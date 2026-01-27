import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/category.dart';

/// Kategoriyalarni boshqarish provideri
class CategoryProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<ProductCategory> _categories = [];
  bool _isLoading = false;
  
  List<ProductCategory> get categories => _categories;
  bool get isLoading => _isLoading;
  
  // Kategory nomlari ro'yxati (dropdown lar uchun)
  List<String> get categoryNames => _categories.map((c) => c.name).toList();

  /// Kategoriyalarni yuklash
  Future<void> loadCategories() async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('categories')
          .orderBy('order')
          .get();

      _categories = snapshot.docs.map((doc) => ProductCategory.fromFirestore(doc)).toList();
      
      // Agar kategoriyalar bo'sh bo'lsa, default qo'shish
      if (_categories.isEmpty) {
        await _addDefaultCategories();
      }
    } catch (e) {
      debugPrint('Error loading categories: $e');
      // Default kategoriyalar
      _categories = _getDefaultCategories();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Default kategoriyalarni qo'shish
  Future<void> _addDefaultCategories() async {
    final defaults = _getDefaultCategories();
    
    for (final cat in defaults) {
      await _firestore.collection('categories').add(cat.toFirestore());
    }
    
    // Qayta yuklash
    final snapshot = await _firestore
        .collection('categories')
        .orderBy('order')
        .get();
    _categories = snapshot.docs.map((doc) => ProductCategory.fromFirestore(doc)).toList();
  }

  List<ProductCategory> _getDefaultCategories() {
    return [
      ProductCategory(name: "Ko'ylak", icon: '👗', order: 1),
      ProductCategory(name: 'Shim', icon: '👖', order: 2),
      ProductCategory(name: 'Yubka', icon: '🩱', order: 3),
      ProductCategory(name: 'Bluzka', icon: '👚', order: 4),
      ProductCategory(name: "Ko'stum", icon: '🥻', order: 5),
      ProductCategory(name: 'Palto', icon: '🧥', order: 6),
      ProductCategory(name: 'Kurtka', icon: '🧥', order: 7),
      ProductCategory(name: 'Sport', icon: '🏃', order: 8),
      ProductCategory(name: 'Boshqa', icon: '📦', order: 99),
    ];
  }

  /// Yangi kategoriya qo'shish
  Future<String?> addCategory(ProductCategory category) async {
    try {
      final docRef = await _firestore.collection('categories').add(category.toFirestore());
      
      _categories.add(category.copyWith(id: docRef.id));
      _categories.sort((a, b) => a.order.compareTo(b.order));
      notifyListeners();
      
      return docRef.id;
    } catch (e) {
      debugPrint('Error adding category: $e');
      return null;
    }
  }

  /// Kategoriyani yangilash
  Future<bool> updateCategory(String id, ProductCategory category) async {
    try {
      await _firestore.collection('categories').doc(id).update({
        'name': category.name,
        'icon': category.icon,
        'imageUrl': category.imageUrl,
        'order': category.order,
      });
      
      final index = _categories.indexWhere((c) => c.id == id);
      if (index != -1) {
        _categories[index] = category.copyWith(id: id);
        _categories.sort((a, b) => a.order.compareTo(b.order));
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      debugPrint('Error updating category: $e');
      return false;
    }
  }

  /// Kategoriyani o'chirish
  Future<bool> deleteCategory(String id) async {
    try {
      // Avval mahsulotlar borligini tekshirish
      final products = await _firestore
          .collection('products')
          .where('category', isEqualTo: _categories.firstWhere((c) => c.id == id).name)
          .limit(1)
          .get();
      
      if (products.docs.isNotEmpty) {
        return false; // Mahsulotlar bor, o'chirib bo'lmaydi
      }
      
      await _firestore.collection('categories').doc(id).delete();
      
      _categories.removeWhere((c) => c.id == id);
      notifyListeners();
      
      return true;
    } catch (e) {
      debugPrint('Error deleting category: $e');
      return false;
    }
  }

  /// Kategoriya nomini olish
  ProductCategory? findByName(String name) {
    try {
      return _categories.firstWhere((c) => c.name.toLowerCase() == name.toLowerCase());
    } catch (e) {
      return null;
    }
  }
}
