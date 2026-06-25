import 'package:cloud_firestore/cloud_firestore.dart';

/// Mahsulot varianti (o'lcham + rang). Admin `products/{id}/variants` da saqlaydi.
class ProductVariant {
  final String? id;
  final String size;
  final String color;
  final int quantity;
  final String barcode;
  final int? priceModifier;

  ProductVariant({
    this.id,
    required this.size,
    required this.color,
    required this.quantity,
    required this.barcode,
    this.priceModifier,
  });

  bool get inStock => quantity > 0;

  factory ProductVariant.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProductVariant(
      id: doc.id,
      size: data['size'] ?? '',
      color: data['color'] ?? '',
      quantity: data['quantity'] ?? 0,
      barcode: data['barcode'] ?? '',
      priceModifier: data['priceModifier'],
    );
  }
}
