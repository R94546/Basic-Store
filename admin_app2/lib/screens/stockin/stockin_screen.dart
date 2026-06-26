import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/locale_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/product.dart';
import '../../models/product_variant.dart';
import '../../models/stock_in.dart';
import '../../providers/category_provider.dart';
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

/// Bu seansda qabul qilingan bitta yozuv (log uchun).
class _RxEntry {
  final String name;
  final int qty;
  final int sum; // qty * kelish narxi
  final DateTime at;
  _RxEntry(this.name, this.qty, this.sum, this.at);
}

/// Bitta-oyna PRIXOD: skanerlaysiz yoki nom/narx bo'yicha qidirasiz →
/// mavjud tovarni qabul qilasiz YOKI yangi tovar qo'shasiz → birka chop
/// etiladi → seans logiga yoziladi. Oynadan chiqmasdan, tez.
class _StockInScreenState extends State<StockInScreen> {
  final _scanCtrl = TextEditingController();
  final _scanFocus = FocusNode();
  final _qtyFocus = FocusNode();
  final _nameFocus = FocusNode();
  String _query = '';

  // === Mavjud tovarni qabul qilish ===
  Product? _selected;
  List<ProductVariant> _variants = [];
  final Map<String, TextEditingController> _vQty = {};
  final _qtyCtrl = TextEditingController();
  final _buyCtrl = TextEditingController();
  final _sellCtrl = TextEditingController();
  bool _perPiece = true; // har dona uchun birka
  String _barcode = '';

  // === Yangi tovar ===
  bool _newMode = false;
  String? _pendingBarcode;
  final _nNameCtrl = TextEditingController();
  final _nBuyCtrl = TextEditingController();
  final _nSellCtrl = TextEditingController();
  final _nQtyCtrl = TextEditingController(text: '1');
  String? _nCategory;

  bool _busy = false;
  final List<_RxEntry> _session = [];

