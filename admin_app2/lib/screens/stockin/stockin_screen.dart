import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/locale_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/product.dart';
import '../../models/product_variant.dart';
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

  // Oddiy tovar uchun
  final _qtyController = TextEditingController();
  String _barcode = '';

  // Variantli tovar uchun: variant id -> kelgan soni controlleri
  List<ProductVariant> _variants = [];
  final Map<String, TextEditingController> _variantQty = {};

  // Umumiy
  final _priceController = TextEditingController(); // Kelish narxi
  final _sellPriceController = TextEditingController(); // Sotish narxi
  final _supplierController = TextEditingController();
  final _noteController = TextEditingController();
  bool _perPieceLabels = false; // har dona uchun etiketka (aks holda 1 ta)
  bool _saving = false;

  bool get _hasVariants => _selected?.hasVariants ?? false;

  @override
  void dispose() {
    _qtyController.dispose();
    _priceController.dispose();
    _sellPriceController.dispose();
    _supplierController.dispose();
    _noteController.dispose();
    for (final c in _variantQty.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pick(Product p) async {
    // Eski variant controllerlarni tozalash
    for (final c in _variantQty.values) {
      c.dispose();
    }
    _variantQty.clear();

    setState(() {
      _selected = p;
      _barcode = p.barcode;
      _variants = const [];
      if (p.buyPrice > 0) _priceController.text = '${p.buyPrice}';
      if (p.price > 0) _sellPriceController.text = '${p.price}';
    });

    if (p.hasVariants && p.id != null) {
      final pp = context.read<ProductProvider>();
      var list = pp.cachedVariants(p.id!);
      if (list.isEmpty) list = await pp.getVariants(p.id!);
      if (!mounted) return;
      setState(() {
        _variants = list;
        for (final v in list) {
          _variantQty[v.id ?? v.skuId] = TextEditingController(text: '0');
        }
      });
    }
  }

  int _variantInc(ProductVariant v) =>
      int.tryParse(_variantQty[v.id ?? v.skuId]?.text ?? '0') ?? 0;

  int get _totalIncoming {
    if (_hasVariants) {
      return _variants.fold(0, (s, v) => s + _variantInc(v));
    }
    return int.tryParse(_qtyController.text) ?? 0;
  }

  Future<void> _generateBarcode() async {
    if (_selected == null || _hasVariants) return;
    final pp = context.read<ProductProvider>();
    final code = BarcodeUtil.fromSeq(await pp.allocateSku());
    if (!mounted) return;
    setState(() => _barcode = code);
    await pp.updateProduct(_selected!.copyWith(barcode: code));
  }

  Future<void> _printLabels(LocaleProvider loc) async {
    final printer = context.read<PrinterProvider>();
    if (!printer.isConfigured) {
      _toast('${loc.t('settings.printer')} ${loc.t('common.notFound')}',
          AppTheme.accentRed);
      return;
    }
    if (_selected == null) return;
    final sellPrice =
        int.tryParse(_sellPriceController.text) ?? _selected!.price;

    if (_hasVariants) {
      for (final v in _variants) {
        final inc = _variantInc(v);
        if (inc <= 0 || v.barcode.isEmpty) continue;
        await printer.printProductLabel(
          productName: _selected!.name,
          barcode: v.barcode,
          price: '${sellPrice + (v.priceModifier ?? 0)}',
          size: v.size,
          color: v.color,
          article: BarcodeUtil.articleOf(v.barcode),
          copies: _perPieceLabels ? inc : 1,
        );
      }
    } else {
      if (_barcode.isEmpty) return;
      final copies = _perPieceLabels ? (int.tryParse(_qtyController.text) ?? 1) : 1;
      await printer.printProductLabel(
        productName: _selected!.name,
        barcode: _barcode,
        price: '$sellPrice',
        size: _selected!.size,
        color: _selected!.color,
        article: BarcodeUtil.articleOf(_barcode),
        copies: copies,
      );
    }
    if (mounted) _toast(loc.t('printer.labelPrinted'), AppTheme.accentGreen);
  }

  Future<void> _save(LocaleProvider loc) async {
    if (_selected == null) {
      _toast(loc.t('stockin.pickProduct'), AppTheme.accentRed);
      return;
    }
    final price = int.tryParse(_priceController.text) ?? 0;
    final sellPrice = int.tryParse(_sellPriceController.text) ?? 0;
    final total = _totalIncoming;
    if (total <= 0 || price <= 0) {
      _toast(loc.t('stockin.fillQtyPrice'), AppTheme.accentRed);
      return;
    }
    setState(() => _saving = true);

    final pp = context.read<ProductProvider>();
    final stockProvider = context.read<StockInProvider>();

    try {
      if (_hasVariants) {
        // Variantlar sonini oshirish
        final add = <String, int>{};
        for (final v in _variants) {
          final inc = _variantInc(v);
          if (inc > 0 && v.id != null) add[v.id!] = inc;
        }
        await pp.receiveVariants(
          _selected!.id!,
          add,
          buyPrice: price,
          sellPrice: sellPrice > 0 ? sellPrice : null,
        );
        // Tarix yozuvi (jami) — tovar soniga tegmasdan
        await stockProvider.addStockIn(
          StockIn(
            productId: _selected!.id!,
            productName: _selected!.name,
            quantity: total,
            buyPrice: price,
            supplier: _supplierController.text.trim().isEmpty
                ? null
                : _supplierController.text.trim(),
            note: _noteController.text.trim().isEmpty
                ? null
                : _noteController.text.trim(),
            createdAt: DateTime.now(),
          ),
          updateStock: false,
        );
      } else {
        // Barcode bo'lmasa generatsiya
        if (_barcode.isEmpty) await _generateBarcode();
        await stockProvider.addStockIn(
          StockIn(
            productId: _selected!.id!,
            productName: _selected!.name,
            quantity: total,
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
      }

      if (!mounted) return;
      await pp.loadProducts();
      if (!mounted) return;
      Navigator.pop(context);
      _toast(loc.t('common.success'), AppTheme.accentGreen);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        _toast('${loc.t('common.error')}: $e', AppTheme.accentRed);
      }
    }
  }

  void _toast(String msg, Color color) {
    if (!mounted) return;
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
          width: 480,
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

                // Narxlar (umumiy)
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
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
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        decoration: InputDecoration(
                            labelText: loc.t('product.sellPrice'),
                            suffixText: loc.t('common.sum')),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Oddiy yoki variantli bo'lim
                if (_selected == null)
                  _hint(loc.t('stockin.pickProduct'))
                else if (_hasVariants)
                  _variantSection(loc)
                else
                  _simpleSection(loc),

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
                const SizedBox(height: 12),

                // Etiketka rejimi
                if (_selected != null)
                  Row(
                    children: [
                      Checkbox(
                        value: _perPieceLabels,
                        activeColor: AppTheme.accentOrange,
                        onChanged: (v) =>
                            setState(() => _perPieceLabels = v ?? false),
                      ),
                      Expanded(
                        child: Text(loc.t('stockin.perPieceLabels'),
                            style: const TextStyle(
                                color: AppTheme.textSecondary, fontSize: 13)),
                      ),
                    ],
                  ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: (_selected == null || _totalIncoming <= 0)
                            ? null
                            : () => _printLabels(loc),
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

  Widget _hint(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppTheme.textSecondary)),
    );
  }

  Widget _simpleSection(LocaleProvider loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                      ? '${loc.t('product.barcode')}: ${loc.t('common.empty')}'
                      : () {
                          final art = BarcodeUtil.articleOf(_barcode);
                          return art.isEmpty ? _barcode : 'Art: $art  •  $_barcode';
                        }(),
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary),
                ),
              ),
              TextButton(
                onPressed: _generateBarcode,
                child: Text(loc.t('product.generateBarcode')),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _qtyController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (_) => setState(() {}),
          decoration:
              InputDecoration(labelText: loc.t('stockin.qtyIncoming')),
        ),
      ],
    );
  }

  Widget _variantSection(LocaleProvider loc) {
    if (_variants.isEmpty) {
      return _hint(loc.t('common.loading'));
    }
    // Rang, keyin razmer bo'yicha tartiblash
    const sizeOrder = ['XS', 'S', 'M', 'L', 'XL', 'XXL', '3XL'];
    final sorted = [..._variants]..sort((a, b) {
        final c = a.color.toLowerCase().compareTo(b.color.toLowerCase());
        if (c != 0) return c;
        final ai = sizeOrder.indexOf(a.size.toUpperCase());
        final bi = sizeOrder.indexOf(b.size.toUpperCase());
        return (ai == -1 ? 999 : ai).compareTo(bi == -1 ? 999 : bi);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(loc.t('stockin.byVariant'),
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary)),
            const Spacer(),
            Text('${loc.t('common.total')}: $_totalIncoming',
                style: const TextStyle(
                    color: AppTheme.accentOrange,
                    fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 240),
          child: SingleChildScrollView(
            child: Column(
              children: sorted.map((v) => _variantRow(loc, v)).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _variantRow(LocaleProvider loc, ProductVariant v) {
    final art = BarcodeUtil.articleOf(v.barcode);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${v.color} • ${v.size}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary)),
                const SizedBox(height: 2),
                Text(
                  '${art.isNotEmpty ? 'Art: $art  •  ' : ''}${loc.t('product.stock')}: ${v.quantity}',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 80,
            child: TextField(
              controller: _variantQty[v.id ?? v.skuId],
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: loc.t('stockin.qtyIncoming'),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
