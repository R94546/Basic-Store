import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:customer_app/core/l10n/locale_provider.dart';
import 'package:customer_app/core/theme/app_theme.dart';
import '../models/cart_item.dart';
import '../models/product_model.dart';
import '../models/product_variant.dart';
import '../providers/cart_provider.dart';
import '../providers/catalog_provider.dart';
import '../providers/wishlist_provider.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final _pageController = PageController();
  int _imageIndex = 0;

  List<ProductVariant> _variants = [];
  bool _loadingVariants = false;

  String? _selectedSize;
  String? _selectedColor;

  Product get _p => widget.product;
  bool get _hasDiscount => _p.discount != null && _p.discount! > 0;
  int get _basePrice => _hasDiscount
      ? (_p.price * (100 - _p.discount!) / 100).round()
      : _p.price;

  @override
  void initState() {
    super.initState();
    if (_p.hasVariants && _p.id != null) {
      _loadVariants();
    } else {
      // Oddiy mahsulot — availableSizes/Colors dan
      if (_p.availableSizes.isNotEmpty) _selectedSize = null;
    }
  }

  Future<void> _loadVariants() async {
    setState(() => _loadingVariants = true);
    final v = await context.read<CatalogProvider>().fetchVariants(_p.id!);
    if (!mounted) return;
    setState(() {
      _variants = v;
      _loadingVariants = false;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Variantlardan ranglar/o'lchamlar
  List<String> get _sizes {
    if (_variants.isNotEmpty) {
      final s = _variants.map((v) => v.size).toSet().toList();
      s.sort(_sizeCompare);
      return s;
    }
    return _p.availableSizes;
  }

  List<String> get _colors {
    if (_variants.isNotEmpty) {
      return _variants.map((v) => v.color).toSet().toList();
    }
    return _p.availableColors;
  }

  static const _sizeOrder = ['XS', 'S', 'M', 'L', 'XL', 'XXL', '2XL', '3XL', '4XL'];
  int _sizeCompare(String a, String b) {
    int r(String s) {
      final i = _sizeOrder.indexOf(s.toUpperCase());
      return i == -1 ? 99 : i;
    }
    return r(a).compareTo(r(b));
  }

  ProductVariant? get _matchedVariant {
    if (_variants.isEmpty) return null;
    return _variants.where((v) {
      final sizeOk = _selectedSize == null || v.size == _selectedSize;
      final colorOk = _selectedColor == null || v.color == _selectedColor;
      return sizeOk && colorOk;
    }).firstOrNull;
  }

  /// Mavjud o'qlar (size/color) tanlanganmi — to'liq SKU aniqlangani.
  bool get _variantReady =>
      (_sizes.isEmpty || _selectedSize != null) &&
      (_colors.isEmpty || _selectedColor != null);

  int get _stock {
    if (_variants.isEmpty) return _p.quantity;
    // Kerakli o'qlar tanlangan bo'lsa — aynan o'sha variant qoldig'i
    // (bitta o'qli tovarda ham to'g'ri ishlaydi; oversellni oldini oladi).
    if (_variantReady) return _matchedVariant?.quantity ?? 0;
    return _p.quantity;
  }

  int get _finalPrice {
    final mod = _variantReady ? (_matchedVariant?.priceModifier ?? 0) : 0;
    return _basePrice + mod;
  }

  void _addToCart(LocaleProvider loc) {
    // Tanlash talablari
    if (_sizes.isNotEmpty && _selectedSize == null) {
      _toast(loc.t('product.selectSize'));
      return;
    }
    if (_colors.isNotEmpty && _selectedColor == null) {
      _toast(loc.t('product.selectColor'));
      return;
    }
    if (_stock <= 0) {
      _toast(loc.t('product.outOfStock'));
      return;
    }

    final cart = context.read<CartProvider>();
    cart.addItem(CartItem(
      productId: _p.id ?? _p.name,
      name: _p.name,
      price: _finalPrice,
      imageUrl: _p.images.isNotEmpty ? _p.images.first : null,
      size: _selectedSize,
      color: _selectedColor,
      maxStock: _stock,
      quantity: 1,
    ));
    _toast(loc.t('product.added'));
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.black,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(milliseconds: 1300),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocaleProvider>();
    final cart = context.watch<CartProvider>();
    final wishlist = context.watch<WishlistProvider>();
    final inWishlist = wishlist.isInWishlist(_p.id ?? '');
    final inCart =
        cart.isInCart(_p.id ?? '', size: _selectedSize, color: _selectedColor);
    final outOfStock = _stock <= 0;

    return Scaffold(
      backgroundColor: CustomerTheme.background,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Rasm galereyasi
              SliverToBoxAdapter(child: _buildGallery()),
              // Ma'lumot
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 140),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_p.name.toUpperCase(),
                          style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0)),
                      const SizedBox(height: 12),
                      // Narx
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('${_money(_finalPrice)} ${loc.t('common.sum')}',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: _hasDiscount
                                      ? Colors.red
                                      : Colors.black)),
                          if (_hasDiscount) ...[
                            const SizedBox(width: 10),
                            Text('${_money(_p.price)}',
                                style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                    decoration: TextDecoration.lineThrough)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              color: Colors.red,
                              child: Text('-${_p.discount}%',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Ombor holati
                      Text(
                        outOfStock
                            ? loc.t('product.outOfStock')
                            : '${loc.t('product.inStock')}: $_stock',
                        style: TextStyle(
                            fontSize: 12,
                            color: outOfStock ? Colors.red : Colors.green[700],
                            fontWeight: FontWeight.w500),
                      ),

                      if (_loadingVariants) ...[
                        const SizedBox(height: 24),
                        const Center(
                            child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 1, color: Colors.black))),
                      ],

                      // Rang
                      if (_colors.isNotEmpty) ...[
                        const SizedBox(height: 32),
                        _label(loc.t('product.color')),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _colors.map((c) {
                            final sel = c == _selectedColor;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedColor = c),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: sel ? Colors.black : Colors.white,
                                  border: Border.all(
                                      color: sel
                                          ? Colors.black
                                          : Colors.grey[300]!),
                                ),
                                child: Text(c,
                                    style: TextStyle(
                                        color:
                                            sel ? Colors.white : Colors.black,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500)),
                              ),
                            );
                          }).toList(),
                        ),
                      ],

                      // O'lcham
                      if (_sizes.isNotEmpty) ...[
                        const SizedBox(height: 28),
                        _label(loc.t('product.size')),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: _sizes.map((s) {
                            final sel = s == _selectedSize;
                            // shu o'lcham + tanlangan rang uchun stock 0 bo'lsa
                            final disabled = _variants.isNotEmpty &&
                                _selectedColor != null &&
                                !_variants.any((v) =>
                                    v.size == s &&
                                    v.color == _selectedColor &&
                                    v.quantity > 0);
                            return GestureDetector(
                              onTap: disabled
                                  ? null
                                  : () => setState(() => _selectedSize = s),
                              child: Container(
                                width: 52,
                                height: 52,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: sel ? Colors.black : Colors.transparent,
                                  border: Border.all(
                                      color: sel
                                          ? Colors.black
                                          : Colors.grey[300]!),
                                ),
                                child: Text(s,
                                    style: TextStyle(
                                      color: disabled
                                          ? Colors.grey[350]
                                          : sel
                                              ? Colors.white
                                              : Colors.black,
                                      fontWeight: FontWeight.w600,
                                      decoration: disabled
                                          ? TextDecoration.lineThrough
                                          : null,
                                    )),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Yuqori tugmalar
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            right: 8,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _circleBtn(Icons.arrow_back, () => Navigator.pop(context)),
                _circleBtn(
                  inWishlist ? Icons.favorite : Icons.favorite_border,
                  () async {
                    await wishlist.toggleWishlist(_p.id ?? '');
                    if (mounted) {
                      _toast(inWishlist
                          ? loc.t('wishlist.removed')
                          : loc.t('wishlist.added'));
                    }
                  },
                  iconColor: inWishlist ? Colors.red : Colors.black,
                ),
              ],
            ),
          ),

          // Pastki tugma
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
              child: SafeArea(
                top: false,
                child: ElevatedButton(
                  onPressed: outOfStock ? null : () => _addToCart(loc),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: outOfStock ? Colors.grey : Colors.black,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(54),
                  ),
                  child: Text(
                    outOfStock
                        ? loc.t('product.outOfStock')
                        : inCart
                            ? '${loc.t('product.addMore')}  (${cart.getQuantity(_p.id ?? '', size: _selectedSize, color: _selectedColor)})'
                            : loc.t('product.addToCart'),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGallery() {
    final h = MediaQuery.of(context).size.height * 0.62;
    final images = _p.images;
    if (images.isEmpty) {
      return Container(
        height: h,
        color: Colors.grey[100],
        child: Icon(Icons.checkroom, size: 80, color: Colors.grey[300]),
      );
    }
    return SizedBox(
      height: h,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: images.length,
            onPageChanged: (i) => setState(() => _imageIndex = i),
            itemBuilder: (_, i) => CachedNetworkImage(
              imageUrl: images[i],
              fit: BoxFit.cover,
              width: double.infinity,
              errorWidget: (_, __, ___) => Container(
                  color: Colors.grey[100],
                  child: Icon(Icons.checkroom,
                      size: 80, color: Colors.grey[300])),
            ),
          ),
          if (images.length > 1)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  images.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _imageIndex ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == _imageIndex ? Colors.black : Colors.black26,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(text.toUpperCase(),
      style: const TextStyle(
          fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0));

  Widget _circleBtn(IconData icon, VoidCallback onTap,
      {Color iconColor = Colors.black}) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: iconColor, size: 20),
        ),
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
