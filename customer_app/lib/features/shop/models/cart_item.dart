/// Represents an item in the shopping cart
class CartItem {
  final String productId;
  final String name;
  final int price;
  final String? imageUrl;
  final String? size;
  final String? color;
  int quantity;

  CartItem({
    required this.productId,
    required this.name,
    required this.price,
    this.imageUrl,
    this.size,
    this.color,
    this.quantity = 1,
  });

  /// Total price for this cart item (price * quantity)
  int get totalPrice => price * quantity;

  /// Create a unique key for cart items with same product but different size/color
  String get cartKey => '$productId-${size ?? 'nosize'}-${color ?? 'nocolor'}';

  /// Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'price': price,
      'imageUrl': imageUrl,
      'size': size,
      'color': color,
      'quantity': quantity,
    };
  }

  /// Create from Map
  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      productId: map['productId'] ?? '',
      name: map['name'] ?? '',
      price: map['price'] ?? 0,
      imageUrl: map['imageUrl'],
      size: map['size'],
      color: map['color'],
      quantity: map['quantity'] ?? 1,
    );
  }

  CartItem copyWith({
    String? productId,
    String? name,
    int? price,
    String? imageUrl,
    String? size,
    String? color,
    int? quantity,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      size: size ?? this.size,
      color: color ?? this.color,
      quantity: quantity ?? this.quantity,
    );
  }
}
