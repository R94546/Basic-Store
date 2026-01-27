import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/product.dart';
import '../models/product_variant.dart';

class ProductProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Product> _products = [];
  bool _isLoading = false;

  List<Product> get products => _products;
  bool get isLoading => _isLoading;

  /// Mahsulotlarni yuklash
  Future<void> loadProducts() async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('products')
          .orderBy('createdAt', descending: true)
          .get();

      _products = snapshot.docs
          .map((doc) => Product.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error loading products: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Yangi mahsulot qo'shish
  Future<String?> addProduct(Product product) async {
    try {
      final docRef = await _firestore.collection('products').add(product.toFirestore());
      await loadProducts();
      return docRef.id;
    } catch (e) {
      debugPrint('Error adding product: $e');
      rethrow;
    }
  }

  /// Mahsulotga variant qo'shish
  Future<void> addVariant(String productId, ProductVariant variant) async {
    try {
      await _firestore
          .collection('products')
          .doc(productId)
          .collection('variants')
          .add(variant.toFirestore());
      
      // Jami sonini yangilash
      await _updateTotalQuantity(productId);
    } catch (e) {
      debugPrint('Error adding variant: $e');
      rethrow;
    }
  }

  /// Bir nechta variant qo'shish
  Future<void> addVariants(String productId, List<ProductVariant> variants) async {
    try {
      final batch = _firestore.batch();
      final variantsRef = _firestore
          .collection('products')
          .doc(productId)
          .collection('variants');

      for (final variant in variants) {
        batch.set(variantsRef.doc(), variant.toFirestore());
      }

      await batch.commit();
      await _updateTotalQuantity(productId);
    } catch (e) {
      debugPrint('Error adding variants: $e');
      rethrow;
    }
  }

  /// Mahsulotning variantlarini olish
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

  /// Jami sonni hisoblash va yangilash
  Future<void> _updateTotalQuantity(String productId) async {
    final variants = await getVariants(productId);
    final total = variants.fold<int>(0, (sum, v) => sum + v.quantity);
    
    await _firestore.collection('products').doc(productId).update({
      'quantity': total,
    });
    
    await loadProducts();
  }

  /// Mahsulotni yangilash
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

  /// Mahsulotni o'chirish
  Future<void> deleteProduct(String id) async {
    try {
      // Avval variantlarni o'chirish
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

  /// Shtrix kod bo'yicha qidirish (POS uchun)
  Product? findByBarcode(String barcode) {
    try {
      return _products.firstWhere((p) => p.barcode == barcode);
    } catch (e) {
      return null;
    }
  }

  /// Variant shtrix kodi bo'yicha qidirish
  Future<({Product product, ProductVariant variant})?> findVariantByBarcode(String barcode) async {
    for (final product in _products) {
      if (product.hasVariants) {
        final variants = await getVariants(product.id!);
        for (final variant in variants) {
          if (variant.barcode == barcode) {
            return (product: product, variant: variant);
          }
        }
      }
    }
    return null;
  }

  /// Kategoriya bo'yicha filter
  List<Product> filterByCategory(String category) {
    if (category.isEmpty || category == 'Barchasi') {
      return _products;
    }
    return _products.where((p) => p.category == category).toList();
  }

  /// Kam qolgan mahsulotlar (Stock Alert)
  List<Product> get lowStockProducts {
    return _products.where((p) => p.quantity <= 3).toList();
  }
}

