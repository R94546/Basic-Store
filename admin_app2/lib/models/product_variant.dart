import 'package:cloud_firestore/cloud_firestore.dart';

/// Mahsulot varianti (o'lcham + rang kombinatsiyasi)
class ProductVariant {
  final String? id;
  final String skuId;      // Unique SKU: "prod001_S_red"
  final String size;       // O'lcham: S, M, L, XL
  final String color;      // Rang: Qizil, Ko'k, Oq
  final int quantity;      // Shu variant uchun soni
  final String barcode;    // Shtrix kod
  final int? priceModifier;  // Narxga o'zgartirish (+/-)

  ProductVariant({
    this.id,
    required this.skuId,
    required this.size,
    required this.color,
    required this.quantity,
    required this.barcode,
    this.priceModifier,
  });

  factory ProductVariant.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProductVariant(
      id: doc.id,
      skuId: data['skuId'] ?? '',
      size: data['size'] ?? 'M',
      color: data['color'] ?? '',
      quantity: data['quantity'] ?? 0,
      barcode: data['barcode'] ?? '',
      priceModifier: data['priceModifier'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'skuId': skuId,
      'size': size,
      'color': color,
      'quantity': quantity,
      'barcode': barcode,
      if (priceModifier != null) 'priceModifier': priceModifier,
    };
  }

  ProductVariant copyWith({
    String? id,
    String? skuId,
    String? size,
    String? color,
    int? quantity,
    String? barcode,
    int? priceModifier,
  }) {
    return ProductVariant(
      id: id ?? this.id,
      skuId: skuId ?? this.skuId,
      size: size ?? this.size,
      color: color ?? this.color,
      quantity: quantity ?? this.quantity,
      barcode: barcode ?? this.barcode,
      priceModifier: priceModifier ?? this.priceModifier,
    );
  }

  /// SKU generatsiya qilish
  static String generateSku(String productId, String size, String color) {
    final cleanColor = color.toLowerCase().replaceAll(' ', '_');
    return '${productId}_${size}_$cleanColor';
  }
}
