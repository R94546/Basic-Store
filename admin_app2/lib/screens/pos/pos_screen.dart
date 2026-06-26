import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/locale_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/client.dart';
import '../../models/debt.dart';
import '../../models/product.dart';
import '../../models/product_variant.dart';
import '../../models/sale.dart';
import '../../providers/category_provider.dart';
import '../../providers/client_provider.dart';
import '../../providers/debt_provider.dart';
import '../../providers/printer_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/sale_provider.dart';
import '../../providers/session_provider.dart';
import '../../services/printer_service.dart';
import '../../utils/barcode_util.dart';

/// Kassa (POS) — parallel cheklar, variant tanlash, aralash to'lov,
/// smena nazorati va chek chop etish bilan.
class POSScreen extends StatefulWidget {
  const POSScreen({super.key});

  @override
  State<POSScreen> createState() => _POSScreenState();
}

class _POSScreenState extends State<POSScreen> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  // ===== Shtrix-skaner (USB/Bluetooth — klaviatura emulyatsiyasi) =====
  // Skaner kodni tez "yozadi" va Enter bilan tugatadi. Qidiruv maydoni
  // fokusda bo'lmasa ham kodni ushlash uchun global klaviatura tinglovchisi.
  final StringBuffer _scanBuffer = StringBuffer();
  DateTime? _lastScanKeyAt;

  final List<_Chek> _cheks = [_Chek(label: 1)];
  int _activeIndex = 0;
  int _chekLabelCounter = 1;
  String _selectedCategory = 'Barchasi';

  _Chek get _active => _cheks[_activeIndex];
  List<CartItem> get _cart => _active.items;

  int _discounted(int base, int? discount) {
    if (discount != null && discount > 0) {
      return (base * (100 - discount) / 100).round();
    }
    return base;
  }

  int get _totalPrice =>
      _cart.fold(0, (s, i) => s + _discounted(i.unitBase, i.product.discount) * i.quantity);
  int get _originalPrice => _cart.fold(0, (s, i) => s + i.unitBase * i.quantity);
  int get _discountAmount => _originalPrice - _totalPrice;
  int get _cartCount => _cart.fold(0, (s, i) => s + i.quantity);

  @override
  void initState() {
    super.initState();
    // Global skaner ushlovchisi — faqat POS ekrani ochiq turganda faol
    // (boshqa yo'lga o'tilganda dispose chaqiriladi va olib tashlanadi).
    HardwareKeyboard.instance.addHandler(_onGlobalKey);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts();
      context.read<CategoryProvider>().loadCategories();
      context.read<SaleProvider>().loadSales();
      context.read<SessionProvider>().loadCurrentSession();
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onGlobalKey);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  /// Shtrix-skaner klaviatura ko'rinishida kod yuboradi. Qidiruv maydoni
  /// fokusda bo'lsa — TextField o'zi ishlaydi (onSubmitted). Aks holda
  /// belgilarni buferga yig'ib, Enter kelganda mahsulotni qidiramiz.
  bool _onGlobalKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    // Qidiruv maydoni yoki boshqa matn maydoni fokusda bo'lsa — aralashmaymiz
    if (_searchFocusNode.hasFocus) return false;
    final primary = FocusManager.instance.primaryFocus;
    if (primary?.context?.widget is EditableText) return false;

    final now = DateTime.now();
    // Belgilar orasidagi tanaffus katta bo'lsa (odam yozyapti) — buferni tozalaymiz.
    if (_lastScanKeyAt != null &&
        now.difference(_lastScanKeyAt!).inMilliseconds > 250) {
      _scanBuffer.clear();
    }
    _lastScanKeyAt = now;

    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      final code = _scanBuffer.toString().trim();
      _scanBuffer.clear();
      if (code.length >= 3) {
        _onSearchSubmit(code);
        return true;
      }
      return false;
    }

    final ch = event.character;
    if (ch != null && ch.length == 1 && ch.codeUnitAt(0) >= 0x20) {
      _scanBuffer.write(ch);
    }
    return false;
  }

  LocaleProvider get _loc => context.read<LocaleProvider>();

  // ===== Chek tablari =====
  void _newChek() => setState(() {
        _chekLabelCounter++;
        _cheks.add(_Chek(label: _chekLabelCounter));
        _activeIndex = _cheks.length - 1;
      });

  void _switchChek(int i) => setState(() => _activeIndex = i);

  void _closeChek(int i) {
    if (_cheks.length == 1) {
      setState(() => _cheks[0].items.clear());
      return;
    }
    setState(() {
      _cheks.removeAt(i);
      if (_activeIndex >= _cheks.length) _activeIndex = _cheks.length - 1;
    });
  }

  // ===== Savatga qo'shish =====
  Future<void> _onProductTap(Product product) async {
    if (product.hasVariants) {
      final pp = context.read<ProductProvider>();
      var variants = pp.cachedVariants(product.id!);
      if (variants.isEmpty) variants = await pp.getVariants(product.id!);
      if (!mounted) return;
      if (variants.isNotEmpty) {
        final chosen = await showDialog<ProductVariant>(
          context: context,
          builder: (_) => _VariantPickerDialog(product: product, variants: variants),
        );
        if (chosen != null) _addToCart(product, variant: chosen);
        return;
      }
    }
    _addToCart(product);
  }

  void _addToCart(Product product, {ProductVariant? variant}) {
    final key = variant?.id ?? variant?.skuId ?? product.id;
    final index = _cart.indexWhere((i) => i.key == key);
    final inCart = index >= 0 ? _cart[index].quantity : 0;
    final stock = variant?.quantity ?? product.quantity;

    if (inCart + 1 > stock) {
      _toast('${_loc.t('pos.outOfStockMsg')} ($stock)', AppTheme.accentRed);
      return;
    }
    setState(() {
      if (index >= 0) {
        _cart[index].quantity++;
      } else {
        _cart.add(CartItem(product: product, variant: variant, quantity: 1));
      }
    });
  }

  void _decrement(int i) => setState(() {
        if (_cart[i].quantity > 1) {
          _cart[i].quantity--;
        } else {
          _cart.removeAt(i);
        }
      });

  void _increment(int i) {
    final item = _cart[i];
    if (item.quantity + 1 > item.availableStock) {
      _toast('${_loc.t('pos.outOfStockMsg')} (${item.availableStock})', AppTheme.accentRed);
      return;
    }
    setState(() => item.quantity++);
  }

  Future<void> _onSearchSubmit(String value) async {
    final code = value.trim();
    if (code.isEmpty) return;
    final pp = context.read<ProductProvider>();
    // Shtrix yoki artikul (qisqa raqam) bo'yicha — darhol, xotiradan.
    final hit = pp.findByCode(code);
    if (hit != null) {
      if (hit.variant != null) {
        _addToCart(hit.product, variant: hit.variant);
      } else if (hit.product.hasVariants) {
        await _onProductTap(hit.product);
      } else {
        _addToCart(hit.product);
      }
    } else if (RegExp(r'^\d{6,}$').hasMatch(code)) {
      // Shtrixsimon kod topilmadi — mahsulotga biriktirishni taklif qilamiz
      // (ishlab chiqaruvchi shtrixini SKU'ga bog'lash, printersiz).
      _searchController.clear();
      setState(() {});
      await _showBindBarcodeDialog(code);
      _searchFocusNode.requestFocus();
      return;
    } else if (code.length >= 8) {
      // Boshqa uzun matn topilmasa ogohlantiramiz; qisqa matn yozsa
      // ro'yxat filtri o'zi ishlaydi.
      _toast(_loc.t('common.notFound'), AppTheme.accentRed);
    }
    _searchController.clear();
    setState(() {});
    _searchFocusNode.requestFocus();
  }

  /// Topilmagan shtrixni mavjud mahsulotga biriktirish dialogi.
  Future<void> _showBindBarcodeDialog(String code) async {
    final result = await showDialog<({Product product, ProductVariant? variant})>(
      context: context,
      builder: (_) => _BindBarcodeDialog(barcode: code),
    );
    if (result == null || !mounted) return;
    _addToCart(result.product, variant: result.variant);
    _toast(_loc.t('bind.done'), AppTheme.accentGreen);
  }

  void _toast(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  // ===== To'lov =====
  Future<void> _checkout() async {
    if (_cart.isEmpty) return;
    final loc = _loc;

    // Smena ochiq bo'lishi shart
    if (!context.read<SessionProvider>().isOpen) {
      _toast(loc.t('pos.noSession'), AppTheme.accentRed);
      return;
    }

    final result = await showDialog<_PaymentResult>(
      context: context,
      builder: (_) => _PaymentDialog(total: _totalPrice),
    );
    if (result == null || !mounted) return;

    final saleProvider = context.read<SaleProvider>();
    final number = saleProvider.nextSaleNumber;

    final sale = Sale(
      number: number,
      createdAt: DateTime.now(),
      totalAmount: _totalPrice,
      originalAmount: _originalPrice,
      discountAmount: _discountAmount,
      paymentMethod: result.method,
      amountPaid: result.amountPaid,
      changeAmount: result.change,
      payments: result.payments,
      customerName: result.customerName,
      note: result.note,
      items: _cart.map((i) => SaleItem(
            productId: i.product.id ?? '',
            variantId: i.variant?.id,
            productName: i.displayName,
            quantity: i.quantity,
            unitPrice: _discounted(i.unitBase, i.product.discount),
            originalPrice: i.unitBase,
            discount: i.product.discount,
            size: i.size,
            color: i.color,
          )).toList(),
    );

    final res = await saleProvider.addSale(sale);
    if (!mounted) return;
    if (!res.ok) {
      _toast(res.error ?? loc.t('common.error'), AppTheme.accentRed);
      return;
    }

    // Qarz (nasiya) bo'lsa — mijoz + qarz yozuvini yaratamiz
    final debtAmount = result.payments['debt'] ?? 0;
    if (debtAmount > 0 && result.customerName != null) {
      final client = await context
          .read<ClientProvider>()
          .getOrCreateByName(result.customerName!);
      if (client?.id != null && mounted) {
        await context.read<DebtProvider>().addDebt(Debt(
              clientId: client!.id!,
              clientName: client.name,
              saleId: res.id,
              saleNumber: number,
              amount: debtAmount,
              createdAt: DateTime.now(),
            ));
      }
      if (!mounted) return;
    }

    await context.read<ProductProvider>().loadProducts();
    await _printReceipt(number, sale);
    if (!mounted) return;

    setState(() => _cart.clear());
    final changeMsg = sale.changeAmount > 0
        ? ' • ${loc.t('pos.change')}: ${_money(sale.changeAmount)}'
        : '';
    _toast('${loc.t('pos.check')} #$number ${loc.t('pos.paid')} ✓$changeMsg',
        AppTheme.accentGreen);
  }

  Future<void> _printReceipt(int number, Sale sale) async {
    final printer = context.read<PrinterProvider>();
    if (!printer.isConfigured || !printer.autoPrintReceipt) return;
    try {
      await printer.printReceipt(
        shopName: 'Ayollar Kiyim',
        orderNumber: '$number',
        items: sale.items
            .map((i) => ReceiptItem(
                name: i.productName,
                quantity: i.quantity,
                price: i.unitPrice,
                size: i.size,
                color: i.color))
            .toList(),
        subtotal: sale.originalAmount,
        discount: sale.discountAmount,
        total: sale.totalAmount,
        paymentMethod: _loc.payLabel(sale.paymentMethod),
      );
    } catch (_) {}
  }

  // ===== UI =====
  @override
  Widget build(BuildContext context) {
    context.watch<LocaleProvider>(); // til o'zgarsa qayta chizish
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Expanded(flex: 2, child: _buildProductsPanel()),
          const SizedBox(width: 16),
          SizedBox(width: 380, child: _buildCartPanel()),
        ],
      ),
    );
  }

  Widget _buildProductsPanel() {
    final loc = _loc;
    return Column(
      children: [
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Text(loc.t('pos.title'),
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary)),
              const SizedBox(width: 24),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  decoration: InputDecoration(
                    hintText: loc.t('pos.searchHint'),
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isEmpty
                        ? const Icon(Icons.qr_code_scanner)
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () =>
                                setState(() => _searchController.clear())),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.3),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none),
                  ),
                  onChanged: (_) => setState(() {}),
                  onSubmitted: _onSearchSubmit,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Consumer<CategoryProvider>(
          builder: (context, catProvider, _) {
            final cats = [loc.t('common.all'), ...catProvider.categoryNames];
            return GlassCard(
              padding: const EdgeInsets.all(8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: cats.map((c) {
                    final isAll = c == loc.t('common.all');
                    final selected = isAll
                        ? _selectedCategory == 'Barchasi'
                        : _selectedCategory == c;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(c),
                        selected: selected,
                        onSelected: (_) => setState(
                            () => _selectedCategory = isAll ? 'Barchasi' : c),
                        selectedColor: AppTheme.accentOrange.withOpacity(0.2),
                        checkmarkColor: AppTheme.accentOrange,
                        labelStyle: TextStyle(
                          color: selected
                              ? AppTheme.accentOrange
                              : AppTheme.textSecondary,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Consumer<ProductProvider>(
            builder: (context, provider, _) {
              if (provider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              var products = _selectedCategory == 'Barchasi'
                  ? provider.products
                  : provider.products
                      .where((p) =>
                          p.category.toLowerCase() ==
                          _selectedCategory.toLowerCase())
                      .toList();
              final q = _searchController.text.toLowerCase();
              if (q.isNotEmpty) {
                products = products
                    .where((p) =>
                        p.name.toLowerCase().contains(q) ||
                        p.barcode.contains(q) ||
                        BarcodeUtil.articleOf(p.barcode).contains(q))
                    .toList();
              }
              if (products.isEmpty) {
                return _emptyState(Icons.search_off, loc.t('common.notFound'));
              }
              return GridView.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 180,
                  childAspectRatio: 0.78,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  final inCart = _cart
                      .where((i) => i.product.id == product.id)
                      .fold<int>(0, (s, i) => s + i.quantity);
                  return _POSProductCard(
                    product: product,
                    inCartQty: inCart,
                    discountedPrice:
                        _discounted(product.price, product.discount),
                    onTap: () => _onProductTap(product),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCartPanel() {
    final loc = _loc;
    return GlassCard(
      child: Column(
        children: [
          _buildChekTabs(),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Expanded(
            child: _cart.isEmpty
                ? _emptyState(
                    Icons.shopping_cart_outlined, loc.t('common.empty'))
                : ListView.builder(
                    itemCount: _cart.length,
                    itemBuilder: (context, index) {
                      final item = _cart[index];
                      return _CartItemTile(
                        item: item,
                        lineTotal:
                            _discounted(item.unitBase, item.product.discount) *
                                item.quantity,
                        onRemove: () => _decrement(index),
                        onAdd: () => _increment(index),
                        onDelete: () =>
                            setState(() => _cart.removeAt(index)),
                      );
                    },
                  ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.35),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                if (_discountAmount > 0) ...[
                  _row(loc.t('product.discount'),
                      '-${_money(_discountAmount)}', AppTheme.accentRed),
                  const SizedBox(height: 8),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${loc.t('common.total')}:',
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary)),
                    Text('${_money(_totalPrice)} ${loc.t('common.sum')}',
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.accentOrange)),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _cart.isEmpty ? null : _checkout,
                    icon: const Icon(Icons.payment),
                    label: Text('${loc.t('pos.pay')}  •  $_cartCount'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      textStyle: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChekTabs() {
    final loc = _loc;
    return SizedBox(
      height: 40,
      child: Row(
        children: [
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _cheks.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final chek = _cheks[index];
                final isActive = index == _activeIndex;
                final count = chek.items.fold<int>(0, (s, i) => s + i.quantity);
                return InkWell(
                  onTap: () => _switchChek(index),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppTheme.accentOrange.withOpacity(0.25)
                          : Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: isActive
                              ? AppTheme.accentOrange
                              : Colors.transparent,
                          width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.receipt_outlined,
                            size: 16,
                            color: isActive
                                ? AppTheme.accentOrange
                                : AppTheme.textSecondary),
                        const SizedBox(width: 6),
                        Text('${loc.t('pos.check')} ${chek.label}',
                            style: TextStyle(
                                fontWeight: isActive
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isActive
                                    ? AppTheme.accentOrange
                                    : AppTheme.textPrimary)),
                        if (count > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                                color: AppTheme.accentOrange,
                                borderRadius: BorderRadius.circular(8)),
                            child: Text('$count',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () => _closeChek(index),
                          child: Icon(Icons.close,
                              size: 14,
                              color: AppTheme.textSecondary.withOpacity(0.7)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: _newChek,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: AppTheme.accentGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.add, color: AppTheme.accentGreen),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: color)),
        Text(value,
            style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _emptyState(IconData icon, String text) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: AppTheme.textSecondary.withOpacity(0.3)),
          const SizedBox(height: 12),
          Text(text, style: const TextStyle(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}

// ===== Variant tanlash dialogi =====
/// Skanerlanган, ammo bazada topilmagan shtrixni mavjud mahsulot/variantга
/// biriktirish dialogi. Tovarda ishlab chiqaruvchi shtrixi bo'lsa — uni
/// SKU'ga bog'laymiz, keyin POS'da to'g'ridan-to'g'ri skanerlanadi (printersiz).
class _BindBarcodeDialog extends StatefulWidget {
  final String barcode;
  const _BindBarcodeDialog({required this.barcode});

  @override
  State<_BindBarcodeDialog> createState() => _BindBarcodeDialogState();
}

class _BindBarcodeDialogState extends State<_BindBarcodeDialog> {
  final _searchCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _pick(Product product) async {
    final pp = context.read<ProductProvider>();
    final loc = context.read<LocaleProvider>();

    ProductVariant? variant;
    if (product.hasVariants) {
      var variants = pp.cachedVariants(product.id!);
      if (variants.isEmpty) variants = await pp.getVariants(product.id!);
      if (!mounted) return;
      variant = await showDialog<ProductVariant>(
        context: context,
        builder: (_) => _VariantPickerDialog(product: product, variants: variants),
      );
      if (variant == null) return; // bekor qilindi
    }

    setState(() => _saving = true);
    try {
      if (variant != null) {
        await pp.assignBarcodeToVariant(product.id!, variant.id!, widget.barcode);
      } else {
        await pp.assignBarcodeToProduct(product.id!, widget.barcode);
      }
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
    Navigator.pop(context, (product: product, variant: variant));
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocaleProvider>();
    final pp = context.watch<ProductProvider>();
    final q = _searchCtrl.text.toLowerCase();
    var products = pp.products;
    if (q.isNotEmpty) {
      products = products
          .where((p) =>
              p.name.toLowerCase().contains(q) ||
              p.barcode.contains(q) ||
              BarcodeUtil.articleOf(p.barcode).contains(q))
          .toList();
    }

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
              const SizedBox(height: 8),
              Text(
                loc.t('bind.hint'),
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: loc.t('pos.searchHint'),
                  prefixIcon: const Icon(Icons.search),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 320,
                child: _saving
                    ? const Center(child: CircularProgressIndicator())
                    : products.isEmpty
                        ? Center(
                            child: Text(loc.t('common.notFound'),
                                style: const TextStyle(
                                    color: AppTheme.textSecondary)))
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
          ),
        ),
      ),
    );
  }
}

class _VariantPickerDialog extends StatelessWidget {
  final Product product;
  final List<ProductVariant> variants;
  const _VariantPickerDialog({required this.product, required this.variants});

  // O'lcham tartibi
  static const _sizeOrder = [
    'XS', 'S', 'M', 'L', 'XL', 'XXL', '2XL', '3XL', '4XL', '5XL'
  ];

  int _sizeRank(String size) {
    final i = _sizeOrder.indexOf(size.toUpperCase().trim());
    return i == -1 ? 999 : i;
  }

  /// Rang bo'yicha, keyin o'lcham bo'yicha tartiblangan variantlar
  List<ProductVariant> get _sorted {
    final list = [...variants];
    list.sort((a, b) {
      final c = a.color.toLowerCase().compareTo(b.color.toLowerCase());
      if (c != 0) return c;
      return _sizeRank(a.size).compareTo(_sizeRank(b.size));
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.read<LocaleProvider>();
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
              Text('${product.name} — ${loc.t('pos.chooseVariant')}',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _sorted.map((v) {
                  final out = v.quantity <= 0;
                  return InkWell(
                    onTap: out ? null : () => Navigator.pop(context, v),
                    borderRadius: BorderRadius.circular(12),
                    child: Opacity(
                      opacity: out ? 0.4 : 1,
                      child: Container(
                        width: 130,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppTheme.accentOrange.withOpacity(0.4)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _colorDot(v.color),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(v.color,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textPrimary),
                                      overflow: TextOverflow.ellipsis),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('${loc.t('product.size')}: ${v.size}',
                                style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 13)),
                            Text('${loc.t('product.stock')}: ${v.quantity}',
                                style: TextStyle(
                                    color: out
                                        ? AppTheme.accentRed
                                        : AppTheme.accentGreen,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(loc.t('common.cancel')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _colorDot(String color) {
    final map = {
      'qizil': Colors.red,
      'red': Colors.red,
      'ko\'k': Colors.blue,
      'blue': Colors.blue,
      'yashil': Colors.green,
      'green': Colors.green,
      'qora': Colors.black,
      'black': Colors.black,
      'oq': Colors.white,
      'white': Colors.white,
      'sariq': Colors.yellow,
      'yellow': Colors.yellow,
      'pushti': Colors.pink,
      'pink': Colors.pink,
    };
    final c = map[color.toLowerCase()] ?? AppTheme.accentOrange;
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: c,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black26),
      ),
    );
  }
}

// ===== Mahsulot kartasi =====
class _POSProductCard extends StatelessWidget {
  final Product product;
  final int inCartQty;
  final int discountedPrice;
  final VoidCallback onTap;

  const _POSProductCard({
    required this.product,
    required this.inCartQty,
    required this.discountedPrice,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final outOfStock = product.quantity <= 0;
    final lowStock = product.quantity > 0 && product.quantity <= 3;
    final hasDiscount = product.discount != null && product.discount! > 0;

    return Opacity(
      opacity: outOfStock ? 0.5 : 1,
      child: GlassCard(
        padding: const EdgeInsets.all(8),
        opacity: 0.2,
        child: InkWell(
          onTap: outOfStock ? null : onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: product.images.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: product.images.first,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => const Icon(
                                  Icons.checkroom,
                                  size: 36,
                                  color: AppTheme.textSecondary),
                            )
                          : Center(
                              child: Icon(Icons.checkroom,
                                  size: 36,
                                  color: AppTheme.textSecondary
                                      .withOpacity(0.4))),
                    ),
                    if (product.hasVariants)
                      Positioned(
                        bottom: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.accentOrange.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.palette,
                              size: 12, color: Colors.white),
                        ),
                      ),
                    if (inCartQty > 0)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                              color: AppTheme.accentOrange,
                              shape: BoxShape.circle),
                          child: Text('$inCartQty',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    if (hasDiscount)
                      Positioned(
                        top: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                              color: AppTheme.accentRed,
                              borderRadius: BorderRadius.circular(6)),
                          child: Text('-${product.discount}%',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(product.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                      color: AppTheme.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (hasDiscount)
                          Text(_money(product.price),
                              style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 10,
                                  decoration: TextDecoration.lineThrough)),
                        Text('${_money(discountedPrice)}',
                            style: const TextStyle(
                                color: AppTheme.accentOrange,
                                fontWeight: FontWeight.bold,
                                fontSize: 12)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: outOfStock
                          ? AppTheme.accentRed.withOpacity(0.15)
                          : lowStock
                              ? AppTheme.accentOrange.withOpacity(0.15)
                              : AppTheme.accentGreen.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('${product.quantity}',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: outOfStock
                                ? AppTheme.accentRed
                                : lowStock
                                    ? AppTheme.accentOrange
                                    : AppTheme.accentGreen)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===== Savat elementi =====
class _CartItemTile extends StatelessWidget {
  final CartItem item;
  final int lineTotal;
  final VoidCallback onRemove;
  final VoidCallback onAdd;
  final VoidCallback onDelete;

  const _CartItemTile({
    required this.item,
    required this.lineTotal,
    required this.onRemove,
    required this.onAdd,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final sub = item.variant != null
        ? '${item.variant!.color} • ${item.variant!.size}'
        : null;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.product.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                if (sub != null)
                  Text(sub,
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 11)),
                const SizedBox(height: 2),
                Text('${_money(lineTotal)}',
                    style: const TextStyle(
                        color: AppTheme.accentOrange,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Row(
            children: [
              _qtyBtn(Icons.remove, onRemove),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8)),
                child: Text('${item.quantity}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              _qtyBtn(Icons.add, onAdd, color: AppTheme.accentOrange),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, size: 18),
                color: AppTheme.accentRed,
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.only(left: 4),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap, {Color? color}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 20, color: color ?? AppTheme.textSecondary),
      ),
    );
  }
}

// ===== Optimallashtirilgan to'lov oynasi (aralash to'lov) =====
class _PaymentDialog extends StatefulWidget {
  final int total;
  const _PaymentDialog({required this.total});

  @override
  State<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {
  // Har bir usul uchun kiritilgan summa
  final Map<String, int> _amounts = {'cash': 0, 'card': 0, 'debt': 0};
  String _active = 'cash';
  final _customerController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _customerController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  int get _cash => _amounts['cash']!;
  int get _card => _amounts['card']!;
  int get _debt => _amounts['debt']!;
  int get _covered => _cash + _card + _debt;
  int get _remaining =>
      _covered < widget.total ? widget.total - _covered : 0;
  // Naqd/karta ortig'i qaytim
  int get _change {
    final toCoverByMoney = widget.total - _debt;
    final money = _cash + _card;
    return money > toCoverByMoney ? money - toCoverByMoney : 0;
  }

  bool get _canConfirm {
    if (_covered < widget.total) return false;
    if (_debt > 0 && _customerController.text.trim().isEmpty) return false;
    return true;
  }

  void _key(String k) {
    setState(() {
      var cur = _amounts[_active]!.toString();
      if (cur == '0') cur = '';
      if (k == '⌫') {
        cur = cur.isEmpty ? '' : cur.substring(0, cur.length - 1);
      } else if (k == '000') {
        if (cur.isNotEmpty && cur.length <= 9) cur += '000';
      } else {
        if (cur.length < 12) cur += k;
      }
      _amounts[_active] = cur.isEmpty ? 0 : int.parse(cur);
    });
  }

  void _exact() => setState(() {
        final others = _covered - _amounts[_active]!;
        final need = widget.total - others;
        _amounts[_active] = need > 0 ? need : 0;
      });

  void _addSum(int v) =>
      setState(() => _amounts[_active] = _amounts[_active]! + v);

  void _confirm() {
    final payments = <String, int>{};
    _amounts.forEach((k, v) {
      if (v > 0) payments[k] = v;
    });
    final method = payments.length > 1
        ? 'mixed'
        : (payments.keys.isNotEmpty ? payments.keys.first : 'cash');
    Navigator.pop(
      context,
      _PaymentResult(
        method: method,
        amountPaid: _cash + _card,
        change: _change,
        payments: payments,
        customerName: _debt > 0 ? _customerController.text.trim() : null,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.read<LocaleProvider>();
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: GlassCard(
        blur: 25,
        opacity: 0.95,
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          width: 760,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(loc.t('pos.payment'),
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary)),
                  const Spacer(),
                  IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 8),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Chap — usullar + summa
                    Expanded(child: _leftPanel(loc)),
                    const SizedBox(width: 16),
                    // O'ng — klaviatura
                    SizedBox(width: 320, child: _keypad(loc)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _leftPanel(LocaleProvider loc) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Jami
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.accentOrange.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Text(loc.t('pos.payable'),
                  style: const TextStyle(color: AppTheme.textSecondary)),
              Text('${_money(widget.total)} ${loc.t('common.sum')}',
                  style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accentOrange)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _methodRow('cash', loc.t('pos.cash'), Icons.payments),
        const SizedBox(height: 8),
        _methodRow('card', loc.t('pos.card'), Icons.credit_card),
        const SizedBox(height: 8),
        _methodRow('debt', loc.t('pos.debt'), Icons.event_note),
        const SizedBox(height: 10),
        if (_debt > 0)
          TextField(
            controller: _customerController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: '${loc.t('pos.customer')} *',
              prefixIcon: const Icon(Icons.person_outline),
              isDense: true,
            ),
          ),
        if (_debt > 0) const SizedBox(height: 8),
        // Qoldi / Qaytim
        Row(
          children: [
            Expanded(
              child: _statBox(
                _remaining > 0 ? loc.t('pos.remaining') : loc.t('pos.change'),
                _money(_remaining > 0 ? _remaining : _change),
                _remaining > 0 ? AppTheme.accentRed : AppTheme.accentGreen,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _statBox(loc.t('pos.received'), _money(_cash + _card),
                  AppTheme.textPrimary),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _canConfirm ? _confirm : null,
            icon: const Icon(Icons.check_circle),
            label: Text(loc.t('common.confirm')),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentGreen,
              padding: const EdgeInsets.all(14),
              textStyle:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _methodRow(String value, String label, IconData icon) {
    final selected = _active == value;
    final amount = _amounts[value]!;
    return InkWell(
      onTap: () => setState(() => _active = value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.accentOrange.withOpacity(0.18)
              : Colors.white.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? AppTheme.accentOrange : Colors.transparent,
              width: 1.5),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: selected
                    ? AppTheme.accentOrange
                    : AppTheme.textSecondary),
            const SizedBox(width: 10),
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? AppTheme.accentOrange
                        : AppTheme.textPrimary)),
            const Spacer(),
            Text(_money(amount),
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: amount > 0
                        ? AppTheme.textPrimary
                        : AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _statBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(label,
              style:
                  const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16, color: color)),
        ],
      ),
    );
  }

  Widget _keypad(LocaleProvider loc) {
    final keys = ['7', '8', '9', '4', '5', '6', '1', '2', '3', '000', '0', '⌫'];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _quick(loc.t('pos.exact'), _exact),
            _quick('+1 000', () => _addSum(1000)),
            _quick('+5 000', () => _addSum(5000)),
            _quick('+10 000', () => _addSum(10000)),
            _quick('+50 000', () => _addSum(50000)),
            _quick('+100 000', () => _addSum(100000)),
          ],
        ),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          childAspectRatio: 1.9,
          children: keys
              .map((k) => ElevatedButton(
                    onPressed: () => _key(k),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.55),
                      foregroundColor: AppTheme.textPrimary,
                      elevation: 0,
                      padding: EdgeInsets.zero,
                    ),
                    child: Text(k,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _quick(String label, VoidCallback onTap) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.textPrimary,
        side: BorderSide(color: AppTheme.accentOrange.withOpacity(0.5)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Text(label),
    );
  }
}

class _PaymentResult {
  final String method;
  final int amountPaid;
  final int change;
  final Map<String, int> payments;
  final String? customerName;
  final String? note;

  _PaymentResult({
    required this.method,
    required this.amountPaid,
    required this.change,
    required this.payments,
    this.customerName,
    this.note,
  });
}

// ===== Modellar / yordamchilar =====
class _Chek {
  final int label;
  final List<CartItem> items;
  _Chek({required this.label}) : items = [];
}

class CartItem {
  final Product product;
  final ProductVariant? variant;
  int quantity;
  CartItem({required this.product, this.variant, this.quantity = 1});

  String get key => variant?.id ?? variant?.skuId ?? product.id ?? product.name;
  int get unitBase => product.price + (variant?.priceModifier ?? 0);
  int get availableStock => variant?.quantity ?? product.quantity;
  String? get size => variant?.size ?? product.size;
  String? get color => variant?.color ?? product.color;
  String get displayName => variant != null
      ? '${product.name} (${variant!.color}/${variant!.size})'
      : product.name;
}

String _money(int value) {
  final s = value.toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
    buf.write(s[i]);
  }
  return buf.toString();
}
