import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_strings.dart';

/// Til (UZ/RU) provideri. Tanlangan til qurilmada (SharedPreferences) saqlanadi.
class LocaleProvider extends ChangeNotifier {
  static const _key = 'app_lang';
  String _lang = 'uz';

  String get lang => _lang;
  bool get isUz => _lang == 'uz';

  String t(String key) {
    final entry = AppStrings.values[key];
    if (entry == null) return key;
    return entry[_lang] ?? entry['uz'] ?? key;
  }

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_key);
      if (saved == 'uz' || saved == 'ru') {
        _lang = saved!;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Locale load error: $e');
    }
  }

  Future<void> setLang(String lang) async {
    if (lang != 'uz' && lang != 'ru') return;
    _lang = lang;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, lang);
    } catch (e) {
      debugPrint('Locale save error: $e');
    }
  }

  void toggle() => setLang(_lang == 'uz' ? 'ru' : 'uz');
}
