import 'dart:js_interop';

import 'tg_user.dart';

@JS('Telegram')
external _Telegram? get _telegram;

extension type _Telegram(JSObject _) implements JSObject {
  external _WebApp? get WebApp;
}

extension type _WebApp(JSObject _) implements JSObject {
  external void ready();
  external void expand();
  external void disableVerticalSwipes();
  external _InitData? get initDataUnsafe;
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
