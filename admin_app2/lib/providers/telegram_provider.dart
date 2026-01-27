import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/telegram_bot_service.dart';

/// Telegram Bot sozlamalari va xabarnomalar provider
class TelegramProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  TelegramBotService? _botService;
  bool _isEnabled = false;
  String _botToken = '';
  String _chatId = '';
  bool _orderNotifications = true;
  bool _stockAlerts = true;
  bool _dailyReports = false;

  bool get isEnabled => _isEnabled;
  bool get isConfigured => _botToken.isNotEmpty && _chatId.isNotEmpty;
  bool get orderNotifications => _orderNotifications;
  bool get stockAlerts => _stockAlerts;
  bool get dailyReports => _dailyReports;

  /// Sozlamalarni yuklash
  Future<void> loadSettings() async {
    try {
      final doc = await _firestore.collection('settings').doc('telegram').get();
      
      if (doc.exists) {
        final data = doc.data()!;
        _isEnabled = data['isEnabled'] ?? false;
        _botToken = data['botToken'] ?? '';
        _chatId = data['chatId'] ?? '';
        _orderNotifications = data['orderNotifications'] ?? true;
        _stockAlerts = data['stockAlerts'] ?? true;
        _dailyReports = data['dailyReports'] ?? false;
        
        _initService();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading telegram settings: $e');
    }
  }

  void _initService() {
    if (_botToken.isNotEmpty && _chatId.isNotEmpty) {
      _botService = TelegramBotService(
        botToken: _botToken,
        chatId: _chatId,
      );
    }
  }

  /// Sozlamalarni saqlash
  Future<void> saveSettings({
    required String botToken,
    required String chatId,
    required bool isEnabled,
    bool? orderNotifications,
    bool? stockAlerts,
    bool? dailyReports,
  }) async {
    try {
      _botToken = botToken;
      _chatId = chatId;
      _isEnabled = isEnabled;
      if (orderNotifications != null) _orderNotifications = orderNotifications;
      if (stockAlerts != null) _stockAlerts = stockAlerts;
      if (dailyReports != null) _dailyReports = dailyReports;

      await _firestore.collection('settings').doc('telegram').set({
        'botToken': _botToken,
        'chatId': _chatId,
        'isEnabled': _isEnabled,
        'orderNotifications': _orderNotifications,
        'stockAlerts': _stockAlerts,
        'dailyReports': _dailyReports,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _initService();
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving telegram settings: $e');
      rethrow;
    }
  }

  /// Test xabari yuborish
  Future<bool> sendTestMessage() async {
    if (_botService == null) return false;
    
    return _botService!.sendMessage(
      '✅ <b>Test xabari muvaffaqiyatli!</b>\n\nAdmin panel telegram botga ulandi.',
    );
  }

  /// Buyurtma xabari yuborish
  Future<void> notifyNewOrder({
    required String orderNumber,
    required String customerName,
    required String customerPhone,
    required List<OrderItem> items,
    required int totalPrice,
  }) async {
    if (!_isEnabled || !_orderNotifications || _botService == null) return;

    await _botService!.sendOrderNotification(
      orderNumber: orderNumber,
      customerName: customerName,
      customerPhone: customerPhone,
      items: items,
      totalPrice: totalPrice,
    );
  }

  /// Stock alert yuborish
  Future<void> notifyLowStock({
    required String productName,
    required String size,
    required String color,
    required int remainingQuantity,
  }) async {
    if (!_isEnabled || !_stockAlerts || _botService == null) return;

    await _botService!.sendStockAlert(
      productName: productName,
      size: size,
      color: color,
      remainingQuantity: remainingQuantity,
    );
  }

  /// Kunlik hisobot yuborish
  Future<void> sendDailyReport({
    required int totalOrders,
    required int totalRevenue,
    required int newCustomers,
    required List<String> lowStockProducts,
  }) async {
    if (!_isEnabled || !_dailyReports || _botService == null) return;

    await _botService!.sendDailyReport(
      totalOrders: totalOrders,
      totalRevenue: totalRevenue,
      newCustomers: newCustomers,
      lowStockProducts: lowStockProducts,
    );
  }
}
