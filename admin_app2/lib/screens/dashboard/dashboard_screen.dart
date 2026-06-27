import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../core/theme/app_theme.dart';
import '../../core/l10n/locale_provider.dart';
import '../../models/product.dart';
import '../../models/sale.dart';
import '../../providers/product_provider.dart';
import '../../providers/sale_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final currencyFormat =
      NumberFormat.currency(locale: 'uz_UZ', symbol: "so'm", decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final products = context.read<ProductProvider>();
      final sales = context.read<SaleProvider>();
      if (products.products.isEmpty) products.loadProducts();
      if (sales.sales.isEmpty) sales.loadSales();
    });
  }

  /// Bugungi foyda taxminini hisoblaydi: har bir savdo elementi uchun
  /// (sotish narxi - tan narxi) * soni. Mahsulot topilmasa tan narxi 0.
  int _todayProfit(List<Sale> todaySales, Map<String, Product> byId) {
    int profit = 0;
    for (final sale in todaySales) {
      for (final item in sale.items) {
        final cost = item.buyPrice > 0
            ? item.buyPrice
            : (byId[item.productId]?.buyPrice ?? 0);
        profit += (item.unitPrice - cost) * item.quantity;
      }
    }
    return profit;
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocaleProvider>();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(loc),
          const SizedBox(height: 24),

          // Stats grid - REAL DATA
          Consumer2<SaleProvider, ProductProvider>(
            builder: (context, saleProvider, productProvider, _) {
              final byId = {
                for (final p in productProvider.products)
                  if (p.id != null) p.id!: p
              };
              final profit = _todayProfit(saleProvider.todaySales, byId);
              // Sklad qiymati: kelish narxi bo'lmasa sotish narxidan hisoblanadi
              final stockValue = productProvider.products.fold<int>(
                  0,
                  (sum, p) =>
                      sum + p.quantity * (p.buyPrice > 0 ? p.buyPrice : p.price));

              final cards = <Widget>[
                _StatCard(
                  title: loc.t('dash.todaySales'),
                  value: currencyFormat.format(saleProvider.todayTotal),
                  icon: Icons.attach_money_rounded,
                  iconColor: AppTheme.accentGreen,
                ),
                _StatCard(
                  title: loc.t('dash.salesCount'),
                  value: NumberFormat.decimalPattern()
                      .format(saleProvider.todayCount),
                  icon: Icons.shopping_bag_rounded,
                  iconColor: AppTheme.accentOrange,
                ),
                _StatCard(
                  title: loc.t('dash.avgCheck'),
                  value: currencyFormat.format(saleProvider.averageCheck),
                  icon: Icons.receipt_long_rounded,
                  iconColor: Colors.blue,
                ),
                _StatCard(
                  title: loc.t('dash.profit'),
                  value: currencyFormat.format(profit),
                  icon: Icons.trending_up_rounded,
                  iconColor: Colors.teal,
                ),
                _StatCard(
                  title: loc.t('dash.stockValue'),
                  value: currencyFormat.format(stockValue),
                  icon: Icons.inventory_2_rounded,
                  iconColor: Colors.purple,
                ),
              ];

              return LayoutBuilder(
                builder: (context, constraints) {
                  // Responsive: 5 / 3 / 2 / 1 ustun
                  final width = constraints.maxWidth;
                  int columns;
                  if (width >= 1100) {
                    columns = 5;
                  } else if (width >= 800) {
                    columns = 3;
                  } else if (width >= 500) {
                    columns = 2;
                  } else {
                    columns = 1;
                  }
                  const spacing = 16.0;
                  final cardWidth =
                      (width - spacing * (columns - 1)) / columns;
                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: cards
                        .map((c) => SizedBox(width: cardWidth, child: c))
                        .toList(),
                  );
                },
              );
            },
          ),

          const SizedBox(height: 24),

          // Weekly sales bar chart
          Consumer<SaleProvider>(
            builder: (context, saleProvider, _) {
              final weekly = saleProvider.getWeeklyStats();
              return GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.t('report.weekly'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 220,
                      child: weekly.values.every((v) => v == 0)
                          ? _emptyChart(loc)
                          : _WeeklyBarChart(data: weekly),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // Two-column: low stock + recent sales (responsive)
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 900;
              final lowStock = _buildLowStock(loc);
              final recent = _buildRecentSales(loc);
              if (wide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: lowStock),
                    const SizedBox(width: 24),
                    Expanded(child: recent),
                  ],
                );
              }
              return Column(
                children: [
                  lowStock,
                  const SizedBox(height: 24),
                  recent,
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _emptyChart(LocaleProvider loc) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bar_chart_rounded,
              size: 56, color: AppTheme.textSecondary.withOpacity(0.3)),
          const SizedBox(height: 12),
          Text(loc.t('dash.noSales'),
              style: const TextStyle(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildLowStock(LocaleProvider loc) {
    return GlassCard(
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
                child: const Icon(Icons.warning_rounded,
                    color: AppTheme.accentRed),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  loc.t('dash.lowStock'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Consumer<ProductProvider>(
            builder: (context, provider, _) {
              // Tugaganlar (0) oldinda, keyin kam qolganlar
              final low = [...provider.lowStockProducts]
                ..sort((a, b) => a.quantity.compareTo(b.quantity));
              if (low.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(loc.t('dash.allStockOk'),
                      style: const TextStyle(color: AppTheme.textSecondary)),
                );
              }
              return Column(
                children: low
                    .take(10)
                    .map((p) => _StockAlertItem(
                          name: p.name,
                          count: p.quantity,
                          unit: loc.t('unit.pcs'),
                          outLabel: loc.t('product.outOfStock'),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSales(LocaleProvider loc) {
    final timeFmt = DateFormat('dd.MM HH:mm');
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                loc.t('dash.recentSales'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () => context.go('/sales'),
                child: Text(loc.t('common.all')),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Consumer<SaleProvider>(
            builder: (context, provider, _) {
              final recent = provider.sales.take(8).toList();
              if (recent.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(loc.t('dash.noSales'),
                      style: const TextStyle(color: AppTheme.textSecondary)),
                );
              }
              return Column(
                children: recent.map((sale) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () => _showSaleDetail(context, sale, loc),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor:
                                  AppTheme.accentGreen.withOpacity(0.2),
                              child: const Icon(Icons.receipt_long,
                                  size: 18, color: AppTheme.accentGreen),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    sale.number != null
                                        ? '#${sale.number}  ${loc.payLabel(sale.paymentMethod)}'
                                        : loc.payLabel(sale.paymentMethod),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    timeFmt.format(sale.createdAt),
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              currencyFormat.format(sale.totalAmount),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.chevron_right,
                                size: 18, color: AppTheme.textSecondary),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showSaleDetail(BuildContext context, Sale sale, LocaleProvider loc) {
    final dateFmt = DateFormat('dd.MM.yyyy HH:mm');
    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassCard(
          blur: 25,
          opacity: 0.95,
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${loc.t('pos.check')} #${sale.number ?? ''}',
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(dialogCtx),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                Text(dateFmt.format(sale.createdAt),
                    style: const TextStyle(color: AppTheme.textSecondary)),
                const Divider(height: 24),
                // Tovarlar
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 260),
                  child: SingleChildScrollView(
                    child: Column(
                      children: sale.items.map((it) {
                        final sub = (it.size != null || it.color != null)
                            ? ' (${[it.color, it.size].where((e) => e != null).join('/')})'
                            : '';
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text('${it.productName}$sub',
                                    style: const TextStyle(
                                        color: AppTheme.textPrimary)),
                              ),
                              Text(
                                  '${it.quantity} × ${currencyFormat.format(it.unitPrice)}',
                                  style: const TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 13)),
                              const SizedBox(width: 8),
                              Text(currencyFormat.format(it.subtotal),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const Divider(height: 24),
                if (sale.discountAmount > 0)
                  _detailRow(loc.t('product.discount'),
                      '-${currencyFormat.format(sale.discountAmount)}',
                      color: AppTheme.accentRed),
                _detailRow(loc.t('common.total'),
                    currencyFormat.format(sale.totalAmount),
                    bold: true),
                _detailRow(loc.t('pos.payment'),
                    loc.payLabel(sale.paymentMethod)),
                if (sale.changeAmount > 0)
                  _detailRow(loc.t('pos.change'),
                      currencyFormat.format(sale.changeAmount)),
                if (sale.customerName != null)
                  _detailRow(loc.t('pos.customer'), sale.customerName!),
                if (sale.note != null && sale.note!.isNotEmpty)
                  _detailRow(loc.t('common.note'), sale.note!),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value,
      {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary)),
          Text(value,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.bold : FontWeight.w500,
                  fontSize: bold ? 16 : 14,
                  color: color ?? AppTheme.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildHeader(LocaleProvider loc) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: loc.t('dash.searchHint'),
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
                  DateFormat('dd.MM.yyyy').format(DateTime.now()),
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Row(
            children: [
              Text(
                loc.t('dash.admin'),
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                radius: 20,
                backgroundColor: AppTheme.accentOrange.withOpacity(0.2),
                child: const Icon(Icons.person, color: AppTheme.accentOrange),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Haftalik savdo bar chart (fl_chart)
class _WeeklyBarChart extends StatelessWidget {
  final Map<String, int> data;
  const _WeeklyBarChart({required this.data});

  String _short(num value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}K';
    return value.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final entries = data.entries.toList();
    final maxVal =
        entries.map((e) => e.value).fold<int>(0, (m, v) => v > m ? v : m);
    final maxY = (maxVal == 0 ? 1 : maxVal) * 1.2;

    return BarChart(
      BarChartData(
        maxY: maxY,
        alignment: BarChartAlignment.spaceAround,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIdx, rod, rodIdx) => BarTooltipItem(
              _short(rod.toY),
              const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12),
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: AppTheme.textSecondary.withOpacity(0.15),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox.shrink();
                return Text(_short(value),
                    style: const TextStyle(
                        fontSize: 10, color: AppTheme.textSecondary));
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= entries.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(entries[idx].key,
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textSecondary)),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (int i = 0; i < entries.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: entries[i].value.toDouble(),
                  width: 22,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(6)),
                  gradient: const LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0x66FF9800), AppTheme.accentOrange],
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
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _StockAlertItem extends StatelessWidget {
  final String name;
  final int count;
  final String unit;
  final String outLabel; // "Tugagan" / "Нет в наличии"

  const _StockAlertItem(
      {required this.name,
      required this.count,
      required this.unit,
      required this.outLabel});

  @override
  Widget build(BuildContext context) {
    final out = count <= 0;
    final color = out ? AppTheme.accentRed : AppTheme.accentOrange;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(out ? Icons.remove_shopping_cart : Icons.warning_amber_rounded,
              size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              out ? outLabel : '$count $unit',
              style: TextStyle(
                color: color,
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
