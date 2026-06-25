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

  /// Telegram'ga ilova tayyor ekanini bildirish + to'liq ekran
  static void init() {
    impl.ready();
    impl.expand();
  }
}
