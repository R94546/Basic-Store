import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SaleProvider>().loadSales();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Text(
                'Savdo tarixi',
                style: TextStyle(
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
                        label: 'Bugun',
                        value: _currencyFormat.format(provider.todayTotal),
                        color: AppTheme.accentGreen,
                      ),
                      const SizedBox(width: 16),
                      _MiniStat(
                        label: 'Savdolar',
                        value: '${provider.todayCount}',
                        color: AppTheme.accentOrange,
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Savdolar ro'yxati
          Expanded(
            child: Consumer<SaleProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (provider.sales.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long, size: 64, color: AppTheme.textSecondary.withOpacity(0.3)),
                        const SizedBox(height: 16),
                        const Text(
                          'Hali savdolar yo\'q',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }
                
                return GlassCard(
                  padding: EdgeInsets.zero,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.sales.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final sale = provider.sales[index];
                      return _SaleListItem(
                        sale: sale,
                        currencyFormat: _currencyFormat,
                        dateFormat: _dateFormat,
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
                    const Text(
                      'Savdo tafsilotlari',
                      style: TextStyle(
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
                const Text(
                  'Tovarlar:',
                  style: TextStyle(fontWeight: FontWeight.w600),
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
                      const Text('Asl summa:', style: TextStyle(color: AppTheme.textSecondary)),
                      Text(_currencyFormat.format(sale.originalAmount)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Chegirma:', style: TextStyle(color: AppTheme.accentRed)),
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
                    const Text(
                      'JAMI:',
                      style: TextStyle(
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
                      sale.paymentMethod == 'cash' ? 'Naqd' : 'Karta',
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
  final VoidCallback onTap;

  const _SaleListItem({
    required this.sale,
    required this.currencyFormat,
    required this.dateFormat,
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
                    '${sale.items.length} tovar',
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
