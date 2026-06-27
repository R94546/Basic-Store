import 'package:cloud_firestore/cloud_firestore.dart';

/// Savdo yozuvi modeli
class Sale {
  final String? id;
  final int? number;           // Chek raqami (1001, 1002 ...)
  final DateTime createdAt;
  final int totalAmount;       // Jami summa (skidka bilan)
  final int originalAmount;    // Asl summa (skidkasiz)
  final int discountAmount;    // Chegirma summasi
  final List<SaleItem> items;
  final String paymentMethod;  // cash, card, debt, mixed
  final int amountPaid;        // Mijoz to'lagan summa
  final int changeAmount;      // Qaytim
  final Map<String, int> payments; // Aralash to'lov: {cash: 5000, card: 3000}
  final String? customerName;  // Qarzga sotilganda mijoz nomi
  final String? note;          // Chek izohi
  final String? cashierName;

  Sale({
    this.id,
    this.number,
    required this.createdAt,
    required this.totalAmount,
    required this.originalAmount,
    required this.discountAmount,
    required this.items,
    this.paymentMethod = 'cash',
    this.amountPaid = 0,
    this.changeAmount = 0,
    this.payments = const {},
    this.customerName,
    this.note,
    this.cashierName,
  });

  /// To'lov usulining o'qiladigan nomi
  String get paymentLabel {
    switch (paymentMethod) {
      case 'card':
        return 'Karta';
      case 'debt':
        return 'Qarz';
      default:
        return 'Naqd';
    }
  }

  factory Sale.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Sale(
      id: doc.id,
      number: data['number'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      totalAmount: data['totalAmount'] ?? 0,
      originalAmount: data['originalAmount'] ?? 0,
      discountAmount: data['discountAmount'] ?? 0,
      items: (data['items'] as List<dynamic>?)
          ?.map((e) => SaleItem.fromMap(e as Map<String, dynamic>))
          .toList() ?? [],
      paymentMethod: data['paymentMethod'] ?? 'cash',
      amountPaid: data['amountPaid'] ?? 0,
      changeAmount: data['changeAmount'] ?? 0,
      payments: (data['payments'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, (v as num).toInt())) ??
          const {},
      customerName: data['customerName'],
      note: data['note'],
      cashierName: data['cashierName'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      if (number != null) 'number': number,
      'createdAt': FieldValue.serverTimestamp(),
      'totalAmount': totalAmount,
      'originalAmount': originalAmount,
      'discountAmount': discountAmount,
      'items': items.map((e) => e.toMap()).toList(),
      'paymentMethod': paymentMethod,
      'amountPaid': amountPaid,
      'changeAmount': changeAmount,
      if (payments.isNotEmpty) 'payments': payments,
      if (customerName != null) 'customerName': customerName,
      if (note != null) 'note': note,
      'cashierName': cashierName,
    };
  }
}

/// Savdodagi tovar
class SaleItem {
  final String productId;
  final String? variantId;  // Variant doc IDsi (bo'lsa)
  final String productName;
  final int quantity;
  final int unitPrice;      // Birlik narxi (skidka bilan)
  final int originalPrice;  // Asl narx
  final int buyPrice;       // Sotuv paytidagi tan (kelish) narxi — foyda uchun
  final int? discount;      // Chegirma foizi
  final String? size;
  final String? color;

  SaleItem({
    required this.productId,
    this.variantId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.originalPrice,
    this.buyPrice = 0,
    this.discount,
    this.size,
    this.color,
  });

  int get subtotal => unitPrice * quantity;
  int get originalSubtotal => originalPrice * quantity;

  factory SaleItem.fromMap(Map<String, dynamic> map) {
    return SaleItem(
      productId: map['productId'] ?? '',
      variantId: map['variantId'],
      productName: map['productName'] ?? '',
      quantity: map['quantity'] ?? 1,
      unitPrice: map['unitPrice'] ?? 0,
      originalPrice: map['originalPrice'] ?? 0,
      buyPrice: map['buyPrice'] ?? 0,
      discount: map['discount'],
      size: map['size'],
      color: map['color'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      if (variantId != null) 'variantId': variantId,
      'productName': productName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'originalPrice': originalPrice,
      'buyPrice': buyPrice,
      if (discount != null) 'discount': discount,
      if (size != null) 'size': size,
      if (color != null) 'color': color,
    };
  }
}
