import 'dart:convert';

import 'package:http/http.dart' as http;

/// Callable Cloud Function'larni ODDIY HTTP orqali chaqirish.
///
/// SABAB: `cloud_functions` plagini web'da (dart2js) callable chaqiruvida
/// "Unsupported operation: Int64 accessor not supported by dart2js" xatosini
/// beradi. Shuning uchun callable protokolini qo'lda bajaramiz:
///   POST <base>/<name>   body: {"data": <payload>}   ->   {"result": <result>}
///
/// Faqat AUTH TALAB QILMAYDIGAN funksiyalar uchun (telegramAuth,
/// telegramLoginAuth, telegramLoginInfo) — shuning uchun Authorization
/// header shart emas.
const String _fnBaseUrl =
    'https://us-central1-zara-shop-automation-uz.cloudfunctions.net';

Future<Map<String, dynamic>?> callFunction(
  String name, [
  Map<String, dynamic>? data,
]) async {
  final res = await http.post(
    Uri.parse('$_fnBaseUrl/$name'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'data': data ?? <String, dynamic>{}}),
  );
  if (res.statusCode != 200) {
    throw Exception('$name ${res.statusCode}: ${res.body}');
  }
  final decoded = jsonDecode(res.body);
  final result = (decoded is Map) ? decoded['result'] : null;
  return (result is Map) ? result.cast<String, dynamic>() : null;
}
