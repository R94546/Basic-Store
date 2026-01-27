import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String? id;
  final String name;
  final String category;
  final String size;       // Oddiy mahsulot uchun
  final String? color;     // Oddiy mahsulot uchun
  final int price;
  final int quantity;
  final String barcode;
  final List<String> images;
  final DateTime? createdAt;
  final int? discount; // Chegirma foizi (0-100)
  
  // Variant tizimi uchun
  final bool hasVariants;
  final List<String> availableSizes;
  final List<String> availableColors;

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
    this.discount,
    this.hasVariants = false,
    this.availableSizes = const [],
    this.availableColors = const [],
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
      discount: data['discount'],
      hasVariants: data['hasVariants'] ?? false,
      availableSizes: List<String>.from(data['availableSizes'] ?? []),
      availableColors: List<String>.from(data['availableColors'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'category': category,
      'size': size,
      if (color != null) 'color': color,
      'price': price,
      'quantity': quantity,
      'barcode': barcode,
      'images': images,
      'createdAt': FieldValue.serverTimestamp(),
      if (discount != null) 'discount': discount,
      'hasVariants': hasVariants,
      'availableSizes': availableSizes,
      'availableColors': availableColors,
    };
  }

  Product copyWith({
    String? id,
    String? name,
    String? category,
    String? size,
    String? color,
    int? price,
    int? quantity,
    String? barcode,
    List<String>? images,
    int? discount,
    bool? hasVariants,
    List<String>? availableSizes,
    List<String>? availableColors,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      size: size ?? this.size,
      color: color ?? this.color,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      barcode: barcode ?? this.barcode,
      images: images ?? this.images,
      createdAt: createdAt,
      discount: discount ?? this.discount,
      hasVariants: hasVariants ?? this.hasVariants,
      availableSizes: availableSizes ?? this.availableSizes,
      availableColors: availableColors ?? this.availableColors,
    );
  }

  /// Jami variantlar soni (variantlar bo'lsa)
  int get totalVariantQuantity => quantity;
}

