import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Admin amallari jurnali (audit log) — kim, qachon, nima qildi.
/// Firestore `activity_logs` to'plamiga yoziladi.
class ActivityLog {
  final String id;
  final String action; // SALE_CONFIRM, STOCK_IN, PRODUCT_CREATE ...
  final String entity; // Sale, StockIn, Product, CashSession ...
  final String? entityId;
  final String? details; // o'qiladigan izoh
  final String userEmail;
  final DateTime createdAt;

  ActivityLog({
    required this.id,
    required this.action,
    required this.entity,
    this.entityId,
    this.details,
    required this.userEmail,
    required this.createdAt,
  });

  factory ActivityLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ActivityLog(
      id: doc.id,
      action: data['action'] ?? '',
      entity: data['entity'] ?? '',
      entityId: data['entityId'],
      details: data['details'],
      userEmail: data['userEmail'] ?? '—',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Bitta amalni jurnalga yozish. Joriy foydalanuvchi emailini o'zi oladi —
  /// chaqirish joyida context/provider shart emas. Xato bo'lsa jim o'tadi
  /// (log yozilmasligi asosiy amalni buzmasligi kerak).
  static Future<void> record({
    required String action,
    required String entity,
    String? entityId,
    String? details,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('activity_logs').add({
        'action': action,
        'entity': entity,
        if (entityId != null) 'entityId': entityId,
        if (details != null) 'details': details,
        'userEmail': FirebaseAuth.instance.currentUser?.email ?? '—',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // jurnal yozilmasa ham asosiy amal davom etadi
    }
  }
}

/// Amal turlari uchun ko'rinish (yorliq + rang).
class LogActionMeta {
  final String uz;
  final String ru;
  final Color color;
  final IconData icon;
  const LogActionMeta(this.uz, this.ru, this.color, this.icon);
}

const Color _green = Color(0xFF4CAF50);
const Color _blue = Color(0xFF2563EB);
const Color _red = Color(0xFFE53935);
const Color _orange = Color(0xFFFF9800);
const Color _gray = Color(0xFF757575);
const Color _violet = Color(0xFF8B5CF6);

const Map<String, LogActionMeta> kLogActions = {
  'LOGIN': LogActionMeta('Tizimga kirish', 'Вход в систему', _violet, Icons.login),
  'LOGOUT': LogActionMeta('Tizimdan chiqish', 'Выход', _gray, Icons.logout),
  'SALE_CONFIRM': LogActionMeta('Sotuv', 'Продажа', _green, Icons.point_of_sale),
  'STOCK_IN': LogActionMeta('Kirim (prixod)', 'Приход', _green, Icons.arrow_downward),
  'PRODUCT_CREATE': LogActionMeta('Mahsulot yaratildi', 'Товар создан', _green, Icons.add_box),
  'PRODUCT_UPDATE': LogActionMeta('Mahsulot o\'zgartirildi', 'Товар изменён', _blue, Icons.edit),
  'PRODUCT_DELETE': LogActionMeta('Mahsulot o\'chirildi', 'Товар удалён', _red, Icons.delete),
  'BARCODE_BIND': LogActionMeta('Shtrix biriktirildi', 'Штрих привязан', _orange, Icons.qr_code),
  'OPEN_SESSION': LogActionMeta('Kassa ochildi', 'Касса открыта', _green, Icons.lock_open),
  'CLOSE_SESSION': LogActionMeta('Kassa yopildi', 'Касса закрыта', _gray, Icons.lock),
  'CASH_IN': LogActionMeta('Naqd kirim', 'Внесение', _green, Icons.add),
  'CASH_OUT': LogActionMeta('Naqd chiqim', 'Изъятие', _orange, Icons.remove),
};

/// Entity filtrlari (kalit, uz, ru).
const List<(String, String, String)> kLogEntities = [
  ('', 'Hammasi', 'Все'),
  ('Sale', 'Sotuvlar', 'Продажи'),
  ('StockIn', 'Kirim', 'Приход'),
  ('Product', 'Mahsulotlar', 'Товары'),
  ('CashSession', 'Kassa', 'Касса'),
];
