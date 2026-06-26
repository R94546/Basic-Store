import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/theme/app_theme.dart';
import '../../core/l10n/locale_provider.dart';
import '../../models/product.dart';
import '../../models/product_variant.dart';
import '../../providers/product_provider.dart';
import '../../providers/category_provider.dart';
import '../../widgets/image_picker_widget.dart';
import '../../services/image_upload_service.dart';
import '../../utils/barcode_util.dart';

/// Tovar qo'shish / tahrirlash oynasi.
///
/// [product] berilsa — tahrirlash rejimi, aks holda — yangi tovar qo'shish.
/// Helper sifatida [showProductFormDialog] dan foydalaning.
class ProductFormDialog extends StatefulWidget {
  final Product? product;

  const ProductFormDialog({super.key, this.product});

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

/// Tovar qo'shish/tahrirlash oynasini ochish uchun qulay yordamchi.
Future<void> showProductFormDialog(BuildContext context, {Product? product}) {
  return showDialog(
    context: context,
    builder: (_) => ProductFormDialog(product: product),
  );
}

/// Variant qatorini tahrirlash uchun ichki holat modeli.
class _VariantRow {
  String size;
  String color;
  final TextEditingController quantity;
  String barcode;

  _VariantRow({
    required this.size,
    required this.color,
    required this.quantity,
    required this.barcode,
  });
}

class _ProductFormDialogState extends State<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _imageUploadService = ImageUploadService();

  late final TextEditingController _nameController;
  late final TextEditingController _buyPriceController;
  late final TextEditingController _priceController;
  late final TextEditingController _quantityController;
  late final TextEditingController _discountController;
  late final TextEditingController _barcodeController;

  String? _selectedCategory;
  String _selectedSize = 'M';
  String? _selectedColor;
  bool _hasVariants = false;
  bool _isSaving = false;

  // Mavjud (yuklab bo'lingan) rasmlar va yangi tanlanganlar.
  late List<String> _existingImages;
  List<PlatformFile> _newImages = [];

  // Variant qatorlari.
  final List<_VariantRow> _variants = [];

  static const List<String> _sizeOptions = [
    'XS', 'S', 'M', 'L', 'XL', 'XXL', '3XL',
  ];
  static const List<String> _colorOptions = [
    'Qora', 'Oq', 'Qizil', "Ko'k", 'Yashil', 'Sariq', 'Pushti', 'Kulrang', "Jigarrang",
  ];

  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;

    _nameController = TextEditingController(text: p?.name ?? '');
    _buyPriceController = TextEditingController(
      text: p != null && p.buyPrice > 0 ? p.buyPrice.toString() : '',
    );
    _priceController = TextEditingController(
      text: p != null ? p.price.toString() : '',
    );
    _quantityController = TextEditingController(
      text: p != null ? p.quantity.toString() : '1',
    );
    _discountController = TextEditingController(
      text: p?.discount != null ? p!.discount.toString() : '',
    );
    _barcodeController = TextEditingController(
      text: p?.barcode ?? '',
    );

