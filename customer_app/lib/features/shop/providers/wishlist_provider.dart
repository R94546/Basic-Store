import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/product_model.dart';

/// Wishlist (Sevimlilar) Provider
/// Foydalanuvchi sevimli mahsulotlarini boshqarish
class WishlistProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<String> _wishlistIds = [];
  List<Product> _wishlistProducts = [];
  bool _isLoading = false;
  
  List<String> get wishlistIds => _wishlistIds;
  List<Product> get wishlistProducts => _wishlistProducts;
  bool get isLoading => _isLoading;
  int get count => _wishlistIds.length;

  /// Wishlist'ni yuklash (local storage'dan)
  Future<void> loadWishlist() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      _wishlistIds = prefs.getStringList('wishlist') ?? [];
      
      // Mahsulotlarni Firestore'dan yuklash
      if (_wishlistIds.isNotEmpty) {
        await _loadProducts();
      }
    } catch (e) {
      debugPrint('Error loading wishlist: $e');
    }
    
    _isLoading = false;
    notifyListeners();
  }

  /// Wishlist mahsulotlarini Firestore'dan yuklash
  Future<void> _loadProducts() async {
    try {
      _wishlistProducts = [];
      
      for (final id in _wishlistIds) {
        final doc = await _firestore.collection('products').doc(id).get();
        if (doc.exists) {
          _wishlistProducts.add(Product.fromFirestore(doc));
        }
      }
    } catch (e) {
      debugPrint('Error loading wishlist products: $e');
    }
  }

  /// Mahsulotni wishlist'ga qo'shish
  Future<void> addToWishlist(String productId) async {
    if (_wishlistIds.contains(productId)) return;
    
    _wishlistIds.add(productId);
    await _saveToLocal();
    
    // Mahsulotni yuklash
    try {
      final doc = await _firestore.collection('products').doc(productId).get();
      if (doc.exists) {
        _wishlistProducts.add(Product.fromFirestore(doc));
      }
    } catch (e) {
      debugPrint('Error adding to wishlist: $e');
    }
    
    notifyListeners();
  }

  /// Mahsulotni wishlist'dan olib tashlash
  Future<void> removeFromWishlist(String productId) async {
    _wishlistIds.remove(productId);
    _wishlistProducts.removeWhere((p) => p.id == productId);
    
    await _saveToLocal();
    notifyListeners();
  }

  /// Wishlist'da bor/yo'qligini tekshirish
  bool isInWishlist(String productId) {
    return _wishlistIds.contains(productId);
  }

  /// Toggle wishlist
  Future<void> toggleWishlist(String productId) async {
    if (isInWishlist(productId)) {
      await removeFromWishlist(productId);
    } else {
      await addToWishlist(productId);
    }
  }

  /// Local storage'ga saqlash
  Future<void> _saveToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('wishlist', _wishlistIds);
    } catch (e) {
      debugPrint('Error saving wishlist: $e');
    }
  }

  /// Wishlist'ni tozalash
  Future<void> clearWishlist() async {
    _wishlistIds.clear();
    _wishlistProducts.clear();
    await _saveToLocal();
    notifyListeners();
  }
}
