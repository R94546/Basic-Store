import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/stock_in.dart';

/// Prixod (tovar kelishi) provideri.
/// Yangi prixod qo'shilganda tovar soni va kelish narxi yangilanadi.
class StockInProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<StockIn> _items = [];
  bool _isLoading = false;

  List<StockIn> get items => _items;
  bool get isLoading => _isLoading;

  /// Bugungi prixodlar summasi (kelish bo'yicha)
  int get todayTotal {
    final start = DateTime.now();
    final s = DateTime(start.year, start.month, start.day);
    return _items
        .where((e) => e.createdAt.isAfter(s))
        .fold(0, (sum, e) => sum + e.total);
  }

  Future<void> loadStockIns() async {
    _isLoading = true;
    notifyListeners();
    try {
      final snap = await _firestore
          .collection('stock_ins')
          .orderBy('createdAt', descending: true)
          .limit(300)
          .get();
      _items = snap.docs.map((d) => StockIn.fromFirestore(d)).toList();
    } catch (e) {
      debugPrint('Error loading stock-ins: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Prixod qo'shish — tovar soni oshadi, kelish (va ixtiyoriy sotish) narxi
  /// yangilanadi.
  ///
  /// [updateStock] false bo'lsa — faqat tarix yozuvi yoziladi, tovar soniga
  /// tegilmaydi. Bu variantli tovarlar uchun ishlatiladi: ularning soni
  /// `ProductProvider.receiveVariants` orqali allaqachon yangilanadi, shuning
  /// uchun bu yerda qayta qo'shsak — ikki marta hisoblanib ketardi.
  Future<bool> addStockIn(StockIn stockIn,
      {int? sellPrice, bool updateStock = true}) async {
    try {
      final ref = _firestore.collection('stock_ins').doc();
      if (!updateStock) {
        await ref.set(stockIn.toFirestore());
      } else {
        await _firestore.runTransaction((txn) async {
          final productRef =
              _firestore.collection('products').doc(stockIn.productId);
          final snap = await txn.get(productRef);
          if (!snap.exists) {
            throw Exception('Mahsulot topilmadi');
          }
          final currentQty = (snap.data()?['quantity'] ?? 0) as int;
          txn.set(ref, stockIn.toFirestore());
          txn.update(productRef, {
            'quantity': currentQty + stockIn.quantity,
            'buyPrice': stockIn.buyPrice,
            if (sellPrice != null && sellPrice > 0) 'price': sellPrice,
          });
        });
      }

      _items.insert(0, StockIn(
        id: ref.id,
        productId: stockIn.productId,
        productName: stockIn.productName,
        quantity: stockIn.quantity,
        buyPrice: stockIn.buyPrice,
        note: stockIn.note,
        supplier: stockIn.supplier,
        createdAt: DateTime.now(),
      ));
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error adding stock-in: $e');
      return false;
    }
  }
}
