import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../core/theme/app_theme.dart';
import '../../core/l10n/locale_provider.dart';
import '../../models/sale.dart';
import '../../providers/product_provider.dart';
import '../../providers/sale_provider.dart';

enum _Period { today, week, all }

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final _currencyFormat =
      NumberFormat.currency(locale: 'uz_UZ', symbol: "so'm", decimalDigits: 0);

  _Period _period = _Period.week;

  // To'lov turi ranglari
  static const _payColors = <String, Color>{
    'cash': AppTheme.accentGreen,
    'card': Colors.blue,
    'debt': AppTheme.accentRed,
  };

  // Kategoriya pie uchun rang palitri
  static const _palette = <Color>[
    AppTheme.accentOrange,
    AppTheme.accentGreen,
    Colors.blue,
    Colors.purple,
    Colors.teal,
    Colors.pinkAccent,
    Colors.indigo,
    Colors.brown,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sales = context.read<SaleProvider>();
      final products = context.read<ProductProvider>();
      if (sales.sales.isEmpty) sales.loadSales();
      if (products.products.isEmpty) products.loadProducts();
    });
  }

  /// Tanlangan davr bo'yicha savdolarni filtrlaydi.
  List<Sale> _filterSales(List<Sale> all) {
    final now = DateTime.now();
    switch (_period) {
      case _Period.today:
        final start = DateTime(now.year, now.month, now.day);
        return all.where((s) => s.createdAt.isAfter(start)).toList();
      case _Period.week:
        final start = now.subtract(const Duration(days: 7));
        return all.where((s) => s.createdAt.isAfter(start)).toList();
      case _Period.all:
        return all;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocaleProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Consumer2<SaleProvider, ProductProvider>(
        builder: (context, saleProvider, productProvider, _) {
          final sales = _filterSales(saleProvider.sales);
          final byId = {
            for (final p in productProvider.products)
              if (p.id != null) p.id!: p
          };

          // ----- Aggregations -----
          int revenue = 0;
          int discount = 0;
          int profit = 0;
          final payTotals = <String, int>{'cash': 0, 'card': 0, 'debt': 0};
          final categoryTotals = <String, int>{};
          final productQty = <String, int>{};

          for (final sale in sales) {
            revenue += sale.totalAmount;
            discount += sale.discountAmount;
            payTotals[sale.paymentMethod] =
                (payTotals[sale.paymentMethod] ?? 0) + sale.totalAmount;
            for (final item in sale.items) {
              final product = byId[item.productId];
              final cost = product?.buyPrice ?? 0;
              profit += (item.unitPrice - cost) * item.quantity;
              final cat = (product?.category.isNotEmpty ?? false)
                  ? product!.category
                  : loc.t('common.other');
              categoryTotals[cat] =
                  (categoryTotals[cat] ?? 0) + item.unitPrice * item.quantity;
              productQty[item.productName] =
                  (productQty[item.productName] ?? 0) + item.quantity;
            }
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(loc),
              const SizedBox(height: 24),

              // KPI row
              _buildKpiRow(revenue, profit, discount, sales.length),
              const SizedBox(height: 24),

              // Pie charts row (responsive)
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 860;
                  final payCard = _buildPaymentPie(loc, payTotals);
                  final catCard = _buildCategoryPie(loc, categoryTotals);
                  if (wide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: payCard),
                        const SizedBox(width: 24),
                        Expanded(child: catCard),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      payCard,
                      const SizedBox(height: 24),
                      catCard,
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // Weekly trend line chart (always last 7 days)
              _buildTrendCard(loc, saleProvider.getWeeklyStats()),
              const SizedBox(height: 24),

              // Top products
              _buildTopProducts(loc, productQty),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(LocaleProvider loc) {
    Widget chip(String label, _Period value) {
      final selected = _period == value;
      return GestureDetector(
        onTap: () => setState(() => _period = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.accentOrange
                : Colors.white.withOpacity(0.35),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      );
    }

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 12,
        children: [
          Text(
            loc.t('nav.reports'),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              chip(loc.t('common.today'), _Period.today),
              const SizedBox(width: 8),
              chip(loc.t('report.week'), _Period.week),
              const SizedBox(width: 8),
              chip(loc.t('report.all'), _Period.all),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKpiRow(int revenue, int profit, int discount, int count) {
    final loc = context.read<LocaleProvider>();
    final items = <Widget>[
      _KpiCard(
        title: loc.t('dash.revenue'),
        value: _currencyFormat.format(revenue),
        icon: Icons.payments_rounded,
        color: AppTheme.accentGreen,
      ),
      _KpiCard(
        title: loc.t('dash.profit'),
        value: _currencyFormat.format(profit),
        icon: Icons.trending_up_rounded,
        color: Colors.teal,
      ),
      _KpiCard(
        title: loc.t('report.discountGiven'),
        value: _currencyFormat.format(discount),
        icon: Icons.discount_rounded,
        color: AppTheme.accentRed,
      ),
      _KpiCard(
        title: loc.t('dash.salesCount'),
        value: NumberFormat.decimalPattern().format(count),
        icon: Icons.receipt_long_rounded,
        color: AppTheme.accentOrange,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 800 ? 4 : (width >= 480 ? 2 : 1);
        const spacing = 16.0;
        final cardWidth = (width - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: items
              .map((c) => SizedBox(width: cardWidth, child: c))
              .toList(),
        );
      },
    );
  }

  Widget _buildPaymentPie(LocaleProvider loc, Map<String, int> payTotals) {
    final total = payTotals.values.fold<int>(0, (a, b) => a + b);

    final sections = <PieChartSectionData>[];
    final legend = <Widget>[];
    payTotals.forEach((key, value) {
      if (value <= 0) return;
      final pct = total > 0 ? value / total * 100 : 0;
      final color = _payColors[key]!;
      sections.add(PieChartSectionData(
        value: value.toDouble(),
        color: color,
        title: '${pct.toStringAsFixed(0)}%',
        radius: 60,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ));
      legend.add(_LegendItem(
        color: color,
        label: loc.payLabel(key),
        value: _currencyFormat.format(value),
      ));
    });

    return _PieCard(
      title: loc.t('report.byPayment'),
      emptyText: loc.t('report.noData'),
      sections: sections,
      legend: legend,
    );
  }

  Widget _buildCategoryPie(LocaleProvider loc, Map<String, int> catTotals) {
    final total = catTotals.values.fold<int>(0, (a, b) => a + b);
    final entries = catTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final sections = <PieChartSectionData>[];
    final legend = <Widget>[];
    for (int i = 0; i < entries.length; i++) {
      final e = entries[i];
      if (e.value <= 0) continue;
      final color = _palette[i % _palette.length];
      final pct = total > 0 ? e.value / total * 100 : 0;
      sections.add(PieChartSectionData(
        value: e.value.toDouble(),
        color: color,
        title: pct >= 6 ? '${pct.toStringAsFixed(0)}%' : '',
        radius: 60,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ));
      legend.add(_LegendItem(
        color: color,
        label: e.key,
        value: _currencyFormat.format(e.value),
      ));
    }

    return _PieCard(
      title: loc.t('report.byCategory'),
      emptyText: loc.t('report.noData'),
      sections: sections,
      legend: legend,
    );
  }

  Widget _buildTrendCard(LocaleProvider loc, Map<String, int> weekly) {
    final entries = weekly.entries.toList();
    final maxVal =
        entries.map((e) => e.value).fold<int>(0, (m, v) => v > m ? v : m);
    final hasData = maxVal > 0;

    String short(num value) {
      if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
      if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}K';
      return value.toStringAsFixed(0);
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${loc.t('report.weekly')} (${loc.t('report.revenueTrend')})',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 240,
            child: !hasData
                ? Center(
                    child: Text(loc.t('report.noData'),
                        style: TextStyle(
                            color: AppTheme.textSecondary.withOpacity(0.7))),
                  )
                : LineChart(
                    LineChartData(
                      minY: 0,
                      maxY: maxVal * 1.2,
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
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 44,
                            getTitlesWidget: (value, meta) {
                              if (value == 0) return const SizedBox.shrink();
                              return Text(short(value),
                                  style: const TextStyle(
                                      fontSize: 10,
                                      color: AppTheme.textSecondary));
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
                                        fontSize: 11,
                                        color: AppTheme.textSecondary)),
                              );
                            },
                          ),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          isCurved: true,
                          color: AppTheme.accentOrange,
                          barWidth: 3,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppTheme.accentOrange.withOpacity(0.18),
                          ),
                          spots: [
                            for (int i = 0; i < entries.length; i++)
                              FlSpot(i.toDouble(), entries[i].value.toDouble()),
                          ],
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopProducts(LocaleProvider loc, Map<String, int> productQty) {
    final entries = productQty.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = entries.take(8).toList();
    final maxQty =
        top.isEmpty ? 1 : top.first.value;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.t('dash.topProducts'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          if (top.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(loc.t('report.noData'),
                  style: const TextStyle(color: AppTheme.textSecondary)),
            )
          else
            ...top.asMap().entries.map((e) {
              final rank = e.key + 1;
              final item = e.value;
              final fraction = maxQty > 0 ? item.value / maxQty : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppTheme.accentOrange.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('$rank',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.accentOrange,
                              fontSize: 13)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.key,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: fraction.clamp(0.02, 1.0),
                              minHeight: 6,
                              backgroundColor: Colors.white.withOpacity(0.3),
                              valueColor: const AlwaysStoppedAnimation(
                                  AppTheme.accentOrange),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('${item.value} ${loc.t('unit.pcs')}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary)),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

/// Pie chart + legenda umumiy karta
class _PieCard extends StatelessWidget {
  final String title;
  final String emptyText;
  final List<PieChartSectionData> sections;
  final List<Widget> legend;

  const _PieCard({
    required this.title,
    required this.emptyText,
    required this.sections,
    required this.legend,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          if (sections.isEmpty)
            SizedBox(
              height: 180,
              child: Center(
                child: Text(emptyText,
                    style: const TextStyle(color: AppTheme.textSecondary)),
              ),
            )
          else ...[
            SizedBox(
              height: 180,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 32,
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: legend,
            ),
          ],
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$label  ',
          style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500),
        ),
        Text(
          value,
          style: const TextStyle(
              color: AppTheme.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 22,
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
