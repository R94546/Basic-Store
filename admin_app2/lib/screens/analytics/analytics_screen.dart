import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/sale_provider.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final _currencyFormat = NumberFormat.currency(locale: 'uz_UZ', symbol: "so'm", decimalDigits: 0);
  
  // Foydalanuvchilar statistikasi
  int _totalUsers = 0;
  int _newUsersThisWeek = 0;
  bool _loadingUsers = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SaleProvider>().loadSales();
      _loadUserStats();
    });
  }

  Future<void> _loadUserStats() async {
    try {
      final firestore = FirebaseFirestore.instance;
      
      // Jami foydalanuvchilar
      final usersSnapshot = await firestore.collection('users').get();
      _totalUsers = usersSnapshot.docs.length;
      
      // Bu haftada ro'yxatdan o'tganlar
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      final newUsersSnapshot = await firestore
          .collection('users')
          .where('createdAt', isGreaterThan: Timestamp.fromDate(weekAgo))
          .get();
      _newUsersThisWeek = newUsersSnapshot.docs.length;
    } catch (e) {
      debugPrint('Error loading user stats: $e');
    }
    
    if (mounted) {
      setState(() => _loadingUsers = false);
    }
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
                  'Hisobotlar',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                // Date Range
                GlassCard(
                  opacity: 0.3,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: const [
                      Icon(Icons.calendar_today, size: 18),
                      SizedBox(width: 8),
                      Text('Oxirgi 30 kun'),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Main content
          Expanded(
            child: Consumer<SaleProvider>(
              builder: (context, saleProvider, _) {
                final weeklyStats = saleProvider.getWeeklyStats();
                
                return Row(
                  children: [
                    // Left - Charts and graphs
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          // Savdo grafigi
                          Expanded(
                            flex: 2,
                            child: GlassCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Savdo grafigi (Oxirgi 7 kun)',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Expanded(
                                    child: weeklyStats.isEmpty || weeklyStats.values.every((v) => v == 0)
                                        ? Center(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.show_chart, size: 64, color: AppTheme.textSecondary.withOpacity(0.3)),
                                                const SizedBox(height: 16),
                                                const Text('Savdolar yo\'q', style: TextStyle(color: AppTheme.textSecondary)),
                                              ],
                                            ),
                                          )
                                        : _WeeklyChart(data: weeklyStats, currencyFormat: _currencyFormat),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Foydalanuvchilar statistikasi
                          Expanded(
                            child: GlassCard(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _UserStatItem(
                                      title: 'Jami foydalanuvchilar',
                                      value: _loadingUsers ? '...' : _totalUsers.toString(),
                                      icon: Icons.people_rounded,
                                      iconColor: Colors.purple,
                                    ),
                                  ),
                                  const VerticalDivider(),
                                  Expanded(
                                    child: _UserStatItem(
                                      title: 'Bu haftada yangi',
                                      value: _loadingUsers ? '...' : '+$_newUsersThisWeek',
                                      icon: Icons.person_add_rounded,
                                      iconColor: AppTheme.accentGreen,
                                    ),
                                  ),
                                  const VerticalDivider(),
                                  Expanded(
                                    child: _UserStatItem(
                                      title: 'Jami mahsulotlar',
                                      value: '...',
                                      icon: Icons.inventory_2_rounded,
                                      iconColor: AppTheme.accentOrange,
                                      futureLoader: _loadProductCount,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Right - Stats cards
                    SizedBox(
                      width: 280,
                      child: Column(
                        children: [
                          Expanded(
                            child: StatCard(
                              title: 'Jami savdo',
                              value: _currencyFormat.format(saleProvider.allTimeTotal),
                              icon: Icons.attach_money,
                              iconColor: AppTheme.accentGreen,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: StatCard(
                              title: 'Savdolar soni',
                              value: NumberFormat.decimalPattern().format(saleProvider.allTimeCount),
                              icon: Icons.shopping_bag,
                              iconColor: AppTheme.accentOrange,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: StatCard(
                              title: 'O\'rtacha chek',
                              value: _currencyFormat.format(saleProvider.allTimeAverageCheck),
                              icon: Icons.receipt,
                              iconColor: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: StatCard(
                              title: 'Bugungi savdo',
                              value: _currencyFormat.format(saleProvider.todayTotal),
                              icon: Icons.today,
                              iconColor: Colors.teal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<String> _loadProductCount() async {
    final snapshot = await FirebaseFirestore.instance.collection('products').get();
    return snapshot.docs.length.toString();
  }
}

/// Foydalanuvchi statistika elementi
class _UserStatItem extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Future<String> Function()? futureLoader;

  const _UserStatItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    this.futureLoader,
  });

  @override
  State<_UserStatItem> createState() => _UserStatItemState();
}

class _UserStatItemState extends State<_UserStatItem> {
  String? _loadedValue;

  @override
  void initState() {
    super.initState();
    if (widget.futureLoader != null) {
      widget.futureLoader!().then((val) {
        if (mounted) setState(() => _loadedValue = val);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(widget.icon, color: widget.iconColor, size: 28),
        ),
        const SizedBox(height: 12),
        Text(
          _loadedValue ?? widget.value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.title,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Haftalik savdo grafigi
class _WeeklyChart extends StatelessWidget {
  final Map<String, int> data;
  final NumberFormat currencyFormat;

  const _WeeklyChart({required this.data, required this.currencyFormat});

  @override
  Widget build(BuildContext context) {
    final maxValue = data.values.reduce((a, b) => a > b ? a : b);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: data.entries.map((entry) {
          final percentage = maxValue > 0 ? entry.value / maxValue : 0.0;
          
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (entry.value > 0)
                    Text(
                      _formatShort(entry.value),
                      style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                    ),
                  const SizedBox(height: 4),
                  Flexible(
                    child: FractionallySizedBox(
                      heightFactor: percentage.clamp(0.05, 1.0),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              AppTheme.accentOrange.withOpacity(0.3),
                              AppTheme.accentOrange,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    entry.key,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _formatShort(int value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}K';
    return value.toString();
  }
}
