import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/locale_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/product.dart';
import '../../models/stock_in.dart';
import '../../providers/printer_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/stock_in_provider.dart';
import '../../utils/barcode_util.dart';

/// Prixod qo'shish dialogini ochadi (Kassa ichidan ham chaqirsa bo'ladi).
Future<void> showStockInDialog(BuildContext context) {
  return showDialog(
    context: context,
    builder: (_) => const _AddStockInDialog(),
  );
}

class StockInScreen extends StatefulWidget {
  const StockInScreen({super.key});

  @override
  State<StockInScreen> createState() => _StockInScreenState();
}

class _StockInScreenState extends State<StockInScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts();
      context.read<StockInProvider>().loadStockIns();
    });
  }

  String _money(int v) => NumberFormat('#,###', 'ru').format(v).replaceAll(',', ' ');

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocaleProvider>();
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Text(loc.t('stockin.title'),
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary)),
                const Spacer(),
                Consumer<StockInProvider>(
                  builder: (context, p, _) => Text(
                    '${loc.t('stockin.todayTotal')}: ${_money(p.todayTotal)} ${loc.t('common.sum')}',
                    style: const TextStyle(
                        color: AppTheme.accentGreen,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => _openAddDialog(context),
                  icon: const Icon(Icons.add),
                  label: Text(loc.t('stockin.new')),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GlassCard(
              child: Consumer<StockInProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (provider.items.isEmpty) {
                    return Center(
                      child: Text(loc.t('common.empty'),
                          style:
                              const TextStyle(color: AppTheme.textSecondary)),
                    );
                  }
                  return ListView.separated(
                    itemCount: provider.items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final s = provider.items[index];
                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.accentGreen.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.arrow_downward,
                              color: AppTheme.accentGreen),
                        ),
                        title: Text(s.productName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary)),
                        subtitle: Text(
                          '${loc.t('stockin.qtyIncoming')}: ${s.quantity} • ${loc.t('product.buyPrice')}: ${_money(s.buyPrice)}'
                          '${s.supplier != null ? ' • ${s.supplier}' : ''}',
                          style: const TextStyle(color: AppTheme.textSecondary),
                        ),
                        trailing: Text(
                          '${_money(s.total)} ${loc.t('common.sum')}\n${DateFormat('dd.MM HH:mm').format(s.createdAt)}',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openAddDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const _AddStockInDialog(),
    );
  }
}

class _AddStockInDialog extends StatefulWidget {
  const _AddStockInDialog();

  @override
  State<_AddStockInDialog> createState() => _AddStockInDialogState();
}

class _AddStockInDialogState extends State<_AddStockInDialog> {
  Product? _selected;
  final _qtyController = TextEditingController();
  final _priceController = TextEditingController();      // Kelish narxi
  final _sellPriceController = TextEditingController();  // Sotish narxi
  final _supplierController = TextEditingController();
  final _noteController = TextEditingController();
  String _barcode = '';
  bool _saving = false;