  int get _sessionTotal => _session.fold(0, (s, e) => s + e.sum);
  bool get _hasVariants => _selected?.hasVariants ?? false;
  LocaleProvider get _loc => context.read<LocaleProvider>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts();
      context.read<StockInProvider>().loadStockIns();
      context.read<CategoryProvider>().loadCategories();
      _scanFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _scanCtrl.dispose();
    _scanFocus.dispose();
    _qtyFocus.dispose();
    _nameFocus.dispose();
    _qtyCtrl.dispose();
    _buyCtrl.dispose();
    _sellCtrl.dispose();
    _nNameCtrl.dispose();
    _nBuyCtrl.dispose();
    _nSellCtrl.dispose();
    _nQtyCtrl.dispose();
    for (final c in _vQty.values) {
      c.dispose();
    }
    super.dispose();
  }

  String _money(int v) =>
      NumberFormat('#,###', 'ru').format(v).replaceAll(',', ' ');

  void _toast(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  // ===== Skan / qidiruv =====
  Future<void> _onScanSubmit(String value) async {
    final code = value.trim();
    if (code.isEmpty) return;
    final pp = context.read<ProductProvider>();
    final hit = pp.findByCode(code);
    if (hit != null) {
      _scanCtrl.clear();
      await _pick(hit.product);
      return;
    }
    if (RegExp(r'^\d{6,}$').hasMatch(code)) {
      // Topilmagan shtrix — yangi tovar (shtrix oldindan to'ldiriladi)
      _scanCtrl.clear();
      _startNew(barcode: code);
      return;
    }
    // Matn — bitta natija qolsa o'shani tanlaymiz
    final res = pp.searchProducts(code);
    if (res.length == 1) {
      _scanCtrl.clear();
      await _pick(res.first);
    } else {
      setState(() => _query = code);
    }
  }

  Future<void> _pick(Product p) async {
    for (final c in _vQty.values) {
      c.dispose();
    }
    _vQty.clear();
    setState(() {
      _newMode = false;
      _query = '';
      _selected = p;
      _barcode = p.barcode;
      _variants = const [];
      _qtyCtrl.text = '1';
      _buyCtrl.text = p.buyPrice > 0 ? '${p.buyPrice}' : '';
      _sellCtrl.text = p.price > 0 ? '${p.price}' : '';
    });
    if (p.hasVariants && p.id != null) {
      final pp = context.read<ProductProvider>();
      var list = pp.cachedVariants(p.id!);
      if (list.isEmpty) list = await pp.getVariants(p.id!);
      if (!mounted) return;
      setState(() {
        _variants = list;
        for (final v in list) {
          _vQty[v.id ?? v.skuId] = TextEditingController(text: '0');
        }
      });
    } else {
      _qtyFocus.requestFocus();
    }
  }

  void _startNew({String? barcode}) {
    setState(() {
      _selected = null;
      _variants = const [];
      _newMode = true;
      _pendingBarcode = barcode;
      _nNameCtrl.clear();
      _nBuyCtrl.clear();
      _nSellCtrl.clear();
      _nQtyCtrl.text = '1';
      final cats = context.read<CategoryProvider>().categoryNames;
      _nCategory = cats.isNotEmpty ? cats.first : null;
    });
    _nameFocus.requestFocus();
  }

  void _reset() {
    for (final c in _vQty.values) {
      c.dispose();
    }
    _vQty.clear();
    setState(() {
      _selected = null;
      _variants = const [];
      _newMode = false;
      _pendingBarcode = null;
      _query = '';
      _barcode = '';
      _busy = false;
    });
    _scanFocus.requestFocus();
  }

  int _vInc(ProductVariant v) =>
      int.tryParse(_vQty[v.id ?? v.skuId]?.text ?? '0') ?? 0;

  int get _incomingTotal => _hasVariants
      ? _variants.fold(0, (s, v) => s + _vInc(v))
      : (int.tryParse(_qtyCtrl.text) ?? 0);

  /// Tovarda umumiy (mahsulot darajasidagi) shtrix borligini ta'minlaydi.
  Future<String> _ensureBarcode(ProductProvider pp) async {
    if (_barcode.isNotEmpty) return _barcode;
    final code = BarcodeUtil.fromSeq(await pp.allocateSku());
    await pp.updateProduct(_selected!.copyWith(barcode: code));
    _barcode = code;
    return code;
  }

  Future<void> _printLabel({
    required String name,
    required String barcode,
    required int price,
    required int copies,
    String size = '-',
    String? color,
  }) async {
    final printer = context.read<PrinterProvider>();
    if (!printer.isConfigured || barcode.isEmpty || copies <= 0) return;
    await printer.printProductLabel(
      productName: name,
      barcode: barcode,
      price: '$price',
      size: size,
      color: color,
      article: BarcodeUtil.articleOf(barcode),
      copies: copies,
    );
  }

  // ===== Mavjud tovarni qabul qilish =====
  Future<void> _receive() async {
    final loc = _loc;
    if (_selected == null) return;
    final buy = int.tryParse(_buyCtrl.text) ?? 0;
    final sell = int.tryParse(_sellCtrl.text) ?? 0;
    final total = _incomingTotal;
    if (total <= 0 || buy <= 0) {
      _toast(loc.t('stockin.fillQtyPrice'), AppTheme.accentRed);
      return;
    }
    setState(() => _busy = true);
    final pp = context.read<ProductProvider>();
    final sp = context.read<StockInProvider>();
    try {
      if (_hasVariants) {
        final add = <String, int>{};
        for (final v in _variants) {
          final inc = _vInc(v);
          if (inc > 0 && v.id != null) add[v.id!] = inc;
        }
        await pp.receiveVariants(_selected!.id!, add,
            buyPrice: buy, sellPrice: sell > 0 ? sell : null);
        await sp.addStockIn(
          StockIn(
            productId: _selected!.id!,
            productName: _selected!.name,
            quantity: total,
            buyPrice: buy,
            createdAt: DateTime.now(),
          ),
          updateStock: false,
        );
      } else {
        await sp.addStockIn(
          StockIn(
            productId: _selected!.id!,
            productName: _selected!.name,
            quantity: total,
            buyPrice: buy,
            createdAt: DateTime.now(),
          ),
          sellPrice: sell > 0 ? sell : null,
        );
      }
      // Umumiy shtrix + birka chop etish (bitta umumiy shtrix)
      final code = await _ensureBarcode(pp);
      await _printLabel(
        name: _selected!.name,
        barcode: code,
        price: sell > 0 ? sell : _selected!.price,
        copies: _perPiece ? total : 1,
        size: _hasVariants ? '-' : _selected!.size,
        color: _hasVariants ? null : _selected!.color,
      );
      _session.insert(
          0, _RxEntry(_selected!.name, total, total * buy, DateTime.now()));
      await pp.loadProducts();
      if (!mounted) return;
      _reset();
      _toast(loc.t('prixod.received'), AppTheme.accentGreen);
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        _toast('${loc.t('common.error')}: $e', AppTheme.accentRed);
      }
    }
  }

  // ===== Yangi tovar (tezkor) =====
  Future<void> _saveNew() async {
    final loc = _loc;
    final name = _nNameCtrl.text.trim();
    final buy = int.tryParse(_nBuyCtrl.text) ?? 0;
    final sell = int.tryParse(_nSellCtrl.text) ?? 0;
    final qty = int.tryParse(_nQtyCtrl.text) ?? 0;
    if (name.isEmpty || qty <= 0 || buy <= 0 || sell <= 0) {
      _toast(loc.t('stockin.fillQtyPrice'), AppTheme.accentRed);
      return;
    }
    setState(() => _busy = true);
    final pp = context.read<ProductProvider>();
    final sp = context.read<StockInProvider>();
    try {
      final product = Product(
        name: name,
        category: _nCategory ?? '',
        size: '-',
        price: sell,
        buyPrice: buy,
        quantity: qty,
        barcode: _pendingBarcode ?? '',
        hasVariants: false,
      );
      final id = await pp.addProduct(product);
      if (id == null) throw Exception('addProduct');
      await pp.loadProducts();
      final created = pp.products.firstWhere((p) => p.id == id,
          orElse: () => product.copyWith(id: id));
      // Tarix (tovar soni addProduct'da o'rnatilgan — qayta qo'shmaymiz)
      await sp.addStockIn(
        StockIn(
          productId: id,
          productName: name,
          quantity: qty,
          buyPrice: buy,
          createdAt: DateTime.now(),
        ),
        updateStock: false,
      );
      await _printLabel(
        name: name,
        barcode: created.barcode,
        price: sell,
        copies: _perPiece ? qty : 1,
      );
      _session.insert(0, _RxEntry(name, qty, qty * buy, DateTime.now()));
      if (!mounted) return;
      _reset();
      _toast(loc.t('prixod.received'), AppTheme.accentGreen);
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        _toast('${loc.t('common.error')}: $e', AppTheme.accentRed);
      }
    }
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
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                const Icon(Icons.inventory_2_rounded,
                    color: AppTheme.accentOrange),
                const SizedBox(width: 12),
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
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // CHAP: skan + ish paneli
                Expanded(
                  flex: 3,
                  child: GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _scanCtrl,
                          focusNode: _scanFocus,
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText: loc.t('prixod.scanHint'),
                            prefixIcon: const Icon(Icons.qr_code_scanner),
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.5),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none),
                          ),
                          onChanged: (v) => setState(() => _query = v),
                          onSubmitted: _onScanSubmit,
                        ),
                        const SizedBox(height: 12),
                        Expanded(child: _leftBody(loc)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // O'NG: seans logi
                Expanded(
                  flex: 2,
                  child: GlassCard(child: _sessionPanel(loc)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _leftBody(LocaleProvider loc) {
    if (_newMode) return _newForm(loc);
    if (_selected != null) return _receivePanel(loc);
    return _searchList(loc);
  }

  // ===== Qidiruv ro'yxati =====
  Widget _searchList(LocaleProvider loc) {
    return Consumer<ProductProvider>(
      builder: (context, pp, _) {
        final list = pp.searchProducts(_query);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OutlinedButton.icon(
              onPressed: () => _startNew(),
              icon: const Icon(Icons.add),
              label: Text(loc.t('prixod.newProductBtn')),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: list.isEmpty
                  ? Center(
                      child: Text(loc.t('common.notFound'),
                          style:
                              const TextStyle(color: AppTheme.textSecondary)))
                  : ListView.separated(
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final p = list[i];
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.checkroom,
                              color: AppTheme.textSecondary),
                          title: Text(p.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary)),
                          subtitle: Text(
                            '${_money(p.price)} ${loc.t('common.sum')}'
                            '${p.hasVariants ? ' • ${loc.t('product.variants')}' : ''}'
                            ' • ${loc.t('product.stock')}: ${p.quantity}',
                            style: const TextStyle(
                                color: AppTheme.textSecondary, fontSize: 12),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios,
                              size: 14, color: AppTheme.textSecondary),
                          onTap: () => _pick(p),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  // ===== Qabul paneli (mavjud tovar) =====
  Widget _receivePanel(LocaleProvider loc) {
    final p = _selected!;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(p.name,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary)),
              ),
              TextButton.icon(
                onPressed: _reset,
                icon: const Icon(Icons.close, size: 18),
                label: Text(loc.t('common.cancel')),
              ),
            ],
          ),
          if (_barcode.isNotEmpty)
            Text(
              () {
                final art = BarcodeUtil.articleOf(_barcode);
                return art.isEmpty ? _barcode : 'Art: $art  •  $_barcode';
              }(),
              style:
                  const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _buyCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                      labelText: loc.t('product.buyPrice'),
                      suffixText: loc.t('common.sum')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _sellCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                      labelText: loc.t('product.sellPrice'),
                      suffixText: loc.t('common.sum')),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_hasVariants) _variantList(loc) else _simpleQty(loc),
          const SizedBox(height: 12),
          _perPieceToggle(loc),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _busy ? null : _receive,
              icon: _busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.check),
              label: Text(loc.t('prixod.receiveAndPrint')),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentGreen,
                  padding: const EdgeInsets.all(16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _simpleQty(LocaleProvider loc) {
    return TextField(
      controller: _qtyCtrl,
      focusNode: _qtyFocus,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (_) => setState(() {}),
      onSubmitted: (_) => _receive(),
      decoration: InputDecoration(
        labelText: loc.t('stockin.qtyIncoming'),
        prefixIcon: const Icon(Icons.numbers),
      ),
    );
  }

  Widget _variantList(LocaleProvider loc) {
    if (_variants.isEmpty) {
      return Text(loc.t('common.loading'),
          style: const TextStyle(color: AppTheme.textSecondary));
    }
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
                    fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            const Spacer(),
            Text('${loc.t('common.total')}: $_incomingTotal',
                style: const TextStyle(
                    color: AppTheme.accentOrange, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        ...sorted.map((v) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text('${v.color} • ${v.size}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary)),
                  ),
                  Text('${loc.t('product.stock')}: ${v.quantity}',
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12)),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 70,
                    child: TextField(
                      controller: _vQty[v.id ?? v.skuId],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 6, vertical: 8)),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _perPieceToggle(LocaleProvider loc) {
    return Row(
      children: [
        Checkbox(
          value: _perPiece,
          activeColor: AppTheme.accentOrange,
          onChanged: (v) => setState(() => _perPiece = v ?? true),
        ),
        Expanded(
          child: Text(loc.t('stockin.perPieceLabels'),
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 13)),
        ),
      ],
    );
  }

  // ===== Yangi tovar formasi (tezkor minimal) =====
  Widget _newForm(LocaleProvider loc) {
    final cats = context.watch<CategoryProvider>().categoryNames;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(loc.t('prixod.newProductBtn'),
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary)),
              ),
              TextButton.icon(
                onPressed: _reset,
                icon: const Icon(Icons.close, size: 18),
                label: Text(loc.t('common.cancel')),
              ),
            ],
          ),
          if (_pendingBarcode != null)
            Text('${loc.t('product.barcode')}: $_pendingBarcode',
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          TextField(
            controller: _nNameCtrl,
            focusNode: _nameFocus,
            decoration: InputDecoration(
                labelText: loc.t('common.name'),
                prefixIcon: const Icon(Icons.checkroom)),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _nCategory,
            isExpanded: true,
            decoration: InputDecoration(
                labelText: loc.t('common.category'),
                prefixIcon: const Icon(Icons.category_outlined)),
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
                  controller: _nBuyCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                      labelText: loc.t('product.buyPrice'),
                      suffixText: loc.t('common.sum')),
                ),
              ),
              const SizedBox(width: 12),
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
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nQtyCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
                labelText: loc.t('stockin.qtyIncoming'),
                prefixIcon: const Icon(Icons.numbers)),
          ),
          const SizedBox(height: 12),
          _perPieceToggle(loc),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _busy ? null : _saveNew,
              icon: _busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.check),
              label: Text(loc.t('prixod.receiveAndPrint')),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentGreen,
                  padding: const EdgeInsets.all(16)),
            ),
          ),
        ],
      ),
    );
  }

  // ===== O'ng panel: seans logi =====
  Widget _sessionPanel(LocaleProvider loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.receipt_long, color: AppTheme.accentOrange),
            const SizedBox(width: 8),
            Text(loc.t('prixod.session'),
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppTheme.textPrimary)),
            const Spacer(),
            Text('${_session.length}',
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
          ],
        ),
        const Divider(),
        Expanded(
          child: _session.isEmpty
              ? Center(
                  child: Text(loc.t('common.empty'),
                      style: const TextStyle(color: AppTheme.textSecondary)))
              : ListView.separated(
                  itemCount: _session.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final e = _session[i];
                    return ListTile(
                      dense: true,
                      title: Text(e.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary)),
                      subtitle: Text(
                          '${e.qty} ${loc.t('common.pcs')} • ${DateFormat('HH:mm').format(e.at)}',
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 12)),
                      trailing: Text('${_money(e.sum)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary)),
                    );
                  },
                ),
        ),
        const Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(loc.t('prixod.sessionTotal'),
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            Text('${_money(_sessionTotal)} ${loc.t('common.sum')}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: AppTheme.accentGreen)),
          ],
        ),
      ],
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
