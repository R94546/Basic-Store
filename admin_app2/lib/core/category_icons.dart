import 'package:flutter/material.dart';

/// Kategoriya uchun tanlanadigan ikonkalar to'plami.
/// Har bir kategoriya `icon` maydonida shu kalitlardan birini saqlaydi.
class CategoryIcons {
  CategoryIcons._();

  /// Kalit -> ikonka
  static const Map<String, IconData> _icons = {
    'clothes': Icons.checkroom,            // Kiyim
    'dress': Icons.woman,                  // Ko'ylak
    'tshirt': Icons.dry_cleaning,          // Futbolka
    'pants': Icons.airline_seat_legroom_extra, // Shim
    'jacket': Icons.ac_unit,               // Kurtka / ustki kiyim
    'shoes': Icons.ice_skating,            // Oyoq kiyim
    'sport': Icons.directions_run,         // Sport
    'bag': Icons.shopping_bag,             // Sumka
    'backpack': Icons.backpack,            // Ryukzak
    'belt': Icons.linear_scale,            // Remen
    'scarf': Icons.waves,                  // Sharf
    'hat': Icons.sports_motorsports,       // Bosh kiyim
    'glasses': Icons.visibility,           // Ko'zoynak
    'watch': Icons.watch,                  // Soat
    'jewelry': Icons.diamond,              // Zargarlik / aksessuar
    'keychain': Icons.vpn_key,             // Brelok
    'kids': Icons.child_care,              // Bolalar
    'underwear': Icons.layers,             // Ichki kiyim
    'socks': Icons.thermostat,             // Paypoq
    'other': Icons.category,               // Boshqa
  };

  /// Kalit -> {uz, ru} nomi (tanlash oynasida ko'rsatish uchun)
  static const Map<String, Map<String, String>> labels = {
    'clothes': {'uz': 'Kiyim', 'ru': 'Одежда'},
    'dress': {'uz': "Ko'ylak", 'ru': 'Платье'},
    'tshirt': {'uz': 'Futbolka', 'ru': 'Футболка'},
    'pants': {'uz': 'Shim', 'ru': 'Брюки'},
    'jacket': {'uz': 'Kurtka', 'ru': 'Куртка'},
    'shoes': {'uz': 'Oyoq kiyim', 'ru': 'Обувь'},
    'sport': {'uz': 'Sport', 'ru': 'Спорт'},
    'bag': {'uz': 'Sumka', 'ru': 'Сумка'},
    'backpack': {'uz': 'Ryukzak', 'ru': 'Рюкзак'},
    'belt': {'uz': 'Remen', 'ru': 'Ремень'},
    'scarf': {'uz': 'Sharf', 'ru': 'Шарф'},
    'hat': {'uz': 'Bosh kiyim', 'ru': 'Головной убор'},
    'glasses': {'uz': "Ko'zoynak", 'ru': 'Очки'},
    'watch': {'uz': 'Soat', 'ru': 'Часы'},
    'jewelry': {'uz': 'Aksessuar', 'ru': 'Аксессуары'},
    'keychain': {'uz': 'Brelok', 'ru': 'Брелок'},
    'kids': {'uz': 'Bolalar', 'ru': 'Детское'},
    'underwear': {'uz': 'Ichki kiyim', 'ru': 'Бельё'},
    'socks': {'uz': 'Paypoq', 'ru': 'Носки'},
    'other': {'uz': 'Boshqa', 'ru': 'Другое'},
  };

  static List<String> get keys => _icons.keys.toList();

  /// Kalit (yoki eski emoji/nomalum qiymat) bo'yicha ikonka. Topilmasa — default.
  static IconData iconFor(String? key) {
    if (key == null) return Icons.category;
    return _icons[key] ?? Icons.category;
  }

  static String label(String key, String lang) =>
      labels[key]?[lang] ?? labels[key]?['uz'] ?? key;
}
