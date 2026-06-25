import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'app_strings.dart';

/// Til (UZ/RU) provideri. Tanlangan til Firestore settings/app da saqlanadi.
class LocaleProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _lang = 'uz'; // 'uz' yoki 'ru'
  String get lang => _lang;
  bool get isUz => _lang == 'uz';

  /// Kalit bo'yicha tarjima. Topilmasa kalitning o'zini qaytaradi.
  String t(String key) {
    final entry = AppStrings.values[key];
    if (entry == null) return key;
    return entry[_lang] ?? entry['uz'] ?? key;
  }

  Future<void> load() async {
    try {
      final doc = await _firestore.collection('settings').doc('app').get();
      final saved = doc.data()?['language'] as String?;
      if (saved == 'uz' || saved == 'ru') {
        _lang = saved!;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading language: $e');
    }
  }

  Future<void> setLang(String lang) async {
    if (lang != 'uz' && lang != 'ru') return;
    _lang = lang;
    notifyListeners();
    try {
      await _firestore
          .collection('settings')
          .doc('app')
          .set({'language': lang}, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving language: $e');
    }
  }

  void toggle() => setLang(_lang == 'uz' ? 'ru' : 'uz');

  /// To'lov usuli kalitini lokalizatsiya qilingan yorliqqa aylantiradi.
  String payLabel(String method) {
    switch (method) {
      case 'card':
        return t('pos.card');
      case 'debt':
        return t('pos.debt');
      case 'mixed':
        return t('pos.mixed');
      default:
        return t('pos.cash');
    }
  }
}
