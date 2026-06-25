import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:customer_app/core/theme/app_theme.dart';
import 'package:customer_app/core/l10n/locale_provider.dart';
import 'package:customer_app/core/telegram/telegram_service.dart';
import '../providers/cart_provider.dart';
import '../models/order_model.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Telegram'dan ism avtomatik to'ldiriladi (mijoz o'zgartira oladi)
    final tg = TelegramService.user;
    if (tg != null && tg.fullName.isNotEmpty) {
      _nameController.text = tg.fullName;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// Telefon maydonidagi 9 ta mahalliy raqam (probellar bilan formatlangan).
  /// To'liq normallashgan raqam: "+998" + 9 ta raqam.
  String _localDigits(String raw) {
    return raw.replaceAll(RegExp(r'\D'), '');
  }

  String _normalizePhone(String raw) {
    return '+998${_localDigits(raw)}';
  }

  Future<void> _placeOrder() async {
    final loc = context.read<LocaleProvider>();
    if (!_formKey.currentState!.validate()) return;

    final cart = context.read<CartProvider>();
    if (cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.t('cart.empty'))),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final normalizedPhone = _normalizePhone(_phoneController.text.trim());
      final tg = TelegramService.user;

      final order = CustomerOrder(
        customerId: tg?.id,
        customerName: _nameController.text.trim(),
        customerPhone: normalizedPhone,
        customerAddress: _addressController.text.trim(),
        customerPhoto: tg?.photoUrl,
        customerUsername: tg?.username,
        items: cart.items,
        subtotal: cart.subtotal,
        deliveryFee: cart.deliveryFee,
        total: cart.total,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        status: OrderStatus.pending,
      );

      // Save to Firestore
      await FirebaseFirestore.instance.collection('orders').add(order.toMap());

      // Buyurtmalar tarixi uchun mijozni saqlash (telefon + Telegram id)
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('customer_phone', normalizedPhone);
        if (tg?.id != null) {
          await prefs.setString('customer_tg_id', tg!.id);
        }
      } catch (_) {
        // Saqlashda xatolik bo'lsa ham buyurtma muvaffaqiyatli
      }

      // Clear cart
      cart.clear();

      if (!mounted) return;

      // Show success and navigate back
      _showSuccessDialog();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${loc.t('common.error')}: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessDialog() {
    final loc = context.read<LocaleProvider>();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: const RoundedRectangleBorder(),
        title: const Icon(
          Icons.check_circle_outline,
          color: Colors.green,
          size: 64,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              loc.t('checkout.success'),
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              loc.t('checkout.successDesc'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: const RoundedRectangleBorder(),
              ),
              child: Text(loc.t('cart.continueShopping').toUpperCase()),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final loc = context.watch<LocaleProvider>();

    return Scaffold(
      backgroundColor: CustomerTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          loc.t('checkout.title').toUpperCase(),
          style: GoogleFonts.playfairDisplay(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Contact Information
            _SectionTitle(title: loc.t('checkout.name').toUpperCase()),
            const SizedBox(height: 16),

            _StyledTextField(
              controller: _nameController,
              label: loc.t('checkout.name'),
              hint: loc.t('checkout.name'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return loc.t('checkout.required');
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            _StyledTextField(
              controller: _phoneController,
              label: loc.t('checkout.phone'),
              hint: '90 111 22 33',
              prefixText: '+998 ',
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                _UzPhoneFormatter(),
              ],
              validator: (value) {
                final digits = _localDigits(value ?? '');
                if (digits.length < 9) {
                  return loc.t('checkout.required');
                }
                return null;
              },
            ),

            const SizedBox(height: 32),

            // Delivery Address
            _SectionTitle(title: loc.t('checkout.address').toUpperCase()),
            const SizedBox(height: 16),

            _StyledTextField(
              controller: _addressController,
              label: loc.t('checkout.address'),
              hint: loc.t('checkout.address'),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return loc.t('checkout.required');
                }
                return null;
              },
            ),

            const SizedBox(height: 32),

            // Order Notes
            _SectionTitle(title: loc.t('checkout.notes').toUpperCase()),
            const SizedBox(height: 16),

            _StyledTextField(
              controller: _notesController,
              label: loc.t('checkout.notes'),
              hint: loc.t('checkout.notes'),
              maxLines: 3,
            ),

            const SizedBox(height: 32),

            // Order Summary
            _SectionTitle(title: loc.t('cart.total').toUpperCase()),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  ...cart.items.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${item.name.toUpperCase()} x${item.quantity}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            Text(
                              '${_formatPrice(item.totalPrice)} ${loc.t('common.sum')}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      )),

                  Divider(color: Colors.grey[300]),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(loc.t('cart.subtotal'),
                          style: const TextStyle(fontSize: 12)),
                      Text('${_formatPrice(cart.subtotal)} ${loc.t('common.sum')}',
                          style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(loc.t('cart.delivery'),
                          style: const TextStyle(fontSize: 12)),
                      Text(
                        cart.deliveryFee > 0
                            ? '${_formatPrice(cart.deliveryFee)} ${loc.t('common.sum')}'
                            : loc.t('cart.free').toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          color: cart.deliveryFee == 0 ? Colors.green : null,
                        ),
                      ),
                    ],
                  ),

                  Divider(color: Colors.grey[300]),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        loc.t('cart.total').toUpperCase(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_formatPrice(cart.total)} ${loc.t('common.sum')}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Place Order Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _placeOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: const RoundedRectangleBorder(),
                  disabledBackgroundColor: Colors.grey,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : Text(
                        loc.t('checkout.placeOrder'),
                        style: const TextStyle(letterSpacing: 1),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // Payment Info
            Text(
              loc.t('checkout.successDesc'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        );
  }
}

/// O'zbek telefon raqamini formatlovchi: 9 ta raqamni "90 111 22 33"
/// ko'rinishida (2 3 2 2) ajratadi va 9 ta raqamdan oshmaydi.
class _UzPhoneFormatter extends TextInputFormatter {
  static const List<int> _groups = [2, 3, 2, 2];

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 9) {
      digits = digits.substring(0, 9);
    }

    final buffer = StringBuffer();
    var index = 0;
    for (final size in _groups) {
      if (index >= digits.length) break;
      if (buffer.isNotEmpty) buffer.write(' ');
      final end =
          (index + size) <= digits.length ? index + size : digits.length;
      buffer.write(digits.substring(index, end));
      index = end;
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
      ),
    );
  }
}

class _StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;
  final String? prefixText;
  final List<TextInputFormatter>? inputFormatters;

  const _StyledTextField({
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboardType,
    this.maxLines = 1,
    this.validator,
    this.prefixText,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: prefixText,
        prefixStyle: const TextStyle(
          color: Colors.black,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: Colors.black),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: Colors.red),
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }
}
