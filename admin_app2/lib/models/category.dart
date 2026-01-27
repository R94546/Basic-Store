import 'package:cloud_firestore/cloud_firestore.dart';

/// Kategoriya modeli
class Category {
  final String? id;
  final String name;
  final String? icon;  // Icon nomi yoki emoji
  final String? imageUrl;
  final int productCount;
  final int order;  // Tartib
  final DateTime? createdAt;

  Category({
    this.id,
    required this.name,
    this.icon,
    this.imageUrl,
    this.productCount = 0,
    this.order = 0,
    this.createdAt,
  });

  factory Category.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Category(
      id: doc.id,
      name: data['name'] ?? '',
      icon: data['icon'],
      imageUrl: data['imageUrl'],
      productCount: data['productCount'] ?? 0,
      order: data['order'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      if (icon != null) 'icon': icon,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'productCount': productCount,
      'order': order,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  Category copyWith({
    String? id,
    String? name,
    String? icon,
    String? imageUrl,
    int? productCount,
    int? order,
    DateTime? createdAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      imageUrl: imageUrl ?? this.imageUrl,
      productCount: productCount ?? this.productCount,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
