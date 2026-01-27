import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/product.dart';
import '../../providers/product_provider.dart';

class DiscountScreen extends StatefulWidget {
  const DiscountScreen({super.key});

  @override
  State<DiscountScreen> createState() => _DiscountScreenState();
}

class _DiscountScreenState extends State<DiscountScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.accentRed.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.discount, color: AppTheme.accentRed),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Chegirmalar',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _showAddDiscountDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Chegirma qo\'shish'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Discounted Products
          Expanded(
            child: Consumer<ProductProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final discountedProducts = provider.products
                    .where((p) => p.discount != null && p.discount! > 0)
                    .toList();

                if (discountedProducts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.discount_outlined,
                          size: 80,
                          color: AppTheme.textSecondary.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Chegirmali mahsulotlar yo\'q',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Tovarlarni tahrirlash orqali chegirma qo\'shing',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 220,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: discountedProducts.length,
                  itemBuilder: (context, index) {
                    return _DiscountProductCard(product: discountedProducts[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddDiscountDialog() {
    showDialog(
      context: context,
      builder: (context) => _SelectProductForDiscountDialog(),
    );
  }
}

class _DiscountProductCard extends StatelessWidget {
  final Product product;

  const _DiscountProductCard({required this.product});

  int get discountedPrice {
    if (product.discount == null || product.discount == 0) return product.price;
    return (product.price * (100 - product.discount!) / 100).round();
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image with discount badge
          Expanded(
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    image: product.images.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(product.images.first),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: product.images.isEmpty
                      ? Center(
                          child: Icon(
                            Icons.checkroom,
                            size: 48,
                            color: AppTheme.textSecondary.withValues(alpha: 0.4),
                          ),
                        )
                      : null,
                ),
                // Discount badge
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.accentRed,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '-${product.discount}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                // Remove discount
                Positioned(
                  top: 4,
                  right: 4,
                  child: IconButton(
                    onPressed: () => _removeDiscount(context),
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            product.name,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                '$discountedPrice so\'m',
                style: const TextStyle(
                  color: AppTheme.accentRed,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${product.price}',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  decoration: TextDecoration.lineThrough,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _removeDiscount(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.gradientStart,
        title: const Text('Chegirmani olib tashlash', style: TextStyle(color: AppTheme.textPrimary)),
        content: Text(
          '"${product.name}" dan chegirmani olib tashlamoqchimisiz?',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Bekor'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<ProductProvider>().updateProduct(
                product.copyWith(discount: 0),
              );
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentRed),
            child: const Text('Olib tashlash'),
          ),
        ],
      ),
    );
  }
}

class _SelectProductForDiscountDialog extends StatefulWidget {
  @override
  State<_SelectProductForDiscountDialog> createState() => _SelectProductForDiscountDialogState();
}

class _SelectProductForDiscountDialogState extends State<_SelectProductForDiscountDialog> {
  Product? _selectedProduct;
  final _discountController = TextEditingController(text: '10');

  @override
  void dispose() {
    _discountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassCard(
        blur: 20,
        opacity: 0.95,
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.discount, color: AppTheme.accentRed),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Chegirma qo\'shish',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Product selection
              const Text('Mahsulotni tanlang:', style: TextStyle(color: AppTheme.textSecondary)),
              const SizedBox(height: 8),
              Consumer<ProductProvider>(
                builder: (context, provider, _) {
                  final products = provider.products.where((p) => p.discount == null || p.discount == 0).toList();
                  return DropdownButtonFormField<Product>(
                    value: _selectedProduct,
                    decoration: const InputDecoration(
                      hintText: 'Mahsulot tanlang',
                      prefixIcon: Icon(Icons.shopping_bag),
                    ),
                    items: products.map((p) => DropdownMenuItem(
                      value: p,
                      child: Text('${p.name} - ${p.price} so\'m'),
                    )).toList(),
                    onChanged: (v) => setState(() => _selectedProduct = v),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Discount percentage
              TextField(
                controller: _discountController,
                decoration: const InputDecoration(
                  labelText: 'Chegirma foizi (%)',
                  prefixIcon: Icon(Icons.percent),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),

              // Preview
              if (_selectedProduct != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppTheme.textSecondary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_selectedProduct!.name, style: const TextStyle(color: AppTheme.textPrimary)),
                            Text(
                              'Joriy: ${_selectedProduct!.price} so\'m → '
                              'Chegirma: ${(_selectedProduct!.price * (100 - (int.tryParse(_discountController.text) ?? 0)) / 100).round()} so\'m',
                              style: const TextStyle(color: AppTheme.accentRed, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Bekor'))),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _selectedProduct != null ? _applyDiscount : null,
                      child: const Text('Qo\'llash'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _applyDiscount() {
    if (_selectedProduct == null) return;
    final discount = int.tryParse(_discountController.text) ?? 0;
    if (discount <= 0 || discount > 100) return;

    context.read<ProductProvider>().updateProduct(
      _selectedProduct!.copyWith(discount: discount),
    );
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_selectedProduct!.name} ga $discount% chegirma qo\'shildi'),
        backgroundColor: AppTheme.accentGreen,
      ),
    );
  }
}