  @override
  void dispose() {
    _qtyController.dispose();
    _priceController.dispose();
    _sellPriceController.dispose();
    _supplierController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _pick(Product p) {
    setState(() {
      _selected = p;
      _barcode = p.barcode;
      if (p.buyPrice > 0) _priceController.text = '${p.buyPrice}';
      if (p.price > 0) _sellPriceController.text = '${p.price}';
    });
  }

  Future<void> _generateBarcode() async {
    if (_selected == null) return;
    final code = BarcodeUtil.generateEan13(
        seed: DateTime.now().millisecondsSinceEpoch);
    setState(() => _barcode = code);
    // Mahsulotga saqlash
    await context
        .read<ProductProvider>()
        .updateProduct(_selected!.copyWith(barcode: code));
  }

  Future<void> _printLabel(LocaleProvider loc) async {
    final printer = context.read<PrinterProvider>();
    if (!printer.isConfigured) {
      _toast(loc.t('settings.printer') + ' ' + loc.t('common.notFound'),
          AppTheme.accentRed);
      return;
    }
    if (_barcode.isEmpty || _selected == null) return;
    final copies = int.tryParse(_qtyController.text) ?? 1;
    await printer.printProductLabel(
      productName: _selected!.name,
      barcode: _barcode,
      price: '${_priceController.text.isEmpty ? _selected!.price : _selected!.price}',
      size: _selected!.size,
      color: _selected!.color,
      copies: copies,
    );
  }

  Future<void> _save(LocaleProvider loc) async {
    if (_selected == null) {
      _toast(loc.t('pos.chooseVariant'), AppTheme.accentRed);
      return;
    }
    final qty = int.tryParse(_qtyController.text) ?? 0;
    final price = int.tryParse(_priceController.text) ?? 0;
    final sellPrice = int.tryParse(_sellPriceController.text) ?? 0;
    if (qty <= 0 || price <= 0) {
      _toast(loc.t('common.error'), AppTheme.accentRed);
      return;
    }
    setState(() => _saving = true);

    // Barcode bo'lmasa generatsiya
    if (_barcode.isEmpty) await _generateBarcode();

    final ok = await context.read<StockInProvider>().addStockIn(
          StockIn(
            productId: _selected!.id!,
            productName: _selected!.name,
            quantity: qty,
            buyPrice: price,
            supplier: _supplierController.text.trim().isEmpty
                ? null
                : _supplierController.text.trim(),
            note: _noteController.text.trim().isEmpty
                ? null
                : _noteController.text.trim(),
            createdAt: DateTime.now(),
          ),
          sellPrice: sellPrice > 0 ? sellPrice : null,
        );

    if (!mounted) return;
    setState(() => _saving = false);

    if (ok) {
      await context.read<ProductProvider>().loadProducts();
      if (!mounted) return;
      Navigator.pop(context);
      _toast(loc.t('common.success'), AppTheme.accentGreen);
    } else {
      _toast(loc.t('common.error'), AppTheme.accentRed);
    }
  }

  void _toast(String msg, Color color) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocaleProvider>();
    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassCard(
        blur: 25,
        opacity: 0.95,
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(loc.t('stockin.new'),
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary)),
                const SizedBox(height: 16),

                // Mahsulot tanlash
                Consumer<ProductProvider>(
                  builder: (context, p, _) {
                    return DropdownButtonFormField<Product>(
                      initialValue: _selected,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: loc.t('common.name'),
                        prefixIcon: const Icon(Icons.inventory_2_outlined),
                      ),
                      items: p.products
                          .map((prod) => DropdownMenuItem(
                                value: prod,
                                child: Text(prod.name,
                                    overflow: TextOverflow.ellipsis),
                              ))
                          .toList(),
                      onChanged: (v) => v == null ? null : _pick(v),
                    );
                  },
                ),
                const SizedBox(height: 12),

                // Barcode
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.qr_code, color: AppTheme.textSecondary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _barcode.isEmpty
                              ? loc.t('product.barcode') +
                                  ': ' +
                                  loc.t('common.empty')
                              : _barcode,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary),
                        ),
                      ),
                      TextButton(
                        onPressed: _selected == null ? null : _generateBarcode,
                        child: Text(loc.t('product.generateBarcode')),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: _qtyController,
                  keyboardType: TextInputType.number,
                  decoration:
                      InputDecoration(labelText: loc.t('stockin.qtyIncoming')),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                            labelText: loc.t('product.buyPrice'),
                            suffixText: loc.t('common.sum')),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _sellPriceController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                            labelText: loc.t('product.sellPrice'),
                            suffixText: loc.t('common.sum')),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _supplierController,
                  decoration:
                      InputDecoration(labelText: loc.t('stockin.supplier')),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _noteController,
                  decoration: InputDecoration(labelText: loc.t('common.note')),
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _barcode.isEmpty ? null : () => _printLabel(loc),
                        icon: const Icon(Icons.print),
                        label: Text(loc.t('product.printLabel')),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _saving ? null : () => _save(loc),
                        icon: _saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.check),
                        label: Text(loc.t('common.save')),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentGreen),
                      ),
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
