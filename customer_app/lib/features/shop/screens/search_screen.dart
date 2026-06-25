import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:customer_app/core/l10n/locale_provider.dart';
import 'package:customer_app/core/theme/app_theme.dart';
import '../models/product_model.dart';
import '../providers/catalog_provider.dart';
import 'product_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CatalogProvider>().loadProducts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocaleProvider>();
    final catalog = context.watch<CatalogProvider>();
    final q = _query.trim();
    final results = q.isEmpty ? <Product>[] : catalog.search(q);

    return Scaffold(
      backgroundColor: CustomerTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Search header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: CustomerTheme.divider),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.maybePop(context),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      style: const TextStyle(
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                      textInputAction: TextInputAction.search,
                      onChanged: (v) => setState(() => _query = v),
                      decoration: InputDecoration(
                        hintText: loc.t('search.hint').toUpperCase(),
                        hintStyle: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                          letterSpacing: 1.0,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF5F5F5),
                        prefixIcon: const Icon(Icons.search,
                            color: Colors.grey, size: 20),
                        suffixIcon: _query.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close,
                                    color: Colors.grey, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _query = '');
                                },
                              )
                            : null,
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.zero,
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.zero,
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.zero,
                          borderSide: BorderSide(color: Colors.black, width: 1),
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 0),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Body
            Expanded(
              child: _buildBody(loc, catalog, q, results),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    LocaleProvider loc,
    CatalogProvider catalog,
    String q,
    List<Product> results,
  ) {
    if (catalog.isLoading && catalog.products.isEmpty) {
      return const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 1, color: Colors.black),
        ),
      );
    }

    if (q.isEmpty) {
      return _message(Icons.search, loc.t('search.start'));
    }

    if (results.isEmpty) {
      return _message(Icons.search_off, loc.t('search.noResults'));
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 20,
        childAspectRatio: 0.56,
      ),
      itemCount: results.length,
      itemBuilder: (_, i) => _ProductCard(
        product: results[i],
        loc: loc,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: results[i]),
          ),
        ),
      ),
    );
  }

  Widget _message(IconData icon, String text) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            text.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final LocaleProvider loc;
  final VoidCallback onTap;

  const _ProductCard({
    required this.product,
    required this.loc,
    required this.onTap,
  });

  bool get _hasDiscount => product.discount != null && product.discount! > 0;

  int get _finalPrice => _hasDiscount
      ? (product.price * (100 - product.discount!) / 100).round()
      : product.price;

  @override
  Widget build(BuildContext context) {
    final img = product.images.isNotEmpty ? product.images.first : null;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              color: Colors.grey[100],
              child: img == null
                  ? Icon(Icons.checkroom, size: 48, color: Colors.grey[300])
                  : CachedNetworkImage(
                      imageUrl: img,
                      fit: BoxFit.cover,
                      placeholder: (ctx, url) =>
                          Container(color: Colors.grey[100]),
                      errorWidget: (ctx, url, err) => Icon(Icons.checkroom,
                          size: 48, color: Colors.grey[300]),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            product.name.toUpperCase(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                '${_money(_finalPrice)} ${loc.t('common.sum')}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _hasDiscount ? Colors.red : Colors.black,
                ),
              ),
              if (_hasDiscount) ...[
                const SizedBox(width: 6),
                Text(
                  _money(product.price),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
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
