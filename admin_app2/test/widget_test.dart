// Asosiy birlik testlari (Firebase'ga bog'liq emas).
import 'package:flutter_test/flutter_test.dart';
import 'package:admin_app/models/sale.dart';

void main() {
  group('SaleItem hisob-kitoblari', () {
    test('subtotal = unitPrice * quantity', () {
      final item = SaleItem(
        productId: 'p1',
        productName: 'Ko\'ylak',
        quantity: 3,
        unitPrice: 50000,
        originalPrice: 60000,
      );
      expect(item.subtotal, 150000);
      expect(item.originalSubtotal, 180000);
    });
  });

  group('Sale modeli', () {
    test("to'lov usuli yorlig'i to'g'ri", () {
      Sale s(String m) => Sale(
            createdAt: DateTime.now(),
            totalAmount: 0,
            originalAmount: 0,
            discountAmount: 0,
            items: const [],
            paymentMethod: m,
          );
      expect(s('cash').paymentLabel, 'Naqd');
      expect(s('card').paymentLabel, 'Karta');
      expect(s('debt').paymentLabel, 'Qarz');
    });
  });
}
