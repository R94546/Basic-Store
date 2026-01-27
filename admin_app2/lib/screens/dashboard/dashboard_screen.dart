import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/product_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final currencyFormat = NumberFormat.currency(locale: 'uz_UZ', symbol: "so'm", decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(),
          
          const SizedBox(height: 24),
          
          // Stats Row
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: "Jami savdo",
                  value: currencyFormat.format(45200000),
                  icon: Icons.attach_money_rounded,
                  iconColor: AppTheme.accentGreen,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StatCard(
                  title: "Buyurtmalar soni",
                  value: "1,245",
                  icon: Icons.shopping_bag_rounded,
                  iconColor: AppTheme.accentOrange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StatCard(
                  title: "O'rtacha chek",
                  value: currencyFormat.format(350000),
                  icon: Icons.receipt_long_rounded,
                  iconColor: Colors.blue,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Products Section
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'So\'nggi mahsulotlar',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go('/warehouse'),
                      child: const Text('Barchasini ko\'rish'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Consumer<ProductProvider>(
                  builder: (context, provider, _) {
                    if (provider.isLoading) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    
                    if (provider.products.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: Text('Mahsulotlar yo\'q'),
                        ),
                      );
                    }
                    
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: provider.products.take(6).map((product) {
                        return SizedBox(
                          width: 180,
                          child: _ProductCard(product: product),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Stock Alert
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.accentRed.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.warning_rounded,
                        color: AppTheme.accentRed,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Stock Alert - Tugayotgan mahsulotlar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _StockAlertItem(name: 'Ko\'ylak (M)', count: 3),
                _StockAlertItem(name: 'Shim qora (L)', count: 2),
                _StockAlertItem(name: 'Bluzka (S)', count: 1),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          // Search
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Qidirish...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white.withOpacity(0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          
          const SizedBox(width: 24),
          
          // Date
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 18),
                const SizedBox(width: 8),
                Text(
                  DateFormat('dd MMMM, yyyy').format(DateTime.now()),
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 24),
          
          // User
          Row(
            children: [
              const Text(
                'Admin',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                radius: 20,
                backgroundColor: AppTheme.accentOrange.withOpacity(0.2),
                child: const Icon(
                  Icons.person,
                  color: AppTheme.accentOrange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final dynamic product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      opacity: 0.15,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(
                Icons.checkroom,
                size: 40,
                color: AppTheme.textSecondary.withOpacity(0.5),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            product.name,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '${product.price} so\'m',
            style: const TextStyle(
              color: AppTheme.accentOrange,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StockAlertItem extends StatelessWidget {
  final String name;
  final int count;

  const _StockAlertItem({
    required this.name,
    required this.count,
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
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.accentRed.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count ta',
              style: const TextStyle(
                color: AppTheme.accentRed,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