    _selectedCategory = p?.category;
    _selectedSize = (p != null && p.size.isNotEmpty) ? p.size : 'M';
    _selectedColor = p?.color;
    _hasVariants = p?.hasVariants ?? false;
    _existingImages = List<String>.from(p?.images ?? const []);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final catProvider = context.read<CategoryProvider>();
      if (catProvider.categoryNames.isEmpty) {
        catProvider.loadCategories();
      }
      // Tahrirlash rejimida mavjud variantlarni yuklash.
      if (_isEdit && _hasVariants && widget.product!.id != null) {
        _loadExistingVariants(widget.product!.id!);
      }
    });
  }

  Future<void> _loadExistingVariants(String productId) async {
    final list = await context.read<ProductProvider>().getVariants(productId);
    if (!mounted) return;
    setState(() {
      _variants.clear();
      for (final v in list) {
        _variants.add(_VariantRow(
          size: v.size,
          color: v.color,
          quantity: TextEditingController(text: v.quantity.toString()),
          barcode: v.barcode,
        ));
      }
    });
  }

  void _addVariantRow() {
    setState(() {
      _variants.add(_VariantRow(
        size: 'M',
        color: _colorOptions.first,
        quantity: TextEditingController(text: '0'),
        // Bo'sh — saqlashda avtomatik unikal ichki shtrix beriladi.
        barcode: '',
      ));
    });
  }

  void _removeVariantRow(int index) {
    setState(() {
      _variants[index].quantity.dispose();
      _variants.removeAt(index);
    });
  }

  int get _variantTotalQty {
    return _variants.fold<int>(
      0,
      (sum, r) => sum + (int.tryParse(r.quantity.text) ?? 0),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _buyPriceController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _discountController.dispose();
    _barcodeController.dispose();
    for (final v in _variants) {
      v.quantity.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final loc = context.read<LocaleProvider>();
    if (_hasVariants && _variants.isEmpty) {
      _snack(loc.t('form.addVariantFirst'), AppTheme.accentRed);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final provider = context.read<ProductProvider>();

      // Rasm yuklash uchun ID — tahrirlashda mavjud, aks holda vaqtinchalik.
      final uploadId =
          widget.product?.id ?? DateTime.now().millisecondsSinceEpoch.toString();

      final imageUrls = <String>[..._existingImages];
      if (_newImages.isNotEmpty) {
        final uploaded = await _imageUploadService.uploadMultipleImages(
          files: _newImages,
          productId: uploadId,
        );
        imageUrls.addAll(uploaded);
      }

      final buyPrice = int.tryParse(_buyPriceController.text) ?? 0;
      final price = int.parse(_priceController.text);
      final discount = int.tryParse(_discountController.text);
      // Oddiy tovar: shtrix bo'sh bo'lsa avtomatik beriladi (yangi tovarda —
      // provider, tahrirda — shu yerda). Variantli tovarda shtrix variantlarda.
      var barcode = _barcodeController.text.trim();
      if (_isEdit && !_hasVariants && barcode.isEmpty) {
        barcode = BarcodeUtil.fromSeq(await provider.allocateSku());
      }

      final totalQty = _hasVariants
          ? _variantTotalQty
          : (int.tryParse(_quantityController.text) ?? 0);

      final availableSizes =
          _hasVariants ? _variants.map((v) => v.size).toSet().toList() : <String>[];
      final availableColors =
          _hasVariants ? _variants.map((v) => v.color).toSet().toList() : <String>[];

      if (_isEdit) {
        final updated = widget.product!.copyWith(
          name: _nameController.text.trim(),
          category: _selectedCategory ?? widget.product!.category,
          size: _hasVariants ? widget.product!.size : _selectedSize,
          color: _hasVariants ? null : _selectedColor,
          buyPrice: buyPrice,
          price: price,
          quantity: totalQty,
          barcode: barcode,
          images: imageUrls,
          discount: discount,
          hasVariants: _hasVariants,
          availableSizes: availableSizes,
          availableColors: availableColors,
        );
        await provider.updateProduct(updated);
        // Eslatma: tahrirlashda variantlar qo'lda boshqariladi; bu yerda
        // faqat yangi qo'shilgan (ID siz) variantlar qo'shiladi.
        if (_hasVariants && widget.product!.id != null) {
          await _syncNewVariants(provider, widget.product!.id!);
        }
        _finish('${updated.name} ${loc.t('form.updated')}');
      } else {
        final product = Product(
          name: _nameController.text.trim(),
          category: _selectedCategory ?? 'Boshqa',
          size: _hasVariants ? 'M' : _selectedSize,
          color: _hasVariants ? null : _selectedColor,
          buyPrice: buyPrice,
          price: price,
          quantity: _hasVariants ? 0 : totalQty,
          barcode: barcode,
          images: imageUrls,
          discount: discount,
          hasVariants: _hasVariants,
          availableSizes: availableSizes,
          availableColors: availableColors,
        );

        final productId = await provider.addProduct(product);

        if (_hasVariants && productId != null) {
          final variants = _buildVariants(productId);
          if (variants.isNotEmpty) {
            await provider.addVariants(productId, variants);
          }
        }
        _finish('${product.name} ${loc.t('form.saved')}');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        _snack('${loc.t('common.error')}: $e', AppTheme.accentRed);
      }
    }
  }

  List<ProductVariant> _buildVariants(String productId) {
    final result = <ProductVariant>[];
    for (final r in _variants) {
      final qty = int.tryParse(r.quantity.text) ?? 0;
      result.add(ProductVariant(
        skuId: ProductVariant.generateSku(productId, r.size, r.color),
        size: r.size,
        color: r.color,
        quantity: qty,
        barcode: r.barcode,
      ));
    }
    return result;
  }

  /// Yangi qo'shilgan variantlarni (mavjudlarini qayta yozmasdan) qo'shadi.
  Future<void> _syncNewVariants(ProductProvider provider, String productId) async {
    final existing = await provider.getVariants(productId);
    final existingBarcodes = existing.map((v) => v.barcode).toSet();
    final fresh = _buildVariants(productId)
        .where((v) => !existingBarcodes.contains(v.barcode))
        .toList();
    if (fresh.isNotEmpty) {
      await provider.addVariants(productId, fresh);
    }
  }

  void _finish(String message) {
    if (!mounted) return;
    Navigator.pop(context);
    _snack(message, AppTheme.accentGreen);
  }

  void _snack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocaleProvider>();
    final categories = context.watch<CategoryProvider>().categoryNames;

    // Tanlangan kategoriya ro'yxatda yo'q bo'lsa qo'shib qo'yamiz.
    final categoryItems = <String>{
      ...categories,
      if (_selectedCategory != null) _selectedCategory!,
    }.toList();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: GlassCard(
        blur: 20,
        opacity: 0.95,
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720, maxHeight: 720),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(loc),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Rasmlar
                        ImagePickerWidget(
                          key: ValueKey(_existingImages.length),
                          existingImages: _existingImages,
                          onImagesSelected: (files) =>
                              setState(() => _newImages = files),
                          maxImages: 5,
                        ),
                        if (_existingImages.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _buildExistingImageRemovers(),
                        ],
                        const SizedBox(height: 16),

                        // Nomi + Kategoriya
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _nameController,
                                decoration: InputDecoration(
                                  labelText: loc.t('common.name'),
                                  prefixIcon: const Icon(Icons.shopping_bag),
                                ),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? loc.t('form.enterName')
                                        : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedCategory,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  labelText: loc.t('common.category'),
                                  prefixIcon: const Icon(Icons.category),
                                ),
                                items: categoryItems
                                    .map((c) => DropdownMenuItem(
                                          value: c,
                                          child: Text(c,
                                              overflow: TextOverflow.ellipsis),
                                        ))
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _selectedCategory = v),
                                validator: (v) => (v == null || v.isEmpty)
                                    ? loc.t('form.selectCategory')
                                    : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Kelish narxi + Sotish narxi + Chegirma
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _numberField(
                                controller: _buyPriceController,
                                label: loc.t('product.buyPrice'),
                                icon: Icons.south_west,
                                required: false,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _numberField(
                                controller: _priceController,
                                label: loc.t('product.sellPrice'),
                                icon: Icons.sell,
                                required: true,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _numberField(
                                controller: _discountController,
                                label: '${loc.t('product.discount')} %',
                                icon: Icons.percent,
                                required: false,
                                max: 100,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildMarginHint(),
                        const SizedBox(height: 16),

                        // Shtrix kod
                        _buildBarcodeField(loc),
                        const SizedBox(height: 16),

                        // Variant toggle
                        _buildVariantToggle(loc),
                        const SizedBox(height: 12),

                        if (_hasVariants)
                          _buildVariantsSection(loc)
                        else
                          _buildSimpleSection(loc),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildActions(loc),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(LocaleProvider loc) {
    return Row(
      children: [
        Icon(_isEdit ? Icons.edit : Icons.add_box,
            color: AppTheme.accentOrange),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            _isEdit ? loc.t('common.edit') : loc.t('product.new'),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close, color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _numberField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool required,
    int? max,
  }) {
    final loc = context.read<LocaleProvider>();
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: (v) {
        if (v == null || v.trim().isEmpty) {
          return required ? loc.t('form.required') : null;
        }
        final n = int.tryParse(v.trim());
        if (n == null || n < 0) return loc.t('form.invalid');
        if (max != null && n > max) return '0-$max';
        return null;
      },
    );
  }

  Widget _buildMarginHint() {
    final loc = context.read<LocaleProvider>();
    final buy = int.tryParse(_buyPriceController.text) ?? 0;
    final sell = int.tryParse(_priceController.text) ?? 0;
    if (buy <= 0 || sell <= 0) return const SizedBox.shrink();
    final profit = sell - buy;
    final color = profit >= 0 ? AppTheme.accentGreen : AppTheme.accentRed;
    return Row(
      children: [
        Icon(Icons.trending_up, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          '${loc.t('form.profit')}: $profit ${loc.t('common.sum')}',
          style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildBarcodeField(LocaleProvider loc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: TextFormField(
            controller: _barcodeController,
            decoration: InputDecoration(
              labelText: loc.t('product.barcode'),
              helperText: loc.t('form.barcodeHint'),
              prefixIcon: const Icon(Icons.qr_code_2),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
        ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          onPressed: () async {
            final code = BarcodeUtil.fromSeq(
                await context.read<ProductProvider>().allocateSku());
            if (mounted) setState(() => _barcodeController.text = code);
          },
          icon: const Icon(Icons.autorenew, size: 18),
          label: Text(loc.t('product.generateBarcode')),
        ),
      ],
    );
  }

  Widget _buildVariantToggle(LocaleProvider loc) {
    return GlassCard(
      opacity: 0.2,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.tune, color: AppTheme.accentOrange, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${loc.t('product.variants')} ${loc.t('form.hasVariants')}',
              style: const TextStyle(
                  color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
            ),
          ),
          Switch(
            value: _hasVariants,
            activeColor: AppTheme.accentOrange,
            onChanged: (v) => setState(() => _hasVariants = v),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleSection(LocaleProvider loc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _sizeOptions.contains(_selectedSize) ? _selectedSize : null,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: loc.t('product.size'),
              prefixIcon: const Icon(Icons.straighten),
            ),
            items: _sizeOptions
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (v) => setState(() => _selectedSize = v ?? 'M'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _colorOptions.contains(_selectedColor) ? _selectedColor : null,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: loc.t('product.color'),
              prefixIcon: const Icon(Icons.palette),
            ),
            items: _colorOptions
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => setState(() => _selectedColor = v),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _numberField(
            controller: _quantityController,
            label: loc.t('common.qty'),
            icon: Icons.numbers,
            required: true,
          ),
        ),
      ],
    );
  }

  Widget _buildVariantsSection(LocaleProvider loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '${loc.t('product.variants')} (${loc.t('form.variantTotal')}: $_variantTotalQty ${loc.t('unit.pcs')})',
              style: const TextStyle(
                  fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _addVariantRow,
              icon: const Icon(Icons.add, size: 18),
              label: Text(loc.t('form.variant')),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_variants.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              loc.t('form.variantHint'),
              style: const TextStyle(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          )
        else
          ...List.generate(_variants.length, (i) => _buildVariantRow(loc, i)),
      ],
    );
  }

  Widget _buildVariantRow(LocaleProvider loc, int index) {
    final row = _variants[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // O'lcham
          SizedBox(
            width: 90,
            child: DropdownButtonFormField<String>(
              value: _sizeOptions.contains(row.size) ? row.size : null,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: loc.t('product.size'),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              items: _sizeOptions
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => setState(() => row.size = v ?? row.size),
            ),
          ),
          const SizedBox(width: 8),
          // Rang
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _colorOptions.contains(row.color) ? row.color : null,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: loc.t('product.color'),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              items: _colorOptions
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => row.color = v ?? row.color),
            ),
          ),
          const SizedBox(width: 8),
          // Soni
          SizedBox(
            width: 70,
            child: TextFormField(
              controller: row.quantity,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: loc.t('common.qty'),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          IconButton(
            tooltip: loc.t('product.barcode'),
            icon: const Icon(Icons.qr_code_2, size: 20),
            color: AppTheme.textSecondary,
            onPressed: () => _showVariantBarcode(loc, row),
          ),
          IconButton(
            tooltip: loc.t('common.delete'),
            icon: const Icon(Icons.delete_outline, size: 20),
            color: AppTheme.accentRed,
            onPressed: () => _removeVariantRow(index),
          ),
        ],
      ),
    );
  }

  void _showVariantBarcode(LocaleProvider loc, _VariantRow row) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.gradientStart,
        title: Text(loc.t('product.barcode'),
            style: const TextStyle(color: AppTheme.textPrimary)),
        content: Text(
          '${row.size} • ${row.color}\n'
          '${row.barcode.isEmpty ? loc.t('form.barcodeAuto') : row.barcode}',
          style: const TextStyle(
              color: AppTheme.textSecondary,
              fontFamily: 'monospace',
              letterSpacing: 2),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final code = BarcodeUtil.fromSeq(
                  await context.read<ProductProvider>().allocateSku());
              if (mounted) setState(() => row.barcode = code);
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(loc.t('product.generateBarcode')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.t('common.cancel')),
          ),
        ],
      ),
    );
  }

  Widget _buildExistingImageRemovers() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(_existingImages.length, (i) {
        final url = _existingImages[i];
        return Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: url,
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  width: 64,
                  height: 64,
                  color: Colors.white.withValues(alpha: 0.4),
                  child: const Icon(Icons.broken_image,
                      color: AppTheme.textSecondary),
                ),
              ),
            ),
            Positioned(
              top: 2,
              right: 2,
              child: GestureDetector(
                onTap: () => setState(() => _existingImages.removeAt(i)),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: AppTheme.accentRed,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 12, color: Colors.white),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildActions(LocaleProvider loc) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isSaving ? null : () => Navigator.pop(context),
            child: Text(loc.t('common.cancel')),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : _save,
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.save),
            label: Text(_isSaving ? loc.t('form.saving') : loc.t('common.save')),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}
