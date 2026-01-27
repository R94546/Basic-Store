import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/product.dart';
import '../../models/product_variant.dart';
import '../../providers/product_provider.dart';

class WarehouseScreen extends StatefulWidget {
  const WarehouseScreen({super.key});

  @override
  State<WarehouseScreen> createState() => _WarehouseScreenState();
}

class _WarehouseScreenState extends State<WarehouseScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts();
    });
  }

  void _showAddProductDialog() {
    showDialog(
      context: context,
      builder: (context) => const _AddProductWithVariantsDialog(),
    );
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
                const Text(
                  'Sklad',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                // Search
                SizedBox(
                  width: 300,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Mahsulot qidirish...',
                      prefixIcon: const Icon(Icons.search),
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
                ElevatedButton.icon(
                  onPressed: _showAddProductDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Yangi mahsulot'),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Products Grid
          Expanded(
            child: Consumer<ProductProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (provider.products.isEmpty) {
                  return Center(
                    child: GlassCard(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 64,
                            color: AppTheme.textSecondary.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Hali mahsulot yo\'q',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _showAddProductDialog,
                            icon: const Icon(Icons.add),
                            label: const Text('Birinchi mahsulotni qo\'shing'),
                          ),
                        ],
                      ),
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
                  itemCount: provider.products.length + 1,
                  itemBuilder: (context, index) {
                    if (index == provider.products.length) {
                      return _AddProductCard(onTap: _showAddProductDialog);
                    }
                    final product = provider.products[index];
                    return _ProductCard(product: product);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;

  const _ProductCard({required this.product});

  void _showEditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _EditProductDialog(product: product),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.gradientStart,
        title: const Text('O\'chirishni tasdiqlang', style: TextStyle(color: AppTheme.textPrimary)),
        content: Text(
          '"${product.name}" ni o\'chirishni xohlaysizmi?',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Bekor'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<ProductProvider>().deleteProduct(product.id!);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${product.name} o\'chirildi'),
                  backgroundColor: AppTheme.accentRed,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentRed),
            child: const Text('O\'chirish'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image with actions
          Expanded(
            child: Stack(
              children: [
                // Product Image
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
                // Variant badge
                if (product.hasVariants)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.accentOrange,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Variants',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                // Action buttons
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
                      child: const Icon(Icons.more_vert, color: Colors.white, size: 18),
                    ),
                    color: AppTheme.gradientStart,
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showEditDialog(context);
                      } else if (value == 'delete') {
                        _confirmDelete(context);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18, color: AppTheme.accentOrange),
                            SizedBox(width: 8),
                            Text('Tahrirlash', style: TextStyle(color: AppTheme.textPrimary)),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: AppTheme.accentRed),
                            SizedBox(width: 8),
                            Text('O\'chirish', style: TextStyle(color: AppTheme.accentRed)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Name
          Text(
            product.name,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          // Category & Size
          Text(
            product.hasVariants 
                ? '${product.category} • ${product.availableSizes.length} o\'lcham'
                : '${product.category} • ${product.size}',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          // Price & Quantity
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${product.price} so\'m',
                style: const TextStyle(
                  color: AppTheme.accentOrange,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: product.quantity <= 3 
                      ? AppTheme.accentRed.withValues(alpha: 0.2)
                      : AppTheme.accentGreen.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${product.quantity}',
                  style: TextStyle(
                    color: product.quantity <= 3 
                        ? AppTheme.accentRed 
                        : AppTheme.accentGreen,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddProductCard extends StatelessWidget {
  final VoidCallback onTap;

  const _AddProductCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
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
                child: const Icon(
                  Icons.add,
                  color: AppTheme.accentOrange,
                  size: 32,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Qo\'shish',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Variant jadval bilan mahsulot qo'shish dialogi
class _AddProductWithVariantsDialog extends StatefulWidget {
  const _AddProductWithVariantsDialog();

  @override
  State<_AddProductWithVariantsDialog> createState() => _AddProductWithVariantsDialogState();
}

class _AddProductWithVariantsDialogState extends State<_AddProductWithVariantsDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  
  String _selectedCategory = 'Ko\'ylak';
  bool _hasVariants = true;
  bool _isSaving = false;

  // O'lchamlar va ranglar
  final List<String> _allSizes = ['XS', 'S', 'M', 'L', 'XL', 'XXL', '3XL'];
  final List<String> _allColors = ['Qora', 'Oq', 'Qizil', 'Ko\'k', 'Yashil', 'Sariq', 'Pushti', 'Kulrang'];
  
  final Set<String> _selectedSizes = {'S', 'M', 'L'};
  final Set<String> _selectedColors = {'Qora', 'Oq'};
  
  // Variant jadvali: {size_color: quantity}
  final Map<String, int> _variantQuantities = {};
  
  final List<String> categories = [
    'Ko\'ylak', 'Shim', 'Yubka', 'Bluzka', 'Ko\'stum', 'Palto', 'Kurtka', 'Sport', 'Boshqa',
  ];

  @override
  void initState() {
    super.initState();
    _updateVariantTable();
  }

  void _updateVariantTable() {
    // Variantlarni generatsiya qilish
    for (final size in _selectedSizes) {
      for (final color in _selectedColors) {
        final key = '${size}_$color';
        _variantQuantities.putIfAbsent(key, () => 0);
      }
    }
    // Eski variantlarni o'chirish
    _variantQuantities.removeWhere((key, _) {
      final parts = key.split('_');
      return !_selectedSizes.contains(parts[0]) || !_selectedColors.contains(parts[1]);
    });
    setState(() {});
  }

  String _generateBarcode() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(5);
    final randomPart = random.nextInt(9999).toString().padLeft(4, '0');
    return '890$timestamp$randomPart'.substring(0, 13);
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final provider = context.read<ProductProvider>();
      
      if (_hasVariants) {
        // Variantli mahsulot
        final product = Product(
          name: _nameController.text.trim(),
          category: _selectedCategory,
          price: int.parse(_priceController.text),
          quantity: 0, // Variantlardan hisoblanadi
          barcode: _generateBarcode(),
          hasVariants: true,
          availableSizes: _selectedSizes.toList(),
          availableColors: _selectedColors.toList(),
        );

        final productId = await provider.addProduct(product);
        
        if (productId != null) {
          // Variantlarni qo'shish
          final variants = <ProductVariant>[];
          for (final entry in _variantQuantities.entries) {
            final parts = entry.key.split('_');
            final size = parts[0];
            final color = parts[1];
            
            if (entry.value > 0) {
              variants.add(ProductVariant(
                skuId: ProductVariant.generateSku(productId, size, color),
                size: size,
                color: color,
                quantity: entry.value,
                barcode: _generateBarcode(),
              ));
            }
          }
          
          if (variants.isNotEmpty) {
            await provider.addVariants(productId, variants);
          }
        }
      } else {
        // Oddiy mahsulot
        final product = Product(
          name: _nameController.text.trim(),
          category: _selectedCategory,
          size: _selectedSizes.first,
          color: _selectedColors.isNotEmpty ? _selectedColors.first : null,
          price: int.parse(_priceController.text),
          quantity: _variantQuantities.values.fold(0, (a, b) => a + b),
          barcode: _generateBarcode(),
          hasVariants: false,
        );

        await provider.addProduct(product);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mahsulot saqlandi!'),
            backgroundColor: AppTheme.accentGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Xato: $e'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    }

    setState(() => _isSaving = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
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
          width: 700,
          height: 600,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    const Text(
                      'Yangi mahsulot',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    // Variant toggle
                    Row(
                      children: [
                        const Text('Variantlar', style: TextStyle(color: AppTheme.textSecondary)),
                        Switch(
                          value: _hasVariants,
                          onChanged: (v) => setState(() => _hasVariants = v),
                          activeColor: AppTheme.accentOrange,
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Basic Info Row
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Tovar nomi',
                          prefixIcon: Icon(Icons.shopping_bag),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Tovar nomini kiriting';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Kategoriya',
                          prefixIcon: Icon(Icons.category),
                        ),
                        items: categories.map((cat) {
                          return DropdownMenuItem(value: cat, child: Text(cat));
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedCategory = value!);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        decoration: const InputDecoration(
                          labelText: 'Narxi (so\'m)',
                          prefixIcon: Icon(Icons.attach_money),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Narxni kiriting';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                if (_hasVariants) ...[
                  // Size Chips
                  const Text('O\'lchamlar:', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _allSizes.map((size) {
                      final isSelected = _selectedSizes.contains(size);
                      return FilterChip(
                        label: Text(size),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedSizes.add(size);
                            } else {
                              _selectedSizes.remove(size);
                            }
                            _updateVariantTable();
                          });
                        },
                        selectedColor: AppTheme.accentOrange.withValues(alpha: 0.3),
                        checkmarkColor: AppTheme.accentOrange,
                      );
                    }).toList(),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Color Chips
                  const Text('Ranglar:', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _allColors.map((color) {
                      final isSelected = _selectedColors.contains(color);
                      return FilterChip(
                        label: Text(color),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedColors.add(color);
                            } else {
                              _selectedColors.remove(color);
                            }
                            _updateVariantTable();
                          });
                        },
                        selectedColor: AppTheme.accentOrange.withValues(alpha: 0.3),
                        checkmarkColor: AppTheme.accentOrange,
                      );
                    }).toList(),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Variant Table
                  const Text('Variant jadvali:', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SingleChildScrollView(
                        child: _buildVariantTable(),
                      ),
                    ),
                  ),
                ] else ...[
                  // Simple product - just quantity
                  Expanded(
                    child: Center(
                      child: GlassCard(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Oddiy mahsulot (variantsiz)'),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: 200,
                              child: TextFormField(
                                initialValue: '1',
                                decoration: const InputDecoration(
                                  labelText: 'Soni',
                                  prefixIcon: Icon(Icons.numbers),
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  _variantQuantities['simple'] = int.tryParse(value) ?? 0;
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                
                const SizedBox(height: 16),
                
                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveProduct,
                    icon: _isSaving 
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: Text(_isSaving ? 'Saqlanmoqda...' : 'Saqlash'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVariantTable() {
    if (_selectedSizes.isEmpty || _selectedColors.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('O\'lcham va rang tanlang'),
      );
    }

    final sizes = _selectedSizes.toList()..sort();
    final colors = _selectedColors.toList();

    return Table(
      border: TableBorder.all(
        color: AppTheme.glassBorder,
        borderRadius: BorderRadius.circular(8),
      ),
      children: [
        // Header row
        TableRow(
          decoration: BoxDecoration(
            color: AppTheme.accentOrange.withValues(alpha: 0.1),
          ),
          children: [
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('Rang \\ O\'lcham', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            ...sizes.map((size) => Padding(
              padding: const EdgeInsets.all(12),
              child: Text(size, style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            )),
          ],
        ),
        // Data rows
        ...colors.map((color) => TableRow(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(color),
            ),
            ...sizes.map((size) {
              final key = '${size}_$color';
              return Padding(
                padding: const EdgeInsets.all(4),
                child: SizedBox(
                  width: 60,
                  child: TextFormField(
                    initialValue: '${_variantQuantities[key] ?? 0}',
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    ),
                    onChanged: (value) {
                      _variantQuantities[key] = int.tryParse(value) ?? 0;
                    },
                  ),
                ),
              );
            }),
          ],
        )),
      ],
    );
  }
}

/// Mahsulotni tahrirlash dialogi
class _EditProductDialog extends StatefulWidget {
  final Product product;

  const _EditProductDialog({required this.product});

  @override
  State<_EditProductDialog> createState() => _EditProductDialogState();
}

class _EditProductDialogState extends State<_EditProductDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _quantityController;
  late String _selectedCategory;
  bool _isSaving = false;

  final List<String> categories = [
    'Ko\'ylak', 'Shim', 'Yubka', 'Bluzka', 'Ko\'stum', 'Palto', 'Kurtka', 'Sport', 'Boshqa',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _priceController = TextEditingController(text: widget.product.price.toString());
    _quantityController = TextEditingController(text: widget.product.quantity.toString());
    _selectedCategory = widget.product.category;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final updatedProduct = widget.product.copyWith(
        name: _nameController.text.trim(),
        category: _selectedCategory,
        price: int.parse(_priceController.text),
        quantity: int.parse(_quantityController.text),
      );

      await context.read<ProductProvider>().updateProduct(updatedProduct);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${updatedProduct.name} yangilandi!'),
            backgroundColor: AppTheme.accentGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xato: $e'), backgroundColor: AppTheme.accentRed),
        );
      }
    }

    setState(() => _isSaving = false);
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
          width: 400,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.edit, color: AppTheme.accentOrange),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Mahsulotni tahrirlash',
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
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Tovar nomi', prefixIcon: Icon(Icons.shopping_bag)),
                  validator: (v) => v?.isEmpty ?? true ? 'Nom kiriting' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(labelText: 'Kategoriya', prefixIcon: Icon(Icons.category)),
                  items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setState(() => _selectedCategory = v!),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        decoration: const InputDecoration(labelText: 'Narxi', prefixIcon: Icon(Icons.attach_money)),
                        keyboardType: TextInputType.number,
                        validator: (v) => v?.isEmpty ?? true ? 'Narx kiriting' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _quantityController,
                        decoration: const InputDecoration(labelText: 'Soni', prefixIcon: Icon(Icons.numbers)),
                        keyboardType: TextInputType.number,
                        validator: (v) => v?.isEmpty ?? true ? 'Son kiriting' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Bekor'))),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveChanges,
                        child: _isSaving
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Saqlash'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
