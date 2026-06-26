import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/theme/app_theme.dart';
import '../../core/l10n/locale_provider.dart';
import '../../models/product.dart';
import '../../providers/product_provider.dart';
import '../../providers/category_provider.dart';
import '../../widgets/label_print_dialog.dart';
import '../stockin/stockin_screen.dart';
import 'add_product_screen.dart';

class WarehouseScreen extends StatefulWidget {
  const WarehouseScreen({super.key});

  @override
  State<WarehouseScreen> createState() => _WarehouseScreenState();
}

class _WarehouseScreenState extends State<WarehouseScreen> {
  final _searchController = TextEditingController();
  String _search = '';
  String _categoryFilter = 'Barchasi';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts();
      final cat = context.read<CategoryProvider>();
      if (cat.categoryNames.isEmpty) cat.loadCategories();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openForm({Product? product}) {
    showProductFormDialog(context, product: product);
  }

  List<Product> _applyFilters(List<Product> products) {
    Iterable<Product> result = products;
    if (_categoryFilter != 'Barchasi') {
      result = result.where((p) => p.category == _categoryFilter);
    }
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      result = result.where((p) =>
          p.name.toLowerCase().contains(q) ||
          p.barcode.toLowerCase().contains(q) ||
          p.category.toLowerCase().contains(q));
    }
    return result.toList();
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocaleProvider>();
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(loc),
          const SizedBox(height: 16),
          _buildCategoryFilter(loc),
          const SizedBox(height: 16),
          Expanded(
            child: Consumer<ProductProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                final products = _applyFilters(provider.products);

                if (provider.products.isEmpty) {
                  return _buildEmpty(loc, isFiltered: false);
                }
                if (products.isEmpty) {
                  return _buildEmpty(loc, isFiltered: true);
                }

                return GridView.builder(
                  gridDelegate:
                      const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 240,
                    childAspectRatio: 0.62,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: products.length + 1,
                  itemBuilder: (context, index) {
                    if (index == products.length) {
                      return _AddProductCard(onTap: () => _openForm());
                    }
                    return _ProductCard(
                      product: products[index],
                      onEdit: () => _openForm(product: products[index]),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(LocaleProvider loc) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Text(
            loc.t('nav.warehouse'),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(width: 12),
          Consumer<ProductProvider>(
            builder: (_, p, __) => Text(
              '${p.products.length} ${loc.t('product.stock').toLowerCase()}',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: 280,
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _search = v.trim()),
              decoration: InputDecoration(
                hintText: '${loc.t('common.search')}...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _search = '');
                        },
                      ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Prixod (tovar kelishi) — Sklad ichida (aniq ko'rinishi uchun to'ldirilgan)
          ElevatedButton.icon(
            onPressed: () async {
              await showStockInDialog(context);
              if (mounted) context.read<ProductProvider>().loadProducts();
            },
            icon: const Icon(Icons.add_box),
            label: Text(loc.t('nav.stockin')),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentGreen,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () => _openForm(),
            icon: const Icon(Icons.add),
            label: Text(loc.t('product.new')),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter(LocaleProvider loc) {
    return Consumer<CategoryProvider>(
      builder: (context, catProvider, _) {
        final cats = ['Barchasi', ...catProvider.categoryNames];
        return SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: cats.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final cat = cats[i];
              final selected = cat == _categoryFilter;
              return ChoiceChip(
                label: Text(cat == 'Barchasi' ? loc.t('common.all') : cat),
                selected: selected,
                onSelected: (_) => setState(() => _categoryFilter = cat),
                selectedColor: AppTheme.accentOrange.withValues(alpha: 0.3),
                backgroundColor: Colors.white.withValues(alpha: 0.3),
                labelStyle: TextStyle(
                  color:
                      selected ? AppTheme.accentOrange : AppTheme.textSecondary,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
                side: BorderSide(
                  color: selected ? AppTheme.accentOrange : AppTheme.glassBorder,
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmpty(LocaleProvider loc, {required bool isFiltered}) {
    return Center(
      child: GlassCard(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isFiltered ? Icons.search_off : Icons.inventory_2_outlined,
              size: 64,
              color: AppTheme.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              isFiltered
                  ? loc.t('warehouse.nothingFound')
                  : loc.t('warehouse.noProducts'),
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 18),
            ),
            if (!isFiltered) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _openForm(),
                icon: const Icon(Icons.add),
                label: Text(loc.t('warehouse.addFirst')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Stock holatiga qarab rang qaytaradi.
Color _stockColor(int qty) {
  if (qty == 0) return AppTheme.accentRed;
  if (qty <= 3) return AppTheme.accentOrange;
  return AppTheme.accentGreen;
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onEdit;

  const _ProductCard({required this.product, required this.onEdit});

  void _confirmDelete(BuildContext context, LocaleProvider loc) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.gradientStart,
        title: Text(loc.t('warehouse.confirmDelete'),
            style: const TextStyle(color: AppTheme.textPrimary)),
        content: Text(
          '"${product.name}" ${loc.t('warehouse.deleteConfirm')}',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(loc.t('common.cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await context.read<ProductProvider>().deleteProduct(product.id!);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${product.name} ${loc.t('warehouse.deleted')}'),
                    backgroundColor: AppTheme.accentRed,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentRed),
            child: Text(loc.t('common.delete')),
          ),
        ],
      ),
    );
  }

  Future<void> _printLabel(BuildContext context) async {
    await showLabelPrintDialog(context, product);
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocaleProvider>();
    final stockColor = _stockColor(product.quantity);

    return GlassCard(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rasm + badge + menyu
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    color: Colors.white.withValues(alpha: 0.5),
                    child: product.images.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: product.images.first,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            errorWidget: (_, __, ___) => _fallbackIcon(),
                          )
                        : _fallbackIcon(),
                  ),
                ),
                if (product.hasVariants)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: _badge(loc.t('product.variants'),
                        AppTheme.accentOrange),
                  ),
                if ((product.discount ?? 0) > 0)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: _badge('-${product.discount}%', AppTheme.accentRed),
                  ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: PopupMenuButton<String>(
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.more_vert,
                          color: Colors.white, size: 18),
                    ),
                    color: AppTheme.gradientStart,
                    onSelected: (value) {
                      if (value == 'edit') {
                        onEdit();
                      } else if (value == 'delete') {
                        _confirmDelete(context, loc);
                      } else if (value == 'print') {
                        _printLabel(context);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: _menuRow(Icons.edit, loc.t('common.edit'),
                            AppTheme.accentOrange),
                      ),
                      PopupMenuItem(
                        value: 'print',
                        child: _menuRow(Icons.print, loc.t('product.printLabel'),
                            AppTheme.textPrimary),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: _menuRow(Icons.delete, loc.t('common.delete'),
                            AppTheme.accentRed),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            product.name,
            style: const TextStyle(
                fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            product.hasVariants
                ? '${product.category} • ${product.availableSizes.length} ${loc.t('product.size').toLowerCase()}'
                : '${product.category} • ${product.size}',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          // Narxlar
          Row(
            children: [
              Expanded(
                child: _priceLine(loc.t('product.sellPrice'),
                    '${product.price} ${loc.t('common.sum')}', AppTheme.accentOrange),
              ),
            ],
          ),
          if (product.buyPrice > 0)
            _priceLine(loc.t('product.buyPrice'),
                '${product.buyPrice} ${loc.t('common.sum')}', AppTheme.textSecondary),
          const SizedBox(height: 6),
          // Qoldiq + barcode
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: stockColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${loc.t('product.stock')}: ${product.quantity}',
                  style: TextStyle(
                    color: stockColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
              if (product.barcode.isNotEmpty)
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.qr_code_2,
                          size: 14, color: AppTheme.textSecondary),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          product.barcode,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 10,
                            fontFamily: 'monospace',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _fallbackIcon() {
    return Center(
      child: Icon(
        Icons.checkroom,
        size: 48,
        color: AppTheme.textSecondary.withValues(alpha: 0.4),
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
            color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _menuRow(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: color)),
      ],
    );
  }

  Widget _priceLine(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
        Text(
          value,
          style: TextStyle(
              color: valueColor, fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    );
  }
}

class _AddProductCard extends StatelessWidget {
  final VoidCallback onTap;

  const _AddProductCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocaleProvider>();
    return GlassCard(
      opacity: 0.1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.accentOrange.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add,
                    color: AppTheme.accentOrange, size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                loc.t('common.add'),
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
