import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/product.dart';
import '../../models/sale.dart';
import '../../providers/product_provider.dart';
import '../../providers/sale_provider.dart';

class POSScreen extends StatefulWidget {
  const POSScreen({super.key});

  @override
  State<POSScreen> createState() => _POSScreenState();
}

class _POSScreenState extends State<POSScreen> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final List<CartItem> _cart = [];
  final List<CartItem> _parkedCarts = []; // Hold Cart uchun
  String _barcodeBuffer = '';
  String _selectedCategory = 'Barchasi'; // Tanlangan kategoriya

  // Kategoriyalar ro'yxati
  final List<String> _categories = ['Barchasi', 'Ko\'ylak', 'Shim', 'Yubka', 'Bluzka'];

  // Skidka bilan narx hisoblash
  int _getDiscountedPrice(Product product) {
    if (product.discount != null && product.discount! > 0) {
      return (product.price * (100 - product.discount!) / 100).round();
    }
    return product.price;
  }

  // Jami narx (skidka bilan)
  int get _totalPrice => _cart.fold(0, (sum, item) => sum + (_getDiscountedPrice(item.product) * item.quantity));
  
  // Asl narx (skidkasiz)
  int get _originalPrice => _cart.fold(0, (sum, item) => sum + (item.product.price * item.quantity));
  
  // Chegirma summasi
  int get _discountAmount => _originalPrice - _totalPrice;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts();
    });
  }

  // QR Scanner zaglushka
  void _showQRStub() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassCard(
          blur: 20,
          opacity: 0.9,
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.qr_code_scanner,
                size: 80,
                color: AppTheme.accentOrange.withOpacity(0.5),
              ),
              const SizedBox(height: 24),
              const Text(
                'QR Skaner',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Tez kunda ishga tushadi!\nPrinter ulagandan so\'ng faol bo\'ladi.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Yopish'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // RawKeyboardListener - Skaner uchun
  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final key = event.character;
      if (key != null && key.isNotEmpty) {
        _barcodeBuffer += key;
      }
      
      // Enter bosilganda - barcode tugadi
      if (event.logicalKey == LogicalKeyboardKey.enter && _barcodeBuffer.isNotEmpty) {
        _searchByBarcode(_barcodeBuffer);
        _barcodeBuffer = '';
      }
    }
  }

  void _searchByBarcode(String barcode) {
    final provider = context.read<ProductProvider>();
    final product = provider.findByBarcode(barcode.trim());
    
    if (product != null) {
      _addToCart(product);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mahsulot topilmadi: $barcode'),
          backgroundColor: AppTheme.accentRed,
        ),
      );
    }
  }

  void _addToCart(Product product) {
    final existingIndex = _cart.indexWhere((item) => item.product.id == product.id);
    
    setState(() {
      if (existingIndex >= 0) {
        _cart[existingIndex].quantity++;
      } else {
        _cart.add(CartItem(product: product, quantity: 1));
      }
    });
  }

  void _removeFromCart(int index) {
    setState(() {
      if (_cart[index].quantity > 1) {
        _cart[index].quantity--;
      } else {
        _cart.removeAt(index);
      }
    });
  }

  void _clearCart() {
    setState(() => _cart.clear());
  }

  // Hold Cart - Savatni park qilish
  void _holdCart() {
    if (_cart.isEmpty) return;
    
    setState(() {
      _parkedCarts.addAll(_cart);
      _cart.clear();
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Savat park qilindi'),
        backgroundColor: AppTheme.accentOrange,
      ),
    );
  }

  void _checkout() {
    if (_cart.isEmpty) return;

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassCard(
          blur: 20,
          opacity: 0.9,
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: AppTheme.accentGreen,
                  size: 64,
                ),
                const SizedBox(height: 16),
                const Text(
                  'To\'lovni tasdiqlang',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                // Skidka mavjud bo'lsa ko'rsatish
                if (_discountAmount > 0) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Asl narx:', style: TextStyle(color: AppTheme.textSecondary)),
                      Text(
                        '$_originalPrice so\'m',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Chegirma:', style: TextStyle(color: AppTheme.accentRed)),
                      Text(
                        '-$_discountAmount so\'m',
                        style: const TextStyle(color: AppTheme.accentRed, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  'Jami: $_totalPrice so\'m',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accentOrange,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('Bekor'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          // Savdoni saqlash
                          final sale = Sale(
                            createdAt: DateTime.now(),
                            totalAmount: _totalPrice,
                            originalAmount: _originalPrice,
                            discountAmount: _discountAmount,
                            items: _cart.map((item) => SaleItem(
                              productId: item.product.id ?? '',
                              productName: item.product.name,
                              quantity: item.quantity,
                              unitPrice: _getDiscountedPrice(item.product),
                              originalPrice: item.product.price,
                              discount: item.product.discount,
                            )).toList(),
                            paymentMethod: 'cash',
                          );
                          
                          await context.read<SaleProvider>().addSale(sale);
                          
                          if (mounted) {
                            Navigator.pop(dialogContext);
                            _clearCart();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('To\'lov muvaffaqiyatli saqlandi!'),
                                backgroundColor: AppTheme.accentGreen,
                              ),
                            );
                          }
                        },
                        child: const Text('Tasdiqlash'),
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

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      onKeyEvent: _handleKeyEvent,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            // Left - Products
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  // Header
                  GlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      children: [
                        const Text(
                          'Kassa',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 24),
                        // Search
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            decoration: InputDecoration(
                              hintText: 'Qidirish yoki shtrix kod...',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.qr_code_scanner),
                                onPressed: _showQRStub,
                                tooltip: 'QR Skaner',
                              ),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.3),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onChanged: (value) => setState(() {}),
                            onSubmitted: (value) {
                              if (value.isNotEmpty) {
                                _searchByBarcode(value);
                                _searchController.clear();
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),

                  // Category Tabs
                  GlassCard(
                    padding: const EdgeInsets.all(8),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _categories.map((category) {
                          final isSelected = _selectedCategory == category;
                          return Container(
                            margin: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(category),
                              selected: isSelected,
                              onSelected: (_) {
                                setState(() => _selectedCategory = category);
                              },
                              selectedColor: AppTheme.accentOrange.withOpacity(0.2),
                              checkmarkColor: AppTheme.accentOrange,
                              labelStyle: TextStyle(
                                color: isSelected ? AppTheme.accentOrange : AppTheme.textSecondary,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  
                  // Products Grid
                  Expanded(
                    child: Consumer<ProductProvider>(
                      builder: (context, provider, _) {
                        if (provider.isLoading) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        
                        // Avval kategoriya bo'yicha filter
                        var filteredProducts = _selectedCategory == 'Barchasi'
                            ? provider.products
                            : provider.products.where((p) => 
                                p.category.toLowerCase() == _selectedCategory.toLowerCase()
                              ).toList();
                        
                        // Keyin qidiruv bo'yicha filter
                        final query = _searchController.text.toLowerCase();
                        if (query.isNotEmpty) {
                          filteredProducts = filteredProducts.where((p) =>
                            p.name.toLowerCase().contains(query) ||
                            p.barcode.contains(query)
                          ).toList();
                        }

                        if (filteredProducts.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 64,
                                  color: AppTheme.textSecondary.withOpacity(0.3),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Mahsulot topilmadi',
                                  style: TextStyle(color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          );
                        }

                        return GridView.builder(
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 180,
                            childAspectRatio: 0.85,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = filteredProducts[index];
                            return _POSProductCard(
                              product: product,
                              onTap: () => _addToCart(product),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Right - Cart
            SizedBox(
              width: 350,
              child: GlassCard(
                child: Column(
                  children: [
                    // Cart Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.accentOrange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.shopping_cart,
                            color: AppTheme.accentOrange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Savat (${_cart.length})',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        if (_cart.isNotEmpty)
                          IconButton(
                            onPressed: _holdCart,
                            icon: const Icon(Icons.pause_circle_outline),
                            tooltip: 'Park qilish',
                          ),
                        if (_cart.isNotEmpty)
                          IconButton(
                            onPressed: _clearCart,
                            icon: const Icon(Icons.delete_outline),
                            tooltip: 'Tozalash',
                          ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    
                    // Cart Items
                    Expanded(
                      child: _cart.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.shopping_cart_outlined,
                                    size: 48,
                                    color: AppTheme.textSecondary.withOpacity(0.3),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Savat bo\'sh',
                                    style: TextStyle(color: AppTheme.textSecondary),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _cart.length,
                              itemBuilder: (context, index) {
                                final item = _cart[index];
                                return _CartItemTile(
                                  item: item,
                                  onRemove: () => _removeFromCart(index),
                                  onAdd: () {
                                    setState(() => item.quantity++);
                                  },
                                );
                              },
                            ),
                    ),
                    
                    // Total & Checkout
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'JAMI:',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              Text(
                                '$_totalPrice so\'m',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.accentOrange,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _cart.isEmpty ? null : _checkout,
                              icon: const Icon(Icons.payment),
                              label: const Text('TO\'LASH'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.all(16),
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _POSProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const _POSProductCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(8),
      opacity: 0.2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    Icons.checkroom,
                    size: 36,
                    color: AppTheme.textSecondary.withOpacity(0.4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              product.name,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: AppTheme.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${product.price} so\'m',
              style: const TextStyle(
                color: AppTheme.accentOrange,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  final CartItem item;
  final VoidCallback onRemove;
  final VoidCallback onAdd;

  const _CartItemTile({
    required this.item,
    required this.onRemove,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${item.product.price} so\'m',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Quantity
          Row(
            children: [
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.remove_circle_outline, size: 20),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${item.quantity}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                onPressed: onAdd,
                icon: const Icon(Icons.add_circle, size: 20, color: AppTheme.accentOrange),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});
}
