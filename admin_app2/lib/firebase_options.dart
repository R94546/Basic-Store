// File generated from android/app/google-services.json.
//
// Eslatma: bu fayl `flutterfire configure` orqali avtomatik yaratiladi.
// Hozircha mavjud google-services.json (Android) ma'lumotlaridan qo'lda
// tuzildi, shunda loyiha kompilyatsiya bo'lib, Android'da ishlaydi.
// Web/Windows/iOS uchun to'liq sozlash kerak bo'lsa `flutterfire configure`
// buyrug'ini ishga tushiring.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return ios;
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return web;
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDX_2W3_ppzlxsAW_k_kZLiUj0clOBa3vI',
    appId: '1:24388481813:android:55934b22eb1cb48a82ef1c',
    messagingSenderId: '24388481813',
    projectId: 'zara-shop-automation-uz',
    storageBucket: 'zara-shop-automation-uz.firebasestorage.app',
  );

  // Web/Desktop uchun vaqtinchalik (Android loyihasi bilan bir xil proyekt).
  // To'liq web sozlash uchun `flutterfire configure` ni ishlating.
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDX_2W3_ppzlxsAW_k_kZLiUj0clOBa3vI',
    appId: '1:24388481813:web:55934b22eb1cb48a82ef1c',
    messagingSenderId: '24388481813',
    projectId: 'zara-shop-automation-uz',
    storageBucket: 'zara-shop-automation-uz.firebasestorage.app',
    authDomain: 'zara-shop-automation-uz.firebaseapp.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDX_2W3_ppzlxsAW_k_kZLiUj0clOBa3vI',
    appId: '1:24388481813:ios:55934b22eb1cb48a82ef1c',
    messagingSenderId: '24388481813',
    projectId: 'zara-shop-automation-uz',
    storageBucket: 'zara-shop-automation-uz.firebasestorage.app',
    iosBundleId: 'com.zarastyle.customerApp',
  );
}
