import 'package:cloud_firestore/cloud_firestore.dart';

/// Prixod (tovar kelishi) yozuvi
class StockIn {
  final String? id;
  final String productId;
  final String productName;
  final int quantity;       // Nechta keldi
  final int buyPrice;       // Kelish narxi (birlik)
  final String? note;
  final String? supplier;   // Yetkazib beruvchi
  final DateTime createdAt;

  StockIn({
    this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.buyPrice,
    this.note,
    this.supplier,
    required this.createdAt,
  });

  int get total => quantity * buyPrice;

  factory StockIn.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StockIn(
      id: doc.id,
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      quantity: data['quantity'] ?? 0,
      buyPrice: data['buyPrice'] ?? 0,
      note: data['note'],
      supplier: data['supplier'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'buyPrice': buyPrice,
      if (note != null) 'note': note,
      if (supplier != null) 'supplier': supplier,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
