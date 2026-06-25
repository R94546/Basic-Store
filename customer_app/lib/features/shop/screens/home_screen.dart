import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:customer_app/core/l10n/locale_provider.dart';
import '../models/product_model.dart';
import '../providers/catalog_provider.dart';
import 'category_products_screen.dart';
import 'product_detail_screen.dart';
import 'profile_screen.dart';

/// Do'kon bosh sahifasi — yangi mahsulotlar + kategoriyalar.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CatalogProvider>().loadProducts();
    });
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
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                  child: Row(
                    children: [
                      const Text('BASIC STORE',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 3)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.person_outline,
                            color: Colors.black),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ProfileScreen()),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Kategoriyalar (gorizontal)
              SliverToBoxAdapter(child: _buildCategories(loc)),

              // Yangi mahsulotlar sarlavhasi
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                  child: Text(loc.t('home.newArrivals').toUpperCase(),
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5)),
                ),
              ),

              // Mahsulotlar gridi
              Consumer<CatalogProvider>(
                builder: (context, catalog, _) {
                  if (catalog.isLoading && catalog.products.isEmpty) {
                    return const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                          child: CircularProgressIndicator(
                              color: Colors.black, strokeWidth: 1)),
                    );
                  }
                  final products = catalog.available;
                  if (products.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text(loc.t('common.empty'),
                            style: TextStyle(color: Colors.grey[600])),
                      ),
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.6,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 18,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => _ProductCard(
                          product: products[i],
                          loc: loc,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => ProductDetailScreen(
                                    product: products[i])),
                          ),
                        ),
                        childCount: products.length,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategories(LocaleProvider loc) {
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
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: cats.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final data = cats[i].data() as Map<String, dynamic>;
              final name = data['name'] ?? '';
              return ActionChip(
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
              );
            },
          );
        },
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final LocaleProvider loc;
  final VoidCallback onTap;

  const _ProductCard(
      {required this.product, required this.loc, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasDiscount = product.discount != null && product.discount! > 0;
    final price = hasDiscount
        ? (product.price * (100 - product.discount!) / 100).round()
        : product.price;

    return GestureDetector(
      onTap: onTap,
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
                  if (hasDiscount)
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
              Text('${_money(price)} ${loc.t('common.sum')}',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: hasDiscount ? Colors.red : Colors.black)),
              if (hasDiscount) ...[
                const SizedBox(width: 6),
                Text('${_money(product.price)}',
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
