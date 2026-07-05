import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'core/functions_call.dart';
import 'core/theme/app_theme.dart';
import 'core/l10n/locale_provider.dart';
import 'core/telegram/telegram_service.dart';
import 'features/shop/customer_shell.dart';
import 'features/shop/providers/cart_provider.dart';
import 'features/shop/providers/order_provider.dart';
import 'features/shop/providers/wishlist_provider.dart';
import 'features/shop/providers/video_background_provider.dart';
import 'features/shop/providers/catalog_provider.dart';
import 'features/shop/providers/shell_tab_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Auth — buyurtmalar egasiga bog'lanadi (xavfsizlik: faqat o'z buyurtmalarini
  // o'qiy oladi). Telegram ichida bo'lsa — initData serverda HMAC bilan
  // tekshirilib, ISHONCHLI uid (tg_<id>) beriladi; aks holda anonim.
  // Har qanday xatoda anonimga qaytadi — buyurtma berish hech qachon to'xtamaydi.
  try {
    if (FirebaseAuth.instance.currentUser == null) {
      final initData = TelegramService.rawInitData;
      if (initData != null) {
        try {
          // HTTP orqali (cloud_functions web'da Int64 xatosi beradi)
          final res = await callFunction('telegramAuth', {'initData': initData});
          final token = (res?['token'] ?? '').toString();
          if (token.isNotEmpty) {
            await FirebaseAuth.instance.signInWithCustomToken(token);
          }
        } catch (_) {}
      }
      if (FirebaseAuth.instance.currentUser == null) {
        await FirebaseAuth.instance.signInAnonymously();
      }
    }
  } catch (_) {}
  // Telegram Mini App'ga tayyor ekanini bildirish (Telegram'dan tashqarida no-op)
  TelegramService.init();
  runApp(const CustomerApp());
}

class CustomerApp extends StatelessWidget {
  const CustomerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => WishlistProvider()),
        ChangeNotifierProvider(create: (_) => VideoBackgroundProvider()),
        ChangeNotifierProvider(create: (_) => CatalogProvider()),
        ChangeNotifierProvider(create: (_) => ShellTabProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()..load()),
      ],
      child: MaterialApp(
        title: 'Basic Store',
        theme: CustomerTheme.lightTheme,
        home: const CustomerShell(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
