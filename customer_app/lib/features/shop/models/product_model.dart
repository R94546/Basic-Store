import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String? id;
  final String name;
  final String category;
  final String size;
  final String? color;
  final int price;
  final int quantity;
  final String barcode;
  final List<String> images;
  final DateTime? createdAt;
  final bool hasVariants;
  final List<String> availableSizes;
  final List<String> availableColors;
  final int? discount;

  Product({
    this.id,
    required this.name,
    required this.category,
    this.size = 'M',
    this.color,
    required this.price,
    required this.quantity,
    required this.barcode,
    this.images = const [],
    this.createdAt,
    this.hasVariants = false,
    this.availableSizes = const [],
    this.availableColors = const [],
    this.discount,
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      size: data['size'] ?? 'M',
      color: data['color'],
      price: data['price'] ?? 0,
      quantity: data['quantity'] ?? 0,
      barcode: data['barcode'] ?? '',
      images: List<String>.from(data['images'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      hasVariants: data['hasVariants'] ?? false,
      availableSizes: List<String>.from(data['availableSizes'] ?? []),
      availableColors: List<String>.from(data['availableColors'] ?? []),
      discount: data['discount'],
    );
  }
}

