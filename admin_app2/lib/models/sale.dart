import 'package:cloud_firestore/cloud_firestore.dart';

/// Savdo yozuvi modeli
class Sale {
  final String? id;
  final DateTime createdAt;
  final int totalAmount;       // Jami summa (skidka bilan)
  final int originalAmount;    // Asl summa (skidkasiz)
  final int discountAmount;    // Chegirma summasi
  final List<SaleItem> items;
  final String paymentMethod;  // cash, card, transfer
  final String? cashierName;

  Sale({
    this.id,
    required this.createdAt,
    required this.totalAmount,
    required this.originalAmount,
    required this.discountAmount,
    required this.items,
    this.paymentMethod = 'cash',
    this.cashierName,
  });

  factory Sale.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Sale(
      id: doc.id,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      totalAmount: data['totalAmount'] ?? 0,
      originalAmount: data['originalAmount'] ?? 0,
      discountAmount: data['discountAmount'] ?? 0,
      items: (data['items'] as List<dynamic>?)
          ?.map((e) => SaleItem.fromMap(e as Map<String, dynamic>))
          .toList() ?? [],
      paymentMethod: data['paymentMethod'] ?? 'cash',
      cashierName: data['cashierName'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'createdAt': FieldValue.serverTimestamp(),
      'totalAmount': totalAmount,
      'originalAmount': originalAmount,
      'discountAmount': discountAmount,
      'items': items.map((e) => e.toMap()).toList(),
      'paymentMethod': paymentMethod,
      'cashierName': cashierName,
    };
  }
}

/// Savdodagi tovar
class SaleItem {
  final String productId;
  final String productName;
  final int quantity;
  final int unitPrice;      // Birlik narxi (skidka bilan)
  final int originalPrice;  // Asl narx
  final int? discount;      // Chegirma foizi

  SaleItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.originalPrice,
    this.discount,
  });

  int get subtotal => unitPrice * quantity;
  int get originalSubtotal => originalPrice * quantity;

  factory SaleItem.fromMap(Map<String, dynamic> map) {
    return SaleItem(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      quantity: map['quantity'] ?? 1,
      unitPrice: map['unitPrice'] ?? 0,
      originalPrice: map['originalPrice'] ?? 0,
      discount: map['discount'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'originalPrice': originalPrice,
      if (discount != null) 'discount': discount,
    };
  }
}
