import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/routes/app_router.dart';
import 'core/l10n/locale_provider.dart';
import 'screens/auth/login_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/product_provider.dart';
import 'providers/telegram_provider.dart';
import 'providers/printer_provider.dart';
import 'providers/order_provider.dart';
import 'providers/sale_provider.dart';
import 'providers/category_provider.dart';
import 'providers/stock_in_provider.dart';
import 'providers/session_provider.dart';
import 'providers/client_provider.dart';
import 'providers/debt_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => TelegramProvider()),
        ChangeNotifierProvider(create: (_) => PrinterProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => SaleProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => StockInProvider()),
        ChangeNotifierProvider(create: (_) => SessionProvider()),
        ChangeNotifierProvider(create: (_) => ClientProvider()),
        ChangeNotifierProvider(create: (_) => DebtProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()..load()),
      ],
      child: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Yuklanmoqda
          if (snapshot.connectionState == ConnectionState.waiting) {
            return MaterialApp(
              theme: AppTheme.lightTheme,
              debugShowCheckedModeBanner: false,
              home: const GradientBackground(
                child: Scaffold(
                  backgroundColor: Colors.transparent,
                  body: Center(child: CircularProgressIndicator()),
                ),
              ),
            );
          }

          // Tizimga kirilmagan
          if (snapshot.data == null) {
            return MaterialApp(
              theme: AppTheme.lightTheme,
              debugShowCheckedModeBanner: false,
              home: const GradientBackground(child: LoginScreen()),
            );
          }

          // Tizimga kirilgan
          return MaterialApp.router(
            title: 'Ayollar Kiyim - Admin',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            routerConfig: AppRouter.router,
          );
        },
      ),
    );
  }
}

