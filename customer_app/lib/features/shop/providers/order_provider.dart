import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';

/// Customer App uchun buyurtmalar provideri
class OrderProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<CustomerOrder> _orders = [];
  bool _isLoading = false;
  String? _error;

  List<CustomerOrder> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Filterlangan ro'yxatlar
  List<CustomerOrder> get activeOrders => _orders
      .where((o) => 
        o.status != OrderStatus.delivered && 
        o.status != OrderStatus.cancelled)
      .toList();

  List<CustomerOrder> get completedOrders => _orders
      .where((o) => 
        o.status == OrderStatus.delivered || 
        o.status == OrderStatus.cancelled)
      .toList();

  /// Barcha buyurtmalarni yuklash (telefon raqami orqali)
  Future<void> loadOrdersByPhone(String phone) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Telefon raqamini normallashtirish
      final normalizedPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
      
      final snapshot = await _firestore
          .collection('orders')
          .where('customerPhone', isEqualTo: normalizedPhone)
          .orderBy('createdAt', descending: true)
          .get();

      _orders = snapshot.docs
          .map((doc) => CustomerOrder.fromFirestore(doc))
          .toList();
    } catch (e) {
      _error = e.toString();
      debugPrint('OrderProvider error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Barcha buyurtmalarni yuklash (hozircha auth yo'q shuning uchun hammasi)
  Future<void> loadAllOrders() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      _orders = snapshot.docs
          .map((doc) => CustomerOrder.fromFirestore(doc))
          .toList();
    } catch (e) {
      _error = e.toString();
      debugPrint('OrderProvider error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Buyurtmani bekor qilish
  Future<bool> cancelOrder(String orderId) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': OrderStatus.cancelled.name,
        'updatedAt': Timestamp.now(),
      });

      // Lokal ro'yxatni yangilash
      final index = _orders.indexWhere((o) => o.id == orderId);
      if (index != -1) {
        _orders[index] = _orders[index].copyWith(
          status: OrderStatus.cancelled,
          updatedAt: DateTime.now(),
        );
        notifyListeners();
      }

      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Buyurtmalar sonini olish
  int get totalOrdersCount => _orders.length;

  /// Aktiv buyurtmalar sonini olish
  int get activeOrdersCount => activeOrders.length;

  /// Ro'yxatni tozalash
  void clear() {
    _orders = [];
    notifyListeners();
  }
}
