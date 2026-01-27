import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Telegram Bot xabarnoma xizmati
class TelegramBotService {
  final String botToken;
  final String chatId;
  
  static const String _baseUrl = 'https://api.telegram.org/bot';

  TelegramBotService({
    required this.botToken,
    required this.chatId,
  });

  /// Xabar yuborish
  Future<bool> sendMessage(String message) async {
    try {
      final url = Uri.parse('$_baseUrl$botToken/sendMessage');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'chat_id': chatId,
          'text': message,
          'parse_mode': 'HTML',
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('Telegram xabar yuborildi!');
        return true;
      } else {
        debugPrint('Telegram xato: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Telegram xato: $e');
      return false;
    }
  }

  /// Yangi buyurtma xabari
  Future<bool> sendOrderNotification({
    required String orderNumber,
    required String customerName,
    required String customerPhone,
    required List<OrderItem> items,
    required int totalPrice,
  }) async {
    final itemsList = items.map((item) {
      return '  • ${item.productName} x${item.quantity} = ${item.price * item.quantity} so\'m';
    }).join('\n');

    final message = '''
🛒 <b>YANGI BUYURTMA!</b>

📋 Buyurtma: <code>#$orderNumber</code>
👤 Mijoz: $customerName
📞 Telefon: $customerPhone

🛍️ <b>Mahsulotlar:</b>
$itemsList

💰 <b>JAMI: $totalPrice so'm</b>

⏰ Vaqt: ${DateTime.now().toString().substring(0, 19)}
''';

    return sendMessage(message);
  }

  /// Stock Alert xabari
  Future<bool> sendStockAlert({
    required String productName,
    required String size,
    required String color,
    required int remainingQuantity,
  }) async {
    final message = '''
⚠️ <b>STOCK ALERT!</b>

📦 Mahsulot: $productName
📏 O'lcham: $size
🎨 Rang: $color
📉 Qoldi: <b>$remainingQuantity ta</b>

🔔 Iltimos, zaxirani to'ldiring!
''';

    return sendMessage(message);
  }

  /// Kunlik hisobot
  Future<bool> sendDailyReport({
    required int totalOrders,
    required int totalRevenue,
    required int newCustomers,
    required List<String> lowStockProducts,
  }) async {
    final lowStock = lowStockProducts.isEmpty 
        ? '✅ Hamma narsa yetarli'
        : lowStockProducts.map((p) => '  ⚠️ $p').join('\n');

    final message = '''
📊 <b>KUNLIK HISOBOT</b>

📅 Sana: ${DateTime.now().toString().substring(0, 10)}

📈 <b>Statistika:</b>
  🛒 Buyurtmalar: $totalOrders ta
  💰 Daromad: $totalRevenue so'm
  👤 Yangi mijozlar: $newCustomers

📦 <b>Kam qolgan mahsulotlar:</b>
$lowStock

Yaxshi savdo! 🎉
''';

    return sendMessage(message);
  }

  /// To'lov tasdiqlandi xabari
  Future<bool> sendPaymentConfirmation({
    required String orderNumber,
    required int amount,
    required String paymentMethod,
  }) async {
    final message = '''
✅ <b>TO'LOV TASDIQLANDI</b>

📋 Buyurtma: <code>#$orderNumber</code>
💳 Usul: $paymentMethod
💰 Summa: $amount so'm

⏰ Vaqt: ${DateTime.now().toString().substring(0, 19)}
''';

    return sendMessage(message);
  }
}

/// Buyurtma elementi
class OrderItem {
  final String productName;
  final int quantity;
  final int price;

  OrderItem({
    required this.productName,
    required this.quantity,
    required this.price,
  });
}
