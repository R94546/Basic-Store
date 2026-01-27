import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:customer_app/core/theme/app_theme.dart';
import '../providers/cart_provider.dart';
import '../providers/wishlist_provider.dart';
import '../models/cart_item.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  final Map<String, dynamic> product;

  const ProductDetailScreen({
    super.key,
    required this.productId,
    required this.product,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  String? _selectedSize;
  String? _selectedColor;
  
  late List<String> _sizes;
  late List<String> _colors;
  late List<String> _images;

  @override
  void initState() {
    super.initState();
    _sizes = List<String>.from(widget.product['availableSizes'] ?? ['XS', 'S', 'M', 'L', 'XL']);
    _colors = List<String>.from(widget.product['availableColors'] ?? ['Black', 'White']);
    // Mock editorial images if none provided
    _images = List<String>.from(widget.product['images'] ?? []);
    if (_images.isEmpty) {
      _images = [
        'https://images.unsplash.com/photo-1595777457583-95e059d581b8?q=80&w=1383&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1539008835657-9e8e9680c956?q=80&w=1287&auto=format&fit=crop',
      ];
    }
    
    if (_sizes.isNotEmpty) _selectedSize = _sizes.first;
    if (_colors.isNotEmpty) _selectedColor = _colors.first;
  }

  void _addToCart() {
    final cart = context.read<CartProvider>();
    final name = widget.product['name'] ?? 'Product';
    final price = widget.product['price'] ?? 0;
    final imageUrl = _images.isNotEmpty ? _images.first : null;
    
    cart.addItem(CartItem(
      productId: widget.productId,
      name: name,
      price: price,
      imageUrl: imageUrl,
      size: _selectedSize,
      color: _selectedColor,
      quantity: 1,
    ));
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('ADDED TO CART'),
        backgroundColor: Colors.black,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'VIEW CART',
          textColor: Colors.white,
          onPressed: () {
            Navigator.pop(context);
            // Will navigate to cart tab
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = (widget.product['name'] ?? 'LINEN BLEND DRESS').toUpperCase();
    final price = widget.product['price'] ?? 150000;
    final description = widget.product['description'] ?? 'Long dress made of linen blend fabric. V-neckline and thin straps. Side vents at hem. Hidden side zip closure.';
    final cart = context.watch<CartProvider>();
    final wishlist = context.watch<WishlistProvider>();
    final inCart = cart.isInCart(widget.productId, size: _selectedSize, color: _selectedColor);
    final inWishlist = wishlist.isInWishlist(widget.productId);

    return Scaffold(
      backgroundColor: CustomerTheme.background,
      body: Stack(
        children: [
          // Content Scroll
          CustomScrollView(
            slivers: [
              // Image Carousel - Full Height
              SliverAppBar(
                expandedHeight: MediaQuery.of(context).size.height * 0.85,
                pinned: false,
                backgroundColor: Colors.white,
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  // Wishlist button
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
                      ),
                      child: Icon(
                        inWishlist ? Icons.favorite : Icons.favorite_border,
                        color: inWishlist ? Colors.red : Colors.black,
                        size: 20,
                      ),
                    ),
                    onPressed: () async {
                      await wishlist.toggleWishlist(widget.productId);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(inWishlist ? 'WISHLIST\'DAN O\'CHIRILDI' : 'WISHLIST\'GA QO\'SHILDI'),
                            backgroundColor: Colors.black,
                            duration: const Duration(milliseconds: 1200),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: PageView.builder(
                    itemCount: _images.length,
                    itemBuilder: (context, index) {
                      return Image.network(
                        _images[index],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(color: Colors.grey[100]),
                      );
                    },
                  ),
                ),
              ),

              // Product Info
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            '${_formatPrice(price)} UZS',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 32),
                      
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                          height: 1.6,
                        ),
                      ),
                      
                      const SizedBox(height: 48),
                      
                      // Size Selection
                      const Text(
                        'SIZE',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: _sizes.map((size) {
                          final isSelected = size == _selectedSize;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedSize = size),
                            child: Container(
                              width: 50,
                              height: 50,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.black : Colors.transparent,
                                border: Border.all(
                                  color: isSelected ? Colors.black : Colors.grey[300]!,
                                ),
                              ),
                              child: Text(
                                size,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.black,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          // Custom Back Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          
          // Bottom Actions
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: SafeArea(
                child: ElevatedButton(
                  onPressed: _addToCart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: inCart ? Colors.grey[800] : Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(inCart ? 'ADD ANOTHER' : 'ADD TO CART'),
                      if (inCart) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${cart.getQuantity(widget.productId, size: _selectedSize, color: _selectedColor)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]} ',
    );
  }
}

