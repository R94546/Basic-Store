import 'tg_user.dart';
// Web'da js-interop implementatsiyasi, boshqa platformalarda stub.
import 'telegram_stub.dart'
    if (dart.library.js_interop) 'telegram_web.dart' as impl;

/// Telegram Mini App bilan ishlash uchun fasad.
/// Telegram'dan tashqarida (oddiy web/Android) hamma narsa null/no-op qaytaradi.
class TelegramService {
  /// Joriy Telegram foydalanuvchisi (yo'q bo'lsa null)
  static TgUser? get user => impl.getTelegramUser();

  /// Ilova Telegram ichida ochilganmi
  static bool get isInTelegram => impl.isInTelegram();

  /// Telegram'dan kelgan xom initData satri (serverda HMAC tekshiriladi).
  static String? get rawInitData => impl.getRawInitData();

  /// Telegram'ga ilova tayyor ekanini bildirish + to'liq ekran
  static void init() {
    impl.ready();
    impl.expand();
  }

  /// Oddiy brauzerda «Telegram bilan kirish» (Login Widget) mavjudmi.
  /// Faqat web'da va widget skripti yuklangan bo'lsa true.
  static bool get canWebLogin => impl.hasLoginWidget();

  /// Login Widget popup'ini ochib, tekshirilgan foydalanuvchi maydonlarini
  /// qaytaradi (serverda HMAC tekshirish uchun). Bekor/xatoda null.
  static Future<Map<String, Object?>?> widgetLogin(String botId) =>
      impl.widgetLogin(botId);
}
