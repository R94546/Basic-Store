import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';

/// Provider for managing shopping cart state
class CartProvider extends ChangeNotifier {
  final Map<String, CartItem> _items = {};

  /// Get all cart items as a list
  List<CartItem> get items => _items.values.toList();

  /// Get cart items count (total quantity of all items)
  int get itemCount => _items.values.fold(0, (sum, item) => sum + item.quantity);

  /// Get number of unique products in cart
  int get uniqueItemCount => _items.length;

  /// Check if cart is empty
  bool get isEmpty => _items.isEmpty;

  /// Calculate subtotal (before delivery)
  int get subtotal => _items.values.fold(0, (sum, item) => sum + item.totalPrice);

  /// Delivery fee (can be made dynamic based on address)
  int get deliveryFee => subtotal > 500000 ? 0 : 25000; // Free delivery over 500,000 UZS

  /// Total including delivery
  int get total => subtotal + deliveryFee;

  /// Add item to cart (qoldiqdan oshmaydi)
  void addItem(CartItem item) {
    final key = item.cartKey;
    final max = item.maxStock;
    if (_items.containsKey(key)) {
      final next = _items[key]!.quantity + item.quantity;
      _items[key]!.quantity = next > max ? max : next;
    } else {
      _items[key] = item..quantity = item.quantity > max ? max : item.quantity;
    }
    notifyListeners();
  }

  /// Remove item from cart completely
  void removeItem(String cartKey) {
    _items.remove(cartKey);
    notifyListeners();
  }

  /// Decrease item quantity by 1
  void decreaseQuantity(String cartKey) {
    if (_items.containsKey(cartKey)) {
      if (_items[cartKey]!.quantity > 1) {
        _items[cartKey]!.quantity--;
      } else {
        _items.remove(cartKey);
      }
      notifyListeners();
    }
  }

  /// Increase item quantity by 1 (qoldiqdan oshmaydi)
  void increaseQuantity(String cartKey) {
    final item = _items[cartKey];
    if (item != null && item.quantity < item.maxStock) {
      item.quantity++;
      notifyListeners();
    }
  }

  /// Update item quantity directly (qoldiqdan oshmaydi)
  void updateQuantity(String cartKey, int quantity) {
    final item = _items[cartKey];
    if (item != null) {
      if (quantity <= 0) {
        _items.remove(cartKey);
      } else {
        item.quantity = quantity > item.maxStock ? item.maxStock : quantity;
      }
      notifyListeners();
    }
  }

  /// Check if product is in cart
  bool isInCart(String productId, {String? size, String? color}) {
    final key = '$productId-${size ?? 'nosize'}-${color ?? 'nocolor'}';
    return _items.containsKey(key);
  }

  /// Get quantity of specific item in cart
  int getQuantity(String productId, {String? size, String? color}) {
    final key = '$productId-${size ?? 'nosize'}-${color ?? 'nocolor'}';
    return _items[key]?.quantity ?? 0;
  }

  /// Clear entire cart
  void clear() {
    _items.clear();
    notifyListeners();
  }
}
