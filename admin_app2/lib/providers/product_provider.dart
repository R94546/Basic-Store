import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/product.dart';
import '../models/product_variant.dart';
import '../utils/barcode_util.dart';

/// Bitta SKU'ga ishora (oddiy tovar yoki variant).
typedef SkuRef = ({Product product, ProductVariant? variant});

class ProductProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Product> _products = [];
  bool _isLoading = false;

  // ===== Tez qidiruv uchun xotira indekslari =====
  // hasVariants tovarlar variantlari (har loadProducts'da yangilanadi).
  final Map<String, List<ProductVariant>> _variantsByProduct = {};
  // Shtrix kod -> SKU
  final Map<String, SkuRef> _byBarcode = {};
  // Artikul (qisqa raqam) -> SKU
  final Map<String, SkuRef> _byArticle = {};

  List<Product> get products => _products;
  bool get isLoading => _isLoading;

  /// Tovar variantlarini xotiradan oladi (Firestore'ga murojaatsiz, darhol).
  List<ProductVariant> cachedVariants(String productId) =>
      _variantsByProduct[productId] ?? const [];

  /// Mahsulotlarni yuklash va qidiruv indekslarini qayta qurish.
  Future<void> loadProducts() async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('products')
          .orderBy('createdAt', descending: true)
          .get();

      _products =
          snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();

      await _rebuildIndex();
    } catch (e) {
      debugPrint('Error loading products: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Variant keshi va shtrix/artikul indekslarini qayta quradi.
  Future<void> _rebuildIndex() async {
    _variantsByProduct.clear();
    _byBarcode.clear();
    _byArticle.clear();

    // hasVariants tovarlar variantlarini parallel yuklash.
    final variantProducts =
        _products.where((p) => p.hasVariants && p.id != null).toList();
    final loaded =
        await Future.wait(variantProducts.map((p) => getVariants(p.id!)));
    for (var i = 0; i < variantProducts.length; i++) {
      _variantsByProduct[variantProducts[i].id!] = loaded[i];
    }

    for (final p in _products) {
      if (p.hasVariants) {
        for (final v in (_variantsByProduct[p.id] ?? const <ProductVariant>[])) {
          _registerCode(v.barcode, p, v);
        }
      } else {
        _registerCode(p.barcode, p, null);
      }
    }
  }

  void _registerCode(String barcode, Product p, ProductVariant? v) {
    final code = barcode.trim();
    if (code.isEmpty) return;
    final ref = (product: p, variant: v);
    _byBarcode[code] = ref;
    final art = BarcodeUtil.articleOf(code);
    if (art.isNotEmpty) _byArticle[art] = ref;
  }

  /// SKU hisoblagichidan (`counters/sku`) keyingi unikal raqamni atomik oladi.
  /// Artikullar 1001 dan boshlanadi.
  Future<int> allocateSku() async {
    final ref = _firestore.collection('counters').doc('sku');
    return _firestore.runTransaction<int>((txn) async {
      final snap = await txn.get(ref);
      final current = (snap.data()?['next'] as int?) ?? 1000;
      final next = current + 1;
      txn.set(ref, {'next': next}, SetOptions(merge: true));
      return next;
    });
  }

  /// Hozirgi indeksda mavjud bo'lmagan unikal ichki shtrix yasaydi.
  Future<String> _uniqueInternalBarcode() async {
    for (var i = 0; i < 50; i++) {
      final seq = await allocateSku();
      final code = BarcodeUtil.fromSeq(seq);
      if (!_byBarcode.containsKey(code)) return code;
    }
    return BarcodeUtil.fromSeq(await allocateSku());
  }

  /// Shtrix boshqa SKU'da ishlatilganmi? (berilgan id'lardan tashqari)
  bool barcodeExists(String barcode,
      {String? exceptProductId, String? exceptVariantId}) {
    final ref = _byBarcode[barcode.trim()];
    if (ref == null) return false;
    if (ref.variant != null) return ref.variant!.id != exceptVariantId;
    return ref.product.id != exceptProductId;
  }

  /// Yangi mahsulot qo'shish. Oddiy tovar shtrixi bo'sh bo'lsa — avtomatik
  /// unikal ichki shtrix beriladi.
  Future<String?> addProduct(Product product) async {
    try {
      var p = product;
      if (!p.hasVariants && p.barcode.trim().isEmpty) {
        p = p.copyWith(barcode: await _uniqueInternalBarcode());
      }
      final docRef =
          await _firestore.collection('products').add(p.toFirestore());
      await loadProducts();
      return docRef.id;
    } catch (e) {
      debugPrint('Error adding product: $e');
      rethrow;
    }
  }

  /// Mahsulotga variant qo'shish (shtrix bo'sh bo'lsa avtomatik beriladi).
  Future<void> addVariant(String productId, ProductVariant variant) async {
    try {
      var v = variant;
      if (v.barcode.trim().isEmpty) {
        v = v.copyWith(barcode: await _uniqueInternalBarcode());
      }
      await _firestore
          .collection('products')
          .doc(productId)
          .collection('variants')
          .add(v.toFirestore());

      await _updateTotalQuantity(productId);
    } catch (e) {
      debugPrint('Error adding variant: $e');
      rethrow;
    }
  }

  /// Bir nechta variant qo'shish. Har bir bo'sh shtrixga unikal ichki shtrix
  /// beriladi.
  Future<void> addVariants(
      String productId, List<ProductVariant> variants) async {
    try {
      final variantsRef = _firestore
          .collection('products')
          .doc(productId)
          .collection('variants');

      final batch = _firestore.batch();
      for (final variant in variants) {
        var v = variant;
        if (v.barcode.trim().isEmpty) {
          v = v.copyWith(barcode: await _uniqueInternalBarcode());
        }
        batch.set(variantsRef.doc(), v.toFirestore());
      }

      await batch.commit();
      await _updateTotalQuantity(productId);
    } catch (e) {
      debugPrint('Error adding variants: $e');
      rethrow;
    }
  }

  /// Mahsulotning variantlarini Firestore'dan olish.
  Future<List<ProductVariant>> getVariants(String productId) async {
    try {
      final snapshot = await _firestore
          .collection('products')
          .doc(productId)
          .collection('variants')
          .get();

      return snapshot.docs
          .map((doc) => ProductVariant.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error loading variants: $e');
      return [];
    }
  }

  /// Variantlarga prixod — har bir variant soni oshadi, jami yangilanadi.
  /// [add] — variant id -> qo'shiladigan soni.
  Future<void> receiveVariants(
    String productId,
    Map<String, int> add, {
    int? buyPrice,
    int? sellPrice,
  }) async {
    try {
      final pref = _firestore.collection('products').doc(productId);

      // Tranzaksiyada — har bir variant joriy sonini o'qib, ustiga qo'shamiz.
      // Shu sababli bir vaqtda bo'lgan savdo bilan to'qnashmaydi.
      await _firestore.runTransaction((txn) async {
        final ids = add.keys.where((k) => (add[k] ?? 0) != 0).toList();
        final refs = {
          for (final id in ids) id: pref.collection('variants').doc(id)
        };
        final snaps = <String, DocumentSnapshot>{};
        for (final id in ids) {
          snaps[id] = await txn.get(refs[id]!);
        }
        for (final id in ids) {
          final snap = snaps[id]!;
          if (!snap.exists) continue;
          final cur = (snap.data() as Map<String, dynamic>?)?['quantity'] ?? 0;
          txn.update(refs[id]!, {'quantity': (cur as int) + add[id]!});
        }
        final updates = <String, dynamic>{};
        if (buyPrice != null && buyPrice > 0) updates['buyPrice'] = buyPrice;
        if (sellPrice != null && sellPrice > 0) updates['price'] = sellPrice;
        if (updates.isNotEmpty) txn.update(pref, updates);
      });

      await _updateTotalQuantity(productId);
    } catch (e) {
      debugPrint('Error receiving variants: $e');
      rethrow;
    }
  }

  /// Jami sonni variantlardan hisoblab yangilash.
  Future<void> _updateTotalQuantity(String productId) async {
    final variants = await getVariants(productId);
    final total = variants.fold<int>(0, (sum, v) => sum + v.quantity);

    await _firestore.collection('products').doc(productId).update({
      'quantity': total,
    });

    await loadProducts();
  }

  /// Mahsulotni yangilash.
  Future<void> updateProduct(Product product) async {
    if (product.id == null) return;

    try {
      await _firestore
          .collection('products')
          .doc(product.id)
          .update(product.toFirestore());
      await loadProducts();
    } catch (e) {
      debugPrint('Error updating product: $e');
      rethrow;
    }
  }

  /// Mahsulotni o'chirish (variantlari bilan).
  Future<void> deleteProduct(String id) async {
    try {
      final variantsSnapshot = await _firestore
          .collection('products')
          .doc(id)
          .collection('variants')
          .get();

      final batch = _firestore.batch();
      for (final doc in variantsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      batch.delete(_firestore.collection('products').doc(id));

      await batch.commit();
      await loadProducts();
    } catch (e) {
      debugPrint('Error deleting product: $e');
      rethrow;
    }
  }

  /// Shtrix yoki artikul bo'yicha SKU topish (POS uchun, darhol — xotiradan).
  SkuRef? findByCode(String code) {
    final c = code.trim();
    if (c.isEmpty) return null;
    return _byBarcode[c] ?? _byArticle[c];
  }

  /// Nom + narx + artikul + shtrix + kategoriya bo'yicha qidiruv.
  /// "Fut 200" kabi nom+narx so'rovini qo'llab-quvvatlaydi — har bir so'z
  /// (token) topilishi shart. So'rov bo'sh bo'lsa — barcha tovarlar.
  List<Product> searchProducts(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return _products;
    final tokens = q.split(RegExp(r'\s+'));
    return _products.where((p) {
      final hay = '${p.name} ${p.price} ${p.barcode} '
              '${BarcodeUtil.articleOf(p.barcode)} ${p.category}'
          .toLowerCase();
      return tokens.every((t) => hay.contains(t));
    }).toList();
  }

  /// Eski moslik uchun: faqat oddiy tovarlarni shtrix bo'yicha qaytaradi.
  Product? findByBarcode(String barcode) {
    final ref = _byBarcode[barcode.trim()];
    if (ref != null && ref.variant == null) return ref.product;
    return null;
  }

  /// Variant shtrixi bo'yicha qidirish (xotiradan, darhol).
  ({Product product, ProductVariant variant})? findVariantByBarcode(
      String barcode) {
    final ref = _byBarcode[barcode.trim()];
    if (ref?.variant != null) {
      return (product: ref!.product, variant: ref.variant!);
    }
    return null;
  }

  /// Shtrix allaqachon biror SKU'ga band emasligini bildiradi.
  bool isBarcodeTaken(String code) => _byBarcode.containsKey(code.trim());

  /// Oddiy (variantsiz) tovarga tashqi (ishlab chiqaruvchi) shtrixni biriktiradi.
  Future<void> assignBarcodeToProduct(String productId, String barcode) async {
    await _firestore
        .collection('products')
        .doc(productId)
        .update({'barcode': barcode.trim()});
    await loadProducts();
  }

  /// Variantga tashqi (ishlab chiqaruvchi) shtrixni biriktiradi.
  Future<void> assignBarcodeToVariant(
      String productId, String variantId, String barcode) async {
    await _firestore
        .collection('products')
        .doc(productId)
        .collection('variants')
        .doc(variantId)
        .update({'barcode': barcode.trim()});
    await loadProducts();
  }

  /// Bo'sh yoki takroriy shtrixlarni yangi unikal ichki shtrixlar bilan
  /// to'g'rilaydi. Natija: nechta SKU yangilandi.
  Future<int> normalizeBarcodes() async {
    await loadProducts();
    final seen = <String>{};
    int fixed = 0;

    Future<void> assignVariant(String productId, ProductVariant v) async {
      final code = await _uniqueInternalBarcode();
      await _firestore
          .collection('products')
          .doc(productId)
          .collection('variants')
          .doc(v.id)
          .update({'barcode': code});
      seen.add(code);
      fixed++;
    }

    for (final p in _products) {
      if (p.hasVariants) {
        final variants =
            _variantsByProduct[p.id] ?? await getVariants(p.id!);
        for (final v in variants) {
          final code = v.barcode.trim();
          if (code.isEmpty || seen.contains(code)) {
            await assignVariant(p.id!, v);
          } else {
            seen.add(code);
          }
        }
      } else {
        final code = p.barcode.trim();
        if (code.isEmpty || seen.contains(code)) {
          final fresh = await _uniqueInternalBarcode();
          await _firestore
              .collection('products')
              .doc(p.id)
              .update({'barcode': fresh});
          seen.add(fresh);
          fixed++;
        } else {
          seen.add(code);
        }
      }
    }

    await loadProducts();
    return fixed;
  }

  /// Kategoriya bo'yicha filter.
  List<Product> filterByCategory(String category) {
    if (category.isEmpty || category == 'Barchasi') {
      return _products;
    }
    return _products.where((p) => p.category == category).toList();
  }

  /// Kam qolgan mahsulotlar (Stock Alert).
  List<Product> get lowStockProducts {
    return _products.where((p) => p.quantity <= 3).toList();
  }
}
