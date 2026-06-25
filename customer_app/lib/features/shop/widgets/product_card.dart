import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:customer_app/core/l10n/locale_provider.dart';
import '../models/cart_item.dart';
import '../models/product_model.dart';
import '../providers/cart_provider.dart';
import '../screens/product_detail_screen.dart';

/// Umumiy mahsulot kartasi — rasm, narx, chegirma va burchakda savat ikonkasi.
class ProductCard extends StatelessWidget {
  final Product product;
  const ProductCard({super.key, required this.product});

  bool get _hasDiscount => product.discount != null && product.discount! > 0;
  int get _price => _hasDiscount
      ? (product.price * (100 - product.discount!) / 100).round()
      : product.price;

  void _openDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
    );
  }

  void _quickAdd(BuildContext context, LocaleProvider loc) {
    // Variantli mahsulot — rang/o'lcham tanlash uchun detalga
    if (product.hasVariants) {
      _openDetail(context);
      return;
    }
    if (product.quantity <= 0) {
      _toast(context, loc.t('product.outOfStock'));
      return;
    }
    context.read<CartProvider>().addItem(CartItem(
          productId: product.id ?? product.name,
          name: product.name,
          price: _price,
          imageUrl: product.images.isNotEmpty ? product.images.first : null,
          quantity: 1,
        ));
    _toast(context, loc.t('product.added'));
  }

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.black,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(milliseconds: 1200),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocaleProvider>();
    final outOfStock = product.quantity <= 0;

    return GestureDetector(
      onTap: () => _openDetail(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              color: Colors.grey[100],
              child: Stack(
                children: [
                  Positioned.fill(
                    child: product.images.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: product.images.first,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Icon(Icons.checkroom,
                                size: 32, color: Colors.grey[300]),
                          )
                        : Icon(Icons.checkroom,
                            size: 32, color: Colors.grey[300]),
                  ),
                  if (_hasDiscount)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        color: Colors.red,
                        child: Text('-${product.discount}%',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  if (outOfStock)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        color: Colors.black54,
                        child: Text(loc.t('product.outOfStock'),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 9)),
                      ),
                    ),
                  // Burchakdagi savat ikonkasi
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Material(
                      color: outOfStock ? Colors.grey : Colors.black,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: outOfStock
                            ? null
                            : () => _quickAdd(context, loc),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            product.hasVariants
                                ? Icons.add
                                : Icons.shopping_bag_outlined,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(product.name.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Row(
            children: [
              Text('${_money(_price)} ${loc.t('common.sum')}',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _hasDiscount ? Colors.red : Colors.black)),
              if (_hasDiscount) ...[
                const SizedBox(width: 6),
                Text(_money(product.price),
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                        decoration: TextDecoration.lineThrough)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _money(int v) {
    final s = v.toString();
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(' ');
      b.write(s[i]);
    }
    return b.toString();
  }
}
