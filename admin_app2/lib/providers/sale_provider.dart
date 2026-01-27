import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/sale.dart';

/// Savdolarni boshqarish provideri
class SaleProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<Sale> _sales = [];
  bool _isLoading = false;
  
  List<Sale> get sales => _sales;
  bool get isLoading => _isLoading;
  
  // Bugungi savdolar
  List<Sale> get todaySales {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    return _sales.where((s) => s.createdAt.isAfter(startOfDay)).toList();
  }
  
  // Bugungi jami savdo
  int get todayTotal => todaySales.fold(0, (sum, s) => sum + s.totalAmount);
  
  // Bugungi savdolar soni
  int get todayCount => todaySales.length;
  
  // O'rtacha chek
  int get averageCheck => todayCount > 0 ? todayTotal ~/ todayCount : 0;
  
  // Jami savdo (barcha vaqt)
  int get allTimeTotal => _sales.fold(0, (sum, s) => sum + s.totalAmount);
  
  // Jami savdolar soni
  int get allTimeCount => _sales.length;
  
  // Jami o'rtacha chek
  int get allTimeAverageCheck => allTimeCount > 0 ? allTimeTotal ~/ allTimeCount : 0;

  /// Savdolarni yuklash
  Future<void> loadSales() async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('sales')
          .orderBy('createdAt', descending: true)
          .limit(500)
          .get();

      _sales = snapshot.docs.map((doc) => Sale.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error loading sales: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Yangi savdo qo'shish
  Future<String?> addSale(Sale sale) async {
    try {
      final docRef = await _firestore.collection('sales').add(sale.toFirestore());
      
      // Mahsulot sonini kamaytirish
      for (final item in sale.items) {
        await _firestore.collection('products').doc(item.productId).update({
          'quantity': FieldValue.increment(-item.quantity),
        });
      }
      
      // Lokal ro'yxatga qo'shish
      _sales.insert(0, Sale(
        id: docRef.id,
        createdAt: DateTime.now(),
        totalAmount: sale.totalAmount,
        originalAmount: sale.originalAmount,
        discountAmount: sale.discountAmount,
        items: sale.items,
        paymentMethod: sale.paymentMethod,
        cashierName: sale.cashierName,
      ));
      
      notifyListeners();
      return docRef.id;
    } catch (e) {
      debugPrint('Error adding sale: $e');
      return null;
    }
  }

  /// Kunlik statistika (oxirgi 7 kun)
  Map<String, int> getWeeklyStats() {
    final now = DateTime.now();
    final stats = <String, int>{};
    
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dayKey = '${day.day}/${day.month}';
      final dayStart = DateTime(day.year, day.month, day.day);
      final dayEnd = dayStart.add(const Duration(days: 1));
      
      final daySales = _sales.where((s) => 
        s.createdAt.isAfter(dayStart) && s.createdAt.isBefore(dayEnd)
      ).toList();
      
      stats[dayKey] = daySales.fold(0, (sum, s) => sum + s.totalAmount);
    }
    
    return stats;
  }

  /// Kategoriya bo'yicha sotilganlar
  Map<String, int> getCategoryStats() {
    final stats = <String, int>{};
    
    for (final sale in _sales) {
      for (final item in sale.items) {
        // Bu yerda kategoriya kerak bo'lsa qo'shimcha logic
        stats[item.productName] = (stats[item.productName] ?? 0) + item.quantity;
      }
    }
    
    return stats;
  }
}
