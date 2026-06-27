import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/activity_log.dart';
import '../models/order.dart';

/// Provider for managing orders
class OrderProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<CustomerOrder> _orders = [];
  bool _isLoading = false;
  String? _error;

  List<CustomerOrder> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Filtered lists
  List<CustomerOrder> get pendingOrders => 
      _orders.where((o) => o.status == OrderStatus.pending).toList();
  
  List<CustomerOrder> get activeOrders => 
      _orders.where((o) => 
        o.status == OrderStatus.confirmed || 
        o.status == OrderStatus.processing ||
        o.status == OrderStatus.shipped
      ).toList();

  List<CustomerOrder> get completedOrders => 
      _orders.where((o) => 
        o.status == OrderStatus.delivered ||
        o.status == OrderStatus.cancelled
      ).toList();

  /// Load all orders from Firestore
  Future<void> loadOrders() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .get();

      _orders = snapshot.docs.map((doc) => CustomerOrder.fromFirestore(doc)).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update order status
  Future<bool> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': newStatus.name,
        'updatedAt': Timestamp.now(),
      });

      // Update local list
      final index = _orders.indexWhere((o) => o.id == orderId);
      if (index != -1) {
        _orders[index] = _orders[index].copyWith(
          status: newStatus,
          updatedAt: DateTime.now(),
        );
        notifyListeners();
      }

      // Yetkazilganda — online sotuvni `sales`ga yozamiz (analitika, dashboard,
      // sotuvlar tarixi, hisobotlar hammasi shu to'plamdan o'qiydi).
      if (newStatus == OrderStatus.delivered) {
        await _recordSaleFromOrder(orderId);
      }

      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Yetkazilgan buyurtmadan `sales` yozuvini yaratadi (dublikatsiz) va
  /// mahsulot qoldig'ini kamaytiradi. Online savdo shu tariqa barcha
  /// admin hisobotlariga (analitika/dashboard/tarix/otchyot) tushadi.
  Future<void> _recordSaleFromOrder(String orderId) async {
    try {
      final ref = _firestore.collection('orders').doc(orderId);
      final doc = await ref.get();
      final data = doc.data();
      if (data == null) return;
      if (data['saleRecorded'] == true) return; // allaqachon yozilgan

      final order = CustomerOrder.fromFirestore(doc);
      final saleItems = order.items
          .map((it) => {
                'productId': it.productId,
                'productName': it.name,
                'quantity': it.quantity,
                'unitPrice': it.price,
                'originalPrice': it.price,
                if (it.size != null) 'size': it.size,
                if (it.color != null) 'color': it.color,
              })
          .toList();

      await _firestore.collection('sales').add({
        'createdAt': FieldValue.serverTimestamp(),
        'totalAmount': order.total,
        'originalAmount': order.subtotal,
        'discountAmount': 0,
        'items': saleItems,
        'paymentMethod': 'cash',
        'amountPaid': order.total,
        'changeAmount': 0,
        'payments': {'cash': order.total},
        'customerName': order.customerName,
        'cashierName': 'Online',
        'orderId': orderId,
        'source': 'online',
      });

      // Qoldiqni kamaytirish (eng yaxshi imkon — productId bo'yicha)
      for (final it in order.items) {
        if (it.productId.isEmpty) continue;
        try {
          await _firestore
              .collection('products')
              .doc(it.productId)
              .update({'quantity': FieldValue.increment(-it.quantity)});
        } catch (_) {}
      }

      await ref.update({'saleRecorded': true});
      ActivityLog.record(
        action: 'SALE_CONFIRM',
        entity: 'Sale',
        entityId: orderId,
        details: 'Online · ${order.total} so\'m',
      );
    } catch (e) {
      debugPrint('recordSaleFromOrder error: $e');
    }
  }

  /// Listen to orders in real-time
  void listenToOrders() {
    _firestore
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      _orders = snapshot.docs.map((doc) => CustomerOrder.fromFirestore(doc)).toList();
      notifyListeners();
    });
  }

  /// Get today's orders count
  int get todayOrdersCount {
    final today = DateTime.now();
    return _orders.where((o) => 
      o.createdAt.year == today.year &&
      o.createdAt.month == today.month &&
      o.createdAt.day == today.day
    ).length;
  }

  /// Get today's revenue
  int get todayRevenue {
    final today = DateTime.now();
    return _orders
        .where((o) => 
          o.createdAt.year == today.year &&
          o.createdAt.month == today.month &&
          o.createdAt.day == today.day &&
          o.status == OrderStatus.delivered
        )
        .fold(0, (sum, o) => sum + o.total);
  }
}
