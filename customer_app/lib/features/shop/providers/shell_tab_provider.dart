import 'package:flutter/foundation.dart';

/// Pastki navigatsiya (CustomerShell) joriy tabini boshqaradi.
/// Boshqa ekranlardan ham tabni almashtirish uchun (masalan buyurtmadan
/// keyin bosh sahifaga o'tish).
class ShellTabProvider extends ChangeNotifier {
  int _index = 0;
  int get index => _index;

  static const int home = 0;
  static const int search = 1;
  static const int menu = 2;
  static const int cart = 3;
  static const int wishlist = 4;
  static const int profile = 5;

  void setIndex(int i) {
    if (i == _index) return;
    _index = i;
    notifyListeners();
  }
}
