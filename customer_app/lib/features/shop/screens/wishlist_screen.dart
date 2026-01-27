import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/wishlist_provider.dart';
import '../models/product_model.dart';
import 'product_detail_screen.dart';

/// Wishlist (Sevimlilar) ekrani - ZARA uslubi
class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WishlistProvider>().loadWishlist();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'WISHLIST',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Consumer<WishlistProvider>(
            builder: (context, provider, _) {
              if (provider.wishlistProducts.isEmpty) return const SizedBox();
              return TextButton(
                onPressed: () => _showClearConfirmation(context),
                child: const Text(
                  'TOZALASH',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    letterSpacing: 0.5,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<WishlistProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.black, strokeWidth: 1),
            );
          }

          if (provider.wishlistProducts.isEmpty) {
            return _EmptyWishlist();
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.60,
              crossAxisSpacing: 12,
              mainAxisSpacing: 16,
            ),
            itemCount: provider.wishlistProducts.length,
            itemBuilder: (context, index) {
              final product = provider.wishlistProducts[index];
              return _WishlistItem(
                product: product,
                onRemove: () => provider.removeFromWishlist(product.id!),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductDetailScreen(
                        productId: product.id!,
                        product: {
                          'name': product.name,
                          'price': product.price,
                          'images': product.images,
                          'availableSizes': product.availableSizes,
                          'availableColors': product.availableColors,
                        },
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  void _showClearConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Wishlist\'ni tozalash'),
        content: const Text('Barcha sevimli mahsulotlarni o\'chirasizmi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('BEKOR'),
          ),
          TextButton(
            onPressed: () {
              context.read<WishlistProvider>().clearWishlist();
              Navigator.pop(context);
            },
            child: const Text('HA', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

/// Bo'sh wishlist
class _EmptyWishlist extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite_border, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'Sevimlilar ro\'yxati bo\'sh',
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
          const SizedBox(height: 8),
          Text(
            'Mahsulotlarni sevimlilar ro\'yxatiga qo\'shing',
            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

/// Wishlist elementi - ZARA uslubi
class _WishlistItem extends StatelessWidget {
  final Product product;
  final VoidCallback onRemove;
  final VoidCallback onTap;

  const _WishlistItem({
    required this.product,
    required this.onRemove,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasDiscount = product.discount != null && product.discount! > 0;
    final discountedPrice = hasDiscount
        ? (product.price * (100 - product.discount!) / 100).round()
        : product.price;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rasm
          Expanded(
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: product.images.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            product.images.first,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _placeholder(),
                          ),
                        )
                      : _placeholder(),
                ),
                
                // Remove button
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: onRemove,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.close, size: 16, color: Colors.black54),
                    ),
                  ),
                ),
                
                // Chegirma badge
                if (hasDiscount)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      color: Colors.red,
                      child: Text(
                        '-${product.discount}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Nomi
          Text(
            product.name.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.5,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          
          const SizedBox(height: 4),
          
          // Narx
          Row(
            children: [
              if (hasDiscount) ...[
                Text(
                  _formatPrice(product.price),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                _formatPrice(discountedPrice),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: hasDiscount ? Colors.red : Colors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Center(
      child: Icon(Icons.image_outlined, size: 32, color: Colors.grey[300]),
    );
  }

  String _formatPrice(int price) {
    return '${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} so\'m';
  }
}
