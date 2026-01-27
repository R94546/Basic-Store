import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

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
                    children: [
                      const Icon(Icons.calendar_today, size: 18),
                      const SizedBox(width: 8),
                      const Text('Oxirgi 30 kun'),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Stats
          Expanded(
            child: Row(
              children: [
                // Left - Chart placeholder
                Expanded(
                  flex: 2,
                  child: GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Savdo grafigi',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.show_chart,
                                  size: 64,
                                  color: AppTheme.textSecondary.withOpacity(0.3),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Grafik tez orada qo\'shiladi',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Right - Stats
                SizedBox(
                  width: 300,
                  child: Column(
                    children: [
                      Expanded(
                        child: StatCard(
                          title: 'Jami savdo',
                          value: '45,200,000 so\'m',
                          icon: Icons.attach_money,
                          iconColor: AppTheme.accentGreen,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: StatCard(
                          title: 'Buyurtmalar soni',
                          value: '1,245',
                          icon: Icons.shopping_bag,
                          iconColor: AppTheme.accentOrange,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: StatCard(
                          title: 'O\'rtacha chek',
                          value: '350,000 so\'m',
                          icon: Icons.receipt,
                          iconColor: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
