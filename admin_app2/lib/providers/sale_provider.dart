import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/sale.dart';

/// Ombor yetishmasligi uchun ichki xato
class _StockException implements Exception {
  final String message;
  _StockException(this.message);
}

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

  /// Keyingi chek raqami (1001 dan boshlanadi)
  int get nextSaleNumber {
    final maxNumber = _sales
        .map((s) => s.number ?? 0)
        .fold<int>(1000, (mx, n) => n > mx ? n : mx);
    return maxNumber + 1;
  }

  /// Yangi savdo qo'shish — ombor yetarliligini tranzaksiyada tekshiradi
  /// va atomik tarzda mahsulot sonini kamaytiradi.
  /// Natija: (ok: muvaffaqiyat, error: xato matni, id: hujjat IDsi).
  Future<({bool ok, String? error, String? id})> addSale(Sale sale) async {
    try {
      final saleRef = _firestore.collection('sales').doc();

      await _firestore.runTransaction((txn) async {
        // Kamaytirishlarni jamlaymiz (bir mahsulot/variant bir necha marta
        // bo'lishi mumkin)
        final Map<String, int> productDec = {};
        final Map<String, int> variantDec = {};       // 'productId/variantId'
        final Map<String, String> itemName = {};
        for (final item in sale.items) {
          if (item.productId.isEmpty) continue;
          productDec[item.productId] =
              (productDec[item.productId] ?? 0) + item.quantity;
          itemName[item.productId] = item.productName;
          if (item.variantId != null) {
            final vk = '${item.productId}/${item.variantId}';
            variantDec[vk] = (variantDec[vk] ?? 0) + item.quantity;
          }
        }

        // 1) O'qish + tekshirish — mahsulotlar
        final Map<String, int> productQty = {};
        for (final pid in productDec.keys) {
          final ref = _firestore.collection('products').doc(pid);
          final snap = await txn.get(ref);
          if (!snap.exists) {
            throw _StockException('Mahsulot topilmadi: ${itemName[pid]}');
          }
          final qty = ((snap.data()?['quantity'] ?? 0) as num).toInt();
          if (qty < productDec[pid]!) {
            throw _StockException(
                '"${itemName[pid]}" omborda yetarli emas (qoldi: $qty)');
          }
          productQty[pid] = qty;
        }

        // O'qish + tekshirish — variantlar
        final Map<String, int> variantQty = {};
        for (final vk in variantDec.keys) {
          final parts = vk.split('/');
          final ref = _firestore
              .collection('products')
              .doc(parts[0])
              .collection('variants')
              .doc(parts[1]);
          final snap = await txn.get(ref);
          if (snap.exists) {
            variantQty[vk] = ((snap.data()?['quantity'] ?? 0) as num).toInt();
          }
        }

        // 2) Yozish — sotuv + kamaytirish
        txn.set(saleRef, sale.toFirestore());
        for (final pid in productDec.keys) {
          txn.update(_firestore.collection('products').doc(pid),
              {'quantity': productQty[pid]! - productDec[pid]!});
        }
        for (final vk in variantQty.keys) {
          final parts = vk.split('/');
          final newQty = variantQty[vk]! - variantDec[vk]!;
          txn.update(
              _firestore
                  .collection('products')
                  .doc(parts[0])
                  .collection('variants')
                  .doc(parts[1]),
              {'quantity': newQty < 0 ? 0 : newQty});
        }
      });

      // Lokal ro'yxatga qo'shish
      _sales.insert(0, Sale(
        id: saleRef.id,
        number: sale.number,
        createdAt: DateTime.now(),
        totalAmount: sale.totalAmount,
        originalAmount: sale.originalAmount,
        discountAmount: sale.discountAmount,
        items: sale.items,
        paymentMethod: sale.paymentMethod,
        amountPaid: sale.amountPaid,
        changeAmount: sale.changeAmount,
        payments: sale.payments,
        customerName: sale.customerName,
        note: sale.note,
        cashierName: sale.cashierName,
      ));

      notifyListeners();
      return (ok: true, error: null, id: saleRef.id);
    } on _StockException catch (e) {
      debugPrint('Stock error: ${e.message}');
      return (ok: false, error: e.message, id: null);
    } catch (e) {
      debugPrint('Error adding sale: $e');
      return (ok: false, error: 'Savdoni saqlashda xatolik: $e', id: null);
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
