import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/product_model.dart';
import '../models/product_variant.dart';

/// Katalog provideri — barcha mahsulotlar (home/qidiruv uchun) + variantlar.
class CatalogProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Product> _products = [];
  bool _isLoading = false;
  bool _loaded = false;

  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  bool get loaded => _loaded;

  /// Faqat sotuvga mavjud (soni > 0) mahsulotlar
  List<Product> get available =>
      _products.where((p) => p.quantity > 0).toList();

  /// Yangi mahsulotlar (oxirgi qo'shilgan)
  List<Product> get newArrivals => available.take(10).toList();

  Future<void> loadProducts({bool force = false}) async {
    if (_loaded && !force) return;
    _isLoading = true;
    notifyListeners();
    try {
      final snap = await _firestore
          .collection('products')
          .orderBy('createdAt', descending: true)
          .get();
      _products = snap.docs.map((d) => Product.fromFirestore(d)).toList();
      _loaded = true;
    } catch (e) {
      debugPrint('Catalog load error: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Nom yoki kategoriya bo'yicha qidiruv
  List<Product> search(String query) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return [];
    return _products
        .where((p) =>
            p.name.toLowerCase().contains(q) ||
            p.category.toLowerCase().contains(q) ||
            p.barcode.contains(q))
        .toList();
  }

  /// Mahsulot variantlarini yuklash
  Future<List<ProductVariant>> fetchVariants(String productId) async {
    try {
      final snap = await _firestore
          .collection('products')
          .doc(productId)
          .collection('variants')
          .get();
      return snap.docs.map((d) => ProductVariant.fromFirestore(d)).toList();
    } catch (e) {
      debugPrint('Variants load error: $e');
      return [];
    }
  }
}
