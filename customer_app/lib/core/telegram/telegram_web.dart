import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'tg_user.dart';

@JS('Telegram')
external _Telegram? get _telegram;

extension type _Telegram(JSObject _) implements JSObject {
  external _WebApp? get WebApp;
  // Login Widget (telegram-widget.js) — oddiy brauzerda kirish uchun
  external _TgLogin? get Login;
}

extension type _TgLogin(JSObject _) implements JSObject {
  // auth(options, callback): callback'ga user obyekti YOKI false keladi
  external void auth(JSObject options, JSFunction callback);
}

// JS'ning global Object.keys / String — obyekt maydonlarini xavfsiz o'qish uchun
// (dartify() dart2js'da katta butun sonlarda "Int64 accessor" xatosi beradi).
@JS('Object.keys')
external JSArray<JSString> _objectKeys(JSObject o);

@JS('String')
external JSString _jsToString(JSAny? value);

extension type _WebApp(JSObject _) implements JSObject {
  external void ready();
  external void expand();
  external void disableVerticalSwipes();
  external _InitData? get initDataUnsafe;
  external String? get initData; // serverda HMAC tekshirish uchun xom satr
}

extension type _InitData(JSObject _) implements JSObject {
  external _TgUserJs? get user;
}

extension type _TgUserJs(JSObject _) implements JSObject {
  external JSNumber? get id;
  external String? get first_name;
  external String? get last_name;
  external String? get username;
  external String? get photo_url;
  external String? get language_code;
}

_WebApp? get _webApp {
  try {
    return _telegram?.WebApp;
  } catch (_) {
    return null;
  }
}

bool isInTelegram() {
  try {
    return _webApp?.initDataUnsafe?.user != null;
  } catch (_) {
    return false;
  }
}

TgUser? getTelegramUser() {
  try {
    final u = _webApp?.initDataUnsafe?.user;
    if (u == null) return null;
    final id = u.id;
    if (id == null) return null;
    return TgUser(
      id: id.toDartInt.toString(),
      firstName: u.first_name ?? '',
      lastName: u.last_name,
      username: u.username,
      photoUrl: u.photo_url,
      languageCode: u.language_code,
    );
  } catch (_) {
    return null;
  }
}

/// Telegram'dan kelgan xom `initData` satri (serverda HMAC tekshiriladi).
String? getRawInitData() {
  try {
    final d = _webApp?.initData;
    return (d == null || d.isEmpty) ? null : d;
  } catch (_) {
    return null;
  }
}

void ready() {
  try {
    _webApp?.ready();
  } catch (_) {}
}

void expand() {
  try {
    _webApp?.expand();
  } catch (_) {}
  // Vertikal swipe (pastga surib yopish) ni o'chirish — scroll ishlashi uchun
  try {
    _webApp?.disableVerticalSwipes();
  } catch (_) {}
}

/// Login Widget skripti (telegram-widget.js) yuklanganmi — oddiy brauzerda
/// «Telegram bilan kirish» tugmasini ko'rsatish uchun.
bool hasLoginWidget() {
  try {
    return _telegram?.Login != null;
  } catch (_) {
    return false;
  }
}

/// Telegram Login Widget popup'ini ochadi (`Telegram.Login.auth`).
/// Muvaffaqiyatda foydalanuvchi maydonlarini (id, first_name, username,
/// photo_url, auth_date, hash ...) Dart map sifatida qaytaradi — server
/// aynan shu maydonlar bo'yicha HMAC tekshiradi. Bekor qilinsa/xatoda null.
///
/// MUHIM: Telegram yuborgan BARCHA maydonlar o'zgartirilmasdan uzatiladi —
/// aks holda serverdagi data_check_string mos kelmay, imzo buziladi.
Future<Map<String, Object?>?> widgetLogin(String botId) {
  final completer = Completer<Map<String, Object?>?>();
  try {
    final login = _telegram?.Login;
    if (login == null || botId.isEmpty) return Future.value(null);

    final opts = JSObject();
    opts['bot_id'] = botId.toJS;
    // Bot foydalanuvchiga xabar yubora olishi uchun (buyurtma holati bildirishi)
    opts['request_access'] = 'write'.toJS;

    void cb(JSAny? user) {
      if (completer.isCompleted) return;
      try {
        // false / null / obyekt emas -> bekor qilindi yoki xato
        if (user == null || !user.isA<JSObject>()) {
          completer.complete(null);
          return;
        }
        final obj = user as JSObject;
        // Har bir maydonni JS String() bilan o'qiymiz — bu serverdagi
        // `${data[k]}` bilan AYNAN mos (id/auth_date toza butun-son stringi),
        // dartify()'siz => "Int64 accessor" xatosi yo'q. Barcha maydonlar
        // o'zgartirilmasdan uzatiladi (HMAC data_check_string mos kelishi uchun).
        final map = <String, Object?>{};
        final keys = _objectKeys(obj).toDart;
        for (final kJs in keys) {
          final k = kJs.toDart;
          final v = obj.getProperty<JSAny?>(kJs);
          if (v == null) continue;
          map[k] = _jsToString(v).toDart;
        }
        // hash bo'lmasa — imzosiz javob (bekor/xato)
        if (map['hash'] == null || (map['hash'] as String).isEmpty) {
          completer.complete(null);
          return;
        }
        completer.complete(map);
      } catch (_) {
        completer.complete(null);
      }
    }

    login.auth(opts, cb.toJS);
  } catch (_) {
    if (!completer.isCompleted) completer.complete(null);
  }
  return completer.future;
}
