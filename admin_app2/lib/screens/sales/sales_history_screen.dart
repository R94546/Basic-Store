import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../core/l10n/locale_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/sale.dart';
import '../../providers/sale_provider.dart';

/// Savdo tarixi ekrani
class SalesHistoryScreen extends StatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  final _currencyFormat = NumberFormat.currency(locale: 'uz_UZ', symbol: "so'm", decimalDigits: 0);
  final _dateFormat = DateFormat('dd.MM.yyyy HH:mm');
  DateTimeRange? _range;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SaleProvider>().loadSales();
    });
  }

  /// Tanlangan sana oralig'i bo'yicha savdolarni filtrlaydi.
  List<Sale> _filter(List<Sale> all) {
    final r = _range;
    if (r == null) return all;
    final end = DateTime(r.end.year, r.end.month, r.end.day)
        .add(const Duration(days: 1));
    final start = DateTime(r.start.year, r.start.month, r.start.day);
    return all
        .where((s) => s.createdAt.isAfter(start) && s.createdAt.isBefore(end))
        .toList();
  }

  String _dateOnly(DateTime d) => DateFormat('dd.MM.yyyy').format(d);

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _range,
    );
    if (picked != null) setState(() => _range = picked);
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocaleProvider>();
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(
                loc.t('nav.sales'),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              // Bugungi statistika
              Consumer<SaleProvider>(
                builder: (context, provider, _) {
                  return Row(
                    children: [
                      _MiniStat(
                        label: loc.t('common.today'),
                        value: _currencyFormat.format(provider.todayTotal),
                        color: AppTheme.accentGreen,
                      ),
                      const SizedBox(width: 16),
                      _MiniStat(
                        label: loc.t('dash.salesCount'),
                        value: '${provider.todayCount}',
                        color: AppTheme.accentOrange,
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          
          const SizedBox(height: 16),

          // Sana filtri
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _pickRange,
                icon: const Icon(Icons.date_range, size: 18),
                label: Text(_range == null
                    ? loc.t('sales.pickDate')
                    : '${_dateOnly(_range!.start)} — ${_dateOnly(_range!.end)}'),
              ),
              if (_range != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => setState(() => _range = null),
                  icon: const Icon(Icons.clear, size: 18),
                  tooltip: loc.t('common.cancel'),
                ),
              ],
            ],
          ),

          const SizedBox(height: 16),

          // Savdolar ro'yxati
          Expanded(
            child: Consumer<SaleProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                final sales = _filter(provider.sales);
                if (sales.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long, size: 64, color: AppTheme.textSecondary.withOpacity(0.3)),
                        const SizedBox(height: 16),
                        Text(
                          loc.t('sales.noSales'),
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }
                
                return GlassCard(
                  padding: EdgeInsets.zero,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: sales.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final sale = sales[index];
                      return _SaleListItem(
                        sale: sale,
                        currencyFormat: _currencyFormat,
                        dateFormat: _dateFormat,
                        itemsUnit: loc.t('unit.items'),
                        onTap: () => _showSaleDetails(sale),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showSaleDetails(Sale sale) {
    final loc = context.read<LocaleProvider>();
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassCard(
          blur: 20,
          opacity: 0.95,
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Text(
                      loc.t('sales.details'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _dateFormat.format(sale.createdAt),
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                
                // Tovarlar
                Text(
                  loc.t('sales.products'),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                
                ...sale.items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.productName,
                          style: const TextStyle(color: AppTheme.textPrimary),
                        ),
                      ),
                      Text(
                        '${item.quantity} x ',
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                      if (item.discount != null && item.discount! > 0) ...[
                        Text(
                          _currencyFormat.format(item.originalPrice),
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            decoration: TextDecoration.lineThrough,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        _currencyFormat.format(item.unitPrice),
                        style: const TextStyle(color: AppTheme.textPrimary),
                      ),
                    ],
                  ),
                )),
                
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                
                // Jami
                if (sale.discountAmount > 0) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(loc.t('sales.originalAmount'), style: const TextStyle(color: AppTheme.textSecondary)),
                      Text(_currencyFormat.format(sale.originalAmount)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(loc.t('sales.discountLabel'), style: const TextStyle(color: AppTheme.accentRed)),
                      Text(
                        '-${_currencyFormat.format(sale.discountAmount)}',
                        style: const TextStyle(color: AppTheme.accentRed),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      loc.t('sales.totalUpper'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _currencyFormat.format(sale.totalAmount),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accentOrange,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // To'lov usuli
                Row(
                  children: [
                    Icon(
                      sale.paymentMethod == 'cash' ? Icons.payments : Icons.credit_card,
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      loc.payLabel(sale.paymentMethod),
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(color: color, fontSize: 12),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _SaleListItem extends StatelessWidget {
  final Sale sale;
  final NumberFormat currencyFormat;
  final DateFormat dateFormat;
  final String itemsUnit;
  final VoidCallback onTap;

  const _SaleListItem({
    required this.sale,
    required this.currencyFormat,
    required this.dateFormat,
    required this.itemsUnit,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            // Vaqt
            Container(
              width: 80,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('HH:mm').format(sale.createdAt),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    DateFormat('dd.MM').format(sale.createdAt),
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Tovarlar
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sale.items.map((e) => e.productName).join(', '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${sale.items.fold<int>(0, (s, i) => s + i.quantity)} $itemsUnit',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Narx
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currencyFormat.format(sale.totalAmount),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accentOrange,
                  ),
                ),
                if (sale.discountAmount > 0)
                  Text(
                    '-${currencyFormat.format(sale.discountAmount)}',
                    style: const TextStyle(
                      color: AppTheme.accentRed,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            
            const SizedBox(width: 8),
            
            const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}
