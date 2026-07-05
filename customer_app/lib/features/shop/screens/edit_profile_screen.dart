import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:customer_app/core/customer_profile.dart';
import 'package:customer_app/core/l10n/locale_provider.dart';
import 'package:customer_app/core/theme/app_theme.dart';

/// Mijoz ma'lumotlarini tahrirlash — ism / telefon / manzil.
/// Bular SharedPreferences'da saqlanadi va checkout'da avtomatik to'ldiriladi.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _name.text = await CustomerProfile.name();
    _phone.text = await CustomerProfile.phone();
    _address.text = await CustomerProfile.address();
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final loc = context.read<LocaleProvider>();
    // Telefonni normallashtirish: +998 + oxirgi 9 raqam
    final digits = _phone.text.replaceAll(RegExp(r'\D'), '');
    final phone = digits.isEmpty
        ? ''
        : '+998${digits.length > 9 ? digits.substring(digits.length - 9) : digits}';

    await CustomerProfile.saveName(_name.text.trim());
    await CustomerProfile.savePhone(phone);
    await CustomerProfile.saveAddress(_address.text.trim());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(loc.t('profile.saved'))),
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
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
          loc.t('profile.editTitle').toUpperCase(),
          style: GoogleFonts.playfairDisplay(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  loc.t('profile.editHint'),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 20),
                _field(loc.t('profile.name'), _name, TextInputType.name),
                const SizedBox(height: 16),
                _field(loc.t('profile.phone'), _phone, TextInputType.phone,
                    prefix: '+998 '),
                const SizedBox(height: 16),
                _field(loc.t('profile.address'), _address, TextInputType.text,
                    maxLines: 2),
                const SizedBox(height: 28),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(),
                    ),
                    child: Text(
                      loc.t('profile.save').toUpperCase(),
                      style: const TextStyle(letterSpacing: 1),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _field(String label, TextEditingController c, TextInputType type,
      {String? prefix, int maxLines = 1}) {
    return TextField(
      controller: c,
      keyboardType: type,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefix,
        labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
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
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }
}
