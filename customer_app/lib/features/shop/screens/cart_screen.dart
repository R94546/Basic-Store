import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:customer_app/core/l10n/locale_provider.dart';
import 'package:customer_app/core/theme/app_theme.dart';
import '../providers/cart_provider.dart';
import '../models/cart_item.dart';
import 'checkout_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocaleProvider>();
    return Scaffold(
      backgroundColor: CustomerTheme.background,
      body: SafeArea(
        child: Consumer<CartProvider>(
          builder: (context, cart, child) {
            if (cart.isEmpty) {
              return _buildEmptyCart(context, loc);
            }
            return _buildCartContent(context, cart, loc);
          },
        ),
      ),
    );
  }

  Widget _buildEmptyCart(BuildContext context, LocaleProvider loc) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 24),
          Text(
            loc.t('cart.empty').toUpperCase(),
            style: GoogleFonts.playfairDisplay(
                fontSize: 18, fontWeight: FontWeight.w500, letterSpacing: 2),
          ),
          const SizedBox(height: 32),
          TextButton(
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
            child: Text(
              loc.t('cart.continueShopping'),
              style: const TextStyle(
                color: Colors.black,
                fontSize: 13,
                letterSpacing: 1,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartContent(
      BuildContext context, CartProvider cart, LocaleProvider loc) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                loc.t('cart.title').toUpperCase(),
                style: GoogleFonts.playfairDisplay(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 3),
              ),
              Text(
                '${cart.uniqueItemCount} ${loc.t('cart.items')}',
                style: TextStyle(
                    color: Colors.grey[600], fontSize: 12, letterSpacing: 1),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: cart.items.length,
            separatorBuilder: (_, __) =>
                Divider(color: Colors.grey[200], height: 32),
            itemBuilder: (context, index) =>
                _CartItemCard(item: cart.items[index], loc: loc),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5)),
            ],
          ),
          child: Column(
            children: [
              _row(loc.t('cart.subtotal'),
                  '${_money(cart.subtotal)} ${loc.t('common.sum')}'),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(loc.t('cart.delivery'),
                      style: const TextStyle(fontSize: 12, letterSpacing: 1)),
                  Text(
                    cart.deliveryFee > 0
                        ? '${_money(cart.deliveryFee)} ${loc.t('common.sum')}'
                        : loc.t('cart.free'),
                    style: TextStyle(
                        fontSize: 14,
                        color: cart.deliveryFee == 0 ? Colors.green : null),
                  ),
                ],
              ),
              if (cart.deliveryFee > 0) ...[
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(loc.t('cart.freeOver'),
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey[500])),
                ),
              ],
              const SizedBox(height: 16),
              Divider(color: Colors.grey[300]),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(loc.t('cart.total').toUpperCase(),
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1)),
                  Text('${_money(cart.total)} ${loc.t('common.sum')}',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: const RoundedRectangleBorder(),
                  ),
                  child: Text(loc.t('cart.checkout'),
                      style: const TextStyle(letterSpacing: 1)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _row(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, letterSpacing: 1)),
        Text(value, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}

class _CartItemCard extends StatelessWidget {
  final CartItem item;
  final LocaleProvider loc;

  const _CartItemCard({required this.item, required this.loc});

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            width: 100,
            height: 140,
            child: item.imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: item.imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: Colors.grey[100]),
                    errorWidget: (_, __, ___) => Container(
                        color: Colors.grey[100],
                        child: const Icon(Icons.image, color: Colors.grey)),
                  )
                : Container(
                    color: Colors.grey[100],
                    child: const Icon(Icons.image, color: Colors.grey)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(item.name.toUpperCase(),
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => cart.removeItem(item.cartKey),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              if (item.size != null || item.color != null)
                Text(
                  [
                    if (item.color != null)
                      '${loc.t('product.color')}: ${item.color}',
                    if (item.size != null)
                      '${loc.t('product.size')}: ${item.size}',
                  ].join('  •  '),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              const SizedBox(height: 12),
              Text('${_money(item.price)} ${loc.t('common.sum')}',
                  style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 16),
              Row(
                children: [
                  _QuantityButton(
                      icon: Icons.remove,
                      onPressed: () => cart.decreaseQuantity(item.cartKey)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('${item.quantity}',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500)),
                  ),
                  _QuantityButton(
                      icon: Icons.add,
                      onPressed: () => cart.increaseQuantity(item.cartKey)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _QuantityButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!)),
        child: Icon(icon, size: 16),
      ),
    );
  }
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
