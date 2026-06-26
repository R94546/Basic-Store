import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/l10n/locale_provider.dart';
import '../core/theme/app_theme.dart';
import '../models/product.dart';
import '../providers/category_provider.dart';
import '../providers/product_provider.dart';
import '../utils/barcode_util.dart';

/// Skanerlangan, ammo bazada topilmagan shtrixni mavjud mahsulotga UMUMIY
/// biriktirish (variantli bo'lsa ham — har variantga emas) yoki shu shtrix
/// bilan yangi tovar yaratish dialogi. Biriktirilgan/yaratilgan tovarni
/// qaytaradi (yoki null — bekor qilindi).
Future<Product?> showBindBarcodeDialog(BuildContext context, String barcode) {
  return showDialog<Product>(
    context: context,
    builder: (_) => _BindBarcodeDialog(barcode: barcode),
  );
}

class _BindBarcodeDialog extends StatefulWidget {
  final String barcode;
  const _BindBarcodeDialog({required this.barcode});

  @override
  State<_BindBarcodeDialog> createState() => _BindBarcodeDialogState();
}

class _BindBarcodeDialogState extends State<_BindBarcodeDialog> {
  final _searchCtrl = TextEditingController();
  bool _saving = false;

  // Yangi tovar (tezkor)
  bool _newMode = false;
  final _nNameCtrl = TextEditingController();
  final _nSellCtrl = TextEditingController();
  final _nQtyCtrl = TextEditingController(text: '1');
  String? _nCategory;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _nNameCtrl.dispose();
    _nSellCtrl.dispose();
    _nQtyCtrl.dispose();
    super.dispose();
  }

  Future<void> _pick(Product product) async {
    final pp = context.read<ProductProvider>();
    final loc = context.read<LocaleProvider>();
    setState(() => _saving = true);
    try {
      await pp.assignBarcodeToProduct(product.id!, widget.barcode);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${loc.t('common.error')}: $e'),
        backgroundColor: AppTheme.accentRed,
      ));
      return;
    }
    if (!mounted) return;
    Navigator.pop(context, product);
  }

  void _startNew() {
    final cats = context.read<CategoryProvider>().categoryNames;
    setState(() {
      _newMode = true;
      _nCategory = cats.isNotEmpty ? cats.first : null;
    });
  }

  Future<void> _saveNew() async {
    final loc = context.read<LocaleProvider>();
    final pp = context.read<ProductProvider>();
    final name = _nNameCtrl.text.trim();
    final sell = int.tryParse(_nSellCtrl.text) ?? 0;
    final qty = int.tryParse(_nQtyCtrl.text) ?? 0;
    if (name.isEmpty || sell <= 0 || qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(loc.t('stockin.fillQtyPrice')),
        backgroundColor: AppTheme.accentRed,
      ));
      return;
    }
    setState(() => _saving = true);
    try {
      final id = await pp.addProduct(Product(
        name: name,
        category: _nCategory ?? '',
        size: '-',
        price: sell,
        quantity: qty,
        barcode: widget.barcode,
        hasVariants: false,
      ));
      if (id == null) throw Exception('addProduct');
      await pp.loadProducts();
      if (!mounted) return;
      final created = pp.products.firstWhere((p) => p.id == id);
      Navigator.pop(context, created);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${loc.t('common.error')}: $e'),
        backgroundColor: AppTheme.accentRed,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocaleProvider>();
    final pp = context.watch<ProductProvider>();
    final products = pp.searchProducts(_searchCtrl.text);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassCard(
        blur: 20,
        opacity: 0.95,
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.qr_code_scanner, color: AppTheme.accentOrange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      loc.t('bind.title'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.accentOrange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.barcode_reader, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      widget.barcode,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (_newMode) _newForm(loc) else _bindBody(loc, products),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bindBody(LocaleProvider loc, List<Product> products) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          loc.t('bind.hint'),
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: loc.t('pos.searchHint'),
                  prefixIcon: const Icon(Icons.search),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _startNew,
              icon: const Icon(Icons.add),
              label: Text(loc.t('prixod.newProductBtn')),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 300,
          child: _saving
              ? const Center(child: CircularProgressIndicator())
              : products.isEmpty
                  ? Center(
                      child: Text(loc.t('common.notFound'),
                          style:
                              const TextStyle(color: AppTheme.textSecondary)))
                  : ListView.builder(
                      itemCount: products.length,
                      itemBuilder: (context, i) {
                        final p = products[i];
                        final art = BarcodeUtil.articleOf(p.barcode);
                        return ListTile(
                          leading: const Icon(Icons.checkroom),
                          title: Text(p.name),
                          subtitle: Text(p.hasVariants
                              ? loc.t('bind.hasVariants')
                              : (art.isNotEmpty ? 'Art: $art' : '')),
                          trailing: const Icon(Icons.link,
                              color: AppTheme.accentOrange),
                          onTap: () => _pick(p),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _newForm(LocaleProvider loc) {
    final cats = context.watch<CategoryProvider>().categoryNames;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _nNameCtrl,
          autofocus: true,
          decoration: InputDecoration(
              labelText: loc.t('common.name'),
              prefixIcon: const Icon(Icons.checkroom)),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _nCategory,
          isExpanded: true,
          decoration: InputDecoration(labelText: loc.t('common.category')),
          items: cats
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: (v) => setState(() => _nCategory = v),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _nSellCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                    labelText: loc.t('product.sellPrice'),
                    suffixText: loc.t('common.sum')),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 100,
              child: TextField(
                controller: _nQtyCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration:
                    InputDecoration(labelText: loc.t('stockin.qtyIncoming')),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _newMode = false),
                child: Text(loc.t('common.cancel')),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _saveNew,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.check),
                label: Text(loc.t('common.save')),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentGreen),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
