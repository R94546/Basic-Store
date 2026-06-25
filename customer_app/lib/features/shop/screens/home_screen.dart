import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:customer_app/core/l10n/locale_provider.dart';
import '../models/product_model.dart';
import '../providers/catalog_provider.dart';
import '../widgets/product_card.dart';
import 'category_products_screen.dart';
import 'product_detail_screen.dart';
import 'profile_screen.dart';

/// Do'kon bosh sahifasi — hero karusel, chegirmalar, kategoriyalar va yangi mahsulotlar.
class HomeScreen extends StatefulWidget {
  final VoidCallback? onProfileTap;
  const HomeScreen({super.key, this.onProfileTap});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _heroController = PageController();
  Timer? _heroTimer;
  int _heroPage = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CatalogProvider>().loadProducts();
    });
    _heroTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_heroController.hasClients) return;
      final count = _heroSlides.length;
      if (count < 2) return;
      final next = (_heroPage + 1) % count;
      _heroController.animateToPage(
        next,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _heroTimer?.cancel();
    _heroController.dispose();
    super.dispose();
  }

  /// Hero slaydlari: chegirmali mahsulotlar; agar 2 tadan kam bo'lsa — yangi
  /// mahsulotlardan (rasmi borlari) to'ldiriladi.
  List<Product> get _heroSlides {
    final catalog = context.read<CatalogProvider>();
    final discounted = catalog.available
        .where((p) => (p.discount ?? 0) > 0 && p.images.isNotEmpty)
        .toList();
    if (discounted.length >= 2) return discounted.take(6).toList();
    final arrivals =
        catalog.newArrivals.where((p) => p.images.isNotEmpty).toList();
    return arrivals.take(6).toList();
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocaleProvider>();
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          color: Colors.black,
          onRefresh: () =>
              context.read<CatalogProvider>().loadProducts(force: true),
          child: Consumer<CatalogProvider>(
            builder: (context, catalog, _) {
              final isInitialLoad =
                  catalog.isLoading && catalog.products.isEmpty;
              return CustomScrollView(
                slivers: [
                  // Header
                  SliverToBoxAdapter(child: _buildHeader()),

                  if (isInitialLoad)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: CircularProgressIndicator(
                            color: Colors.black, strokeWidth: 1),
                      ),
                    )
                  else if (catalog.available.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text(loc.t('common.empty'),
                            style: TextStyle(color: Colors.grey[600])),
                      ),
                    )
                  else ...[
                    // Hero karusel
                    SliverToBoxAdapter(child: _buildHero(loc)),

                    // Kategoriyalar
                    SliverToBoxAdapter(
                      child: _SectionTitle(loc.t('home.categories')),
                    ),
                    SliverToBoxAdapter(child: _buildCategories()),

                    // Chegirmalar
                    ..._buildSaleSliver(catalog, loc),

                    // Yangi mahsulotlar
                    SliverToBoxAdapter(
                      child: _SectionTitle(loc.t('home.newArrivals')),
                    ),
                    _buildGrid(catalog.available),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------------------
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
      child: Row(
        children: [
          Image.asset('assets/images/logo.png', height: 30),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.black),
            onPressed: () {
              if (widget.onProfileTap != null) {
                widget.onProfileTap!();
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Hero karusel
  // ---------------------------------------------------------------------------
  Widget _buildHero(LocaleProvider loc) {
    final slides = _heroSlides;
    if (slides.isEmpty) return const SizedBox.shrink();
    final height = MediaQuery.of(context).size.height * 0.38;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: SizedBox(
          height: height,
          child: Stack(
            children: [
              PageView.builder(
                controller: _heroController,
                itemCount: slides.length,
                onPageChanged: (i) => setState(() => _heroPage = i),
                itemBuilder: (context, i) => _HeroSlide(
                  product: slides[i],
                  loc: loc,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ProductDetailScreen(product: slides[i]),
                    ),
                  ),
                ),
              ),
              // Nuqta indikatorlari
              if (slides.length > 1)
                Positioned(
                  bottom: 14,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(slides.length, (i) {
                      final active = i == _heroPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: active ? 18 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: active ? Colors.white : Colors.white54,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Kategoriyalar
  // ---------------------------------------------------------------------------
  Widget _buildCategories() {
    return SizedBox(
      height: 44,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('categories')
            .orderBy('order')
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return const SizedBox();
          final cats = snap.data!.docs;
          if (cats.isEmpty) return const SizedBox();
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: cats.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final data = cats[i].data() as Map<String, dynamic>;
              final name = data['name'] ?? '';
              return Center(
                child: ActionChip(
                  label: Text(name,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w500)),
                  backgroundColor: Colors.grey[100],
                  shape: const StadiumBorder(),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CategoryProductsScreen(
                          categoryName: name, categoryId: cats[i].id),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Chegirmalar (gorizontal ProductCard ro'yxati)
  // ---------------------------------------------------------------------------
  List<Widget> _buildSaleSliver(CatalogProvider catalog, LocaleProvider loc) {
    final sale =
        catalog.available.where((p) => (p.discount ?? 0) > 0).toList();
    if (sale.isEmpty) return const [];
    return [
      SliverToBoxAdapter(
        child: _SectionTitle(loc.t('home.sale'), accent: true),
      ),
      SliverToBoxAdapter(
        child: SizedBox(
          height: 280,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            itemCount: sale.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, i) => SizedBox(
              width: 150,
              child: ProductCard(product: sale[i]),
            ),
          ),
        ),
      ),
    ];
  }

  // ---------------------------------------------------------------------------
  // Yangi mahsulotlar gridi
  // ---------------------------------------------------------------------------
  Widget _buildGrid(List<Product> products) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.6,
          crossAxisSpacing: 12,
          mainAxisSpacing: 18,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, i) => ProductCard(product: products[i]),
          childCount: products.length,
        ),
      ),
    );
  }
}

// =============================================================================
// Hero slayd
// =============================================================================
class _HeroSlide extends StatelessWidget {
  final Product product;
  final LocaleProvider loc;
  final VoidCallback onTap;

  const _HeroSlide({
    required this.product,
    required this.loc,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final discount = product.discount ?? 0;
    final hasDiscount = discount > 0;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (product.images.isNotEmpty)
            CachedNetworkImage(
              imageUrl: product.images.first,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(color: Colors.grey[200]),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[200],
                child: Icon(Icons.checkroom,
                    size: 48, color: Colors.grey[400]),
              ),
            )
          else
            Container(color: Colors.grey[200]),

          // Qoramtir gradient overlay
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black12,
                  Colors.black87,
                ],
                stops: [0.35, 0.6, 1.0],
              ),
            ),
          ),

          // Matn
          Positioned(
            left: 20,
            right: 20,
            bottom: 34,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasDiscount)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    color: Colors.red,
                    child: Text(
                      '-$discount%  ${loc.t('home.discountUpTo')}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                Text(
                  product.name.toUpperCase(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      loc.t('home.shopNow'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward,
                        color: Colors.white, size: 14),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Bo'lim sarlavhasi
// =============================================================================
class _SectionTitle extends StatelessWidget {
  final String text;
  final bool accent;

  const _SectionTitle(this.text, {this.accent = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Row(
        children: [
          if (accent)
            Container(
              width: 4,
              height: 16,
              margin: const EdgeInsets.only(right: 8),
              color: Colors.red,
            ),
          Text(
            text.toUpperCase(),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
