// google-services.json (Android) asosida qo'lda tuzilgan.
// Web/Telegram Mini App uchun ham shu proyekt ishlatiladi.
// To'liq web sozlash uchun `flutterfire configure` ni ishga tushiring.
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
      default:
        return web;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDX_2W3_ppzlxsAW_k_kZLiUj0clOBa3vI',
    appId: '1:24388481813:android:7e404f449cd24bc782ef1c',
    messagingSenderId: '24388481813',
    projectId: 'zara-shop-automation-uz',
    storageBucket: 'zara-shop-automation-uz.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDX_2W3_ppzlxsAW_k_kZLiUj0clOBa3vI',
    appId: '1:24388481813:web:7e404f449cd24bc782ef1c',
    messagingSenderId: '24388481813',
    projectId: 'zara-shop-automation-uz',
    storageBucket: 'zara-shop-automation-uz.firebasestorage.app',
    authDomain: 'zara-shop-automation-uz.firebaseapp.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDX_2W3_ppzlxsAW_k_kZLiUj0clOBa3vI',
    appId: '1:24388481813:ios:7e404f449cd24bc782ef1c',
    messagingSenderId: '24388481813',
    projectId: 'zara-shop-automation-uz',
    storageBucket: 'zara-shop-automation-uz.firebasestorage.app',
    iosBundleId: 'com.zarastyle.customerApp',
  );
}
