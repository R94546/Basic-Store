import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/l10n/locale_provider.dart';
import '../core/theme/app_theme.dart';
import '../models/product.dart';
import '../models/product_variant.dart';
import '../providers/printer_provider.dart';
import '../providers/product_provider.dart';
import '../utils/barcode_util.dart';

/// Etiketka (birka) chop etish dialogini ochadi.
///
/// Oddiy tovar uchun — bitta etiketka (nusxa soni bilan). Variantli tovar uchun
/// — har bir rang/razmer alohida, har biriga nusxa soni. Saqlangan shtrixni
/// qayta chiqaradi (dublikat).
Future<void> showLabelPrintDialog(BuildContext context, Product product) async {
  List<ProductVariant> variants = const [];
  if (product.hasVariants && product.id != null) {
    final pp = context.read<ProductProvider>();
    variants = pp.cachedVariants(product.id!);
    if (variants.isEmpty) variants = await pp.getVariants(product.id!);
  }
  if (!context.mounted) return;
  await showDialog(
    context: context,
    builder: (_) => _LabelPrintDialog(product: product, variants: variants),
  );
}

class _LabelPrintDialog extends StatefulWidget {
  final Product product;
  final List<ProductVariant> variants;
  const _LabelPrintDialog({required this.product, required this.variants});

  @override
  State<_LabelPrintDialog> createState() => _LabelPrintDialogState();
}

class _LabelPrintDialogState extends State<_LabelPrintDialog> {
  // Variant id (yoki 'simple') -> nusxa soni controlleri.
  final Map<String, TextEditingController> _copies = {};
  bool _printing = false;

  bool get _hasVariants => widget.variants.isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (_hasVariants) {
      for (final v in widget.variants) {
        _copies[v.id ?? v.skuId] = TextEditingController(text: '1');
      }
    } else {
      _copies['simple'] = TextEditingController(text: '1');
    }
  }

  @override
  void dispose() {
    for (final c in _copies.values) {
      c.dispose();
    }
    super.dispose();
  }

  int _n(String key) => int.tryParse(_copies[key]?.text ?? '1') ?? 1;

  void _toast(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  Future<void> _printAll(LocaleProvider loc) async {
    final printer = context.read<PrinterProvider>();
    if (!printer.isConfigured) {
      _toast(loc.t('printer.notConfigured'), AppTheme.accentRed);
      return;
    }
    setState(() => _printing = true);
    int done = 0;
    try {
      if (_hasVariants) {
        for (final v in widget.variants) {
          final copies = _n(v.id ?? v.skuId);
          if (copies <= 0 || v.barcode.isEmpty) continue;
          final ok = await printer.printProductLabel(
            productName: widget.product.name,
            barcode: v.barcode,
            price: (widget.product.price + (v.priceModifier ?? 0)).toString(),
            size: v.size,
            color: v.color,
            article: BarcodeUtil.articleOf(v.barcode),
            copies: copies,
          );
          if (ok) done++;
        }
      } else {
        final copies = _n('simple');
        if (copies > 0 && widget.product.barcode.isNotEmpty) {
          final ok = await printer.printProductLabel(
            productName: widget.product.name,
            barcode: widget.product.barcode,
            price: widget.product.price.toString(),
            size: widget.product.size,
            color: widget.product.color,
            article: BarcodeUtil.articleOf(widget.product.barcode),
            copies: copies,
          );
          if (ok) done++;
        }
      }
    } finally {
      if (mounted) setState(() => _printing = false);
    }
    if (!mounted) return;
    if (done > 0) {
      Navigator.pop(context);
      _toast(loc.t('printer.labelPrinted'), AppTheme.accentGreen);
    } else {
      _toast(loc.t('printer.printError'), AppTheme.accentRed);
    }
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.print, color: AppTheme.accentOrange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${loc.t('product.printLabel')} — ${widget.product.name}',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  child: _hasVariants ? _variantList(loc) : _simpleRow(loc),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _printing ? null : () => _printAll(loc),
                  icon: _printing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.print),
                  label: Text(loc.t('common.print')),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _simpleRow(LocaleProvider loc) {
    final art = BarcodeUtil.articleOf(widget.product.barcode);
    return _tile(
      title: '${widget.product.size}'
          '${widget.product.color != null ? ' • ${widget.product.color}' : ''}',
      article: art,
      barcode: widget.product.barcode,
      stock: widget.product.quantity,
      copiesKey: 'simple',
      loc: loc,
    );
  }

  Widget _variantList(LocaleProvider loc) {
    return Column(
      children: widget.variants.map((v) {
        return _tile(
          title: '${v.color} • ${v.size}',
          article: BarcodeUtil.articleOf(v.barcode),
          barcode: v.barcode,
          stock: v.quantity,
          copiesKey: v.id ?? v.skuId,
          loc: loc,
        );
      }).toList(),
    );
  }

  Widget _tile({
    required String title,
    required String article,
    required String barcode,
    required int stock,
    required String copiesKey,
    required LocaleProvider loc,
  }) {
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
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary)),
                const SizedBox(height: 2),
                Text(
                  '${article.isNotEmpty ? 'Art: $article  •  ' : ''}'
                  '${loc.t('product.stock')}: $stock',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 70,
            child: TextField(
              controller: _copies[copiesKey],
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: loc.t('label.copies'),
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
