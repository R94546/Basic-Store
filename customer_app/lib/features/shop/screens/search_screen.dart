import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:customer_app/core/l10n/locale_provider.dart';
import 'package:customer_app/core/theme/app_theme.dart';
import '../models/product_model.dart';
import '../providers/catalog_provider.dart';
import '../widgets/product_card.dart';

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
      itemBuilder: (_, i) => ProductCard(product: results[i]),
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
