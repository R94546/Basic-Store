/// Shtrix kod (EAN-13) generatsiya va tekshirish yordamchisi.
///
/// Ichki tizim ketma-ket hisoblagich (`counters/sku`) beradigan [seq] raqamdan
/// foydalanadi: har bir SKU (oddiy tovar yoki variant) uchun bitta unikal,
/// doimiy va takrorlanmaydigan kod. Bir xil [seq] har doim bir xil shtrixni
/// beradi — shu sababli tovar kartasidan dublikat (qayta) chop etish mumkin.
class BarcodeUtil {
  /// Ichki do'kon prefiksi (GS1 200–299 oralig'i ichki ishlatish uchun rezerv).
  static const String internalPrefix = '200';

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

  /// Ketma-ket [seq] raqamdan to'liq, unikal EAN-13 (13 raqam) yasaydi.
  ///
  /// Body = `200` + seq (9 raqamga to'ldirilgan) + checksum.
  /// Vaqtga bog'liq emas, shuning uchun dublikat bo'lishi mumkin emas.
  static String fromSeq(int seq) {
    final body = internalPrefix + (seq % 1000000000).toString().padLeft(9, '0');
    return body + ean13Checksum(body).toString();
  }

  /// Shtrix ichki (`200…`) va to'g'ri bo'lsa — undagi qisqa **artikul** raqamini
  /// qaytaradi (masalan, `1042`). Tashqi (yetkazib beruvchi) kodlar uchun bo'sh
  /// string. Artikul — kassir skaner ishlamaganda qo'lda teradigan qisqa raqam.
  static String articleOf(String code) {
    final c = code.trim();
    if (c.length == 13 && c.startsWith(internalPrefix) && isValidEan13(c)) {
      final seq = int.tryParse(c.substring(3, 12)) ?? 0;
      if (seq > 0) return seq.toString();
    }
    return '';
  }

  /// To'liq, to'g'ri EAN-13 (13 raqam) generatsiya qiladi (zaxira yo'l).
  ///
  /// Iloji bo'lsa [fromSeq] ishlatilsin — u hisoblagichga asoslanib unikallikni
  /// kafolatlaydi. Bu metod faqat hisoblagich mavjud bo'lmaganda ishlatiladi.
  static String generateEan13({int? seed}) {
    final base = seed ?? DateTime.now().millisecondsSinceEpoch;
    return fromSeq(base % 1000000000);
  }

  /// EAN-13 to'g'ri yoki yo'qligini tekshiradi.
  static bool isValidEan13(String code) {
    if (code.length != 13 || int.tryParse(code) == null) return false;
    return ean13Checksum(code.substring(0, 12)) == int.parse(code[12]);
  }
}
