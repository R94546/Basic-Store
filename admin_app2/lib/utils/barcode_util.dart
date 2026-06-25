/// Shtrix kod (EAN-13) generatsiya va tekshirish yordamchisi.
class BarcodeUtil {
  /// Berilgan 12 raqamdan EAN-13 nazorat raqamini (checksum) hisoblaydi.
  static int ean13Checksum(String twelveDigits) {
    int sum = 0;
    for (int i = 0; i < 12; i++) {
      final d = int.parse(twelveDigits[i]);
      sum += (i % 2 == 0) ? d : d * 3;
    }
    final mod = sum % 10;
    return mod == 0 ? 0 : 10 - mod;
  }

  /// To'liq, to'g'ri EAN-13 (13 raqam) generatsiya qiladi.
  /// [seed] — takrorlanmaslik uchun son (masalan, vaqt yoki hisoblagich).
  static String generateEan13({int? seed}) {
    final base = seed ?? DateTime.now().millisecondsSinceEpoch;
    // Mahalliy do'kon prefiksi 200 (ichki ishlatish uchun rezerv)
    var body = '200${(base % 1000000000).toString().padLeft(9, '0')}';
    if (body.length > 12) body = body.substring(0, 12);
    body = body.padRight(12, '0');
    return body + ean13Checksum(body).toString();
  }

  /// EAN-13 to'g'ri yoki yo'qligini tekshiradi.
  static bool isValidEan13(String code) {
    if (code.length != 13 || int.tryParse(code) == null) return false;
    return ean13Checksum(code.substring(0, 12)) ==
        int.parse(code[12]);
  }
}
