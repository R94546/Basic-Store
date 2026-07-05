import 'package:shared_preferences/shared_preferences.dart';

/// Mijoz profili + oxirgi kiritilgan ma'lumotlar (SharedPreferences).
/// - TG login (web) natijasi: ism/username/rasm
/// - Oxirgi telefon va manzil — checkout'da avtomatik to'ldirish uchun
class CustomerProfile {
  static const _kName = 'tg_web_name';
  static const _kUsername = 'tg_web_username';
  static const _kPhoto = 'tg_web_photo';
  static const _kPhone = 'customer_phone';
  static const _kAddress = 'customer_address';

  /// Web Telegram login profilini saqlash
  static Future<void> saveTg({
    required String name,
    required String username,
    required String photo,
  }) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kName, name);
    await p.setString(_kUsername, username);
    await p.setString(_kPhoto, photo);
  }

  static Future<String> name() async =>
      (await SharedPreferences.getInstance()).getString(_kName) ?? '';
  static Future<String> username() async =>
      (await SharedPreferences.getInstance()).getString(_kUsername) ?? '';
  static Future<String> photo() async =>
      (await SharedPreferences.getInstance()).getString(_kPhoto) ?? '';
  static Future<String> phone() async =>
      (await SharedPreferences.getInstance()).getString(_kPhone) ?? '';
  static Future<String> address() async =>
      (await SharedPreferences.getInstance()).getString(_kAddress) ?? '';

  static Future<void> savePhone(String v) async {
    if (v.trim().isEmpty) return;
    await (await SharedPreferences.getInstance()).setString(_kPhone, v.trim());
  }

  static Future<void> saveAddress(String v) async {
    if (v.trim().isEmpty) return;
    await (await SharedPreferences.getInstance()).setString(_kAddress, v.trim());
  }
}
