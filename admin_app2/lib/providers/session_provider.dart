import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/activity_log.dart';
import '../models/cash_session.dart';

/// Smena davomidagi to'lov turlari bo'yicha yig'indi.
class SessionSummary {
  final int cashSales;
  final int cardSales;
  final int debtSales;
  final int salesCount;
  const SessionSummary({
    this.cashSales = 0,
    this.cardSales = 0,
    this.debtSales = 0,
    this.salesCount = 0,
  });

  int get totalRevenue => cashSales + cardSales + debtSales;
}

/// Kassa smenasi provideri — ochish/yopish, kirim/chiqim.
class SessionProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CashSession? _current;
  List<CashSession> _history = [];
  bool _isLoading = false;

  CashSession? get current => _current;
  List<CashSession> get history => _history;
  bool get isLoading => _isLoading;
  bool get isOpen => _current != null && _current!.isOpen;

  /// Joriy ochiq smenani yuklash
  Future<void> loadCurrentSession() async {
    _isLoading = true;
    notifyListeners();
    try {
      final snap = await _firestore
          .collection('sessions')
          .where('status', isEqualTo: 'open')
          .limit(1)
          .get();
      _current = snap.docs.isNotEmpty
          ? CashSession.fromFirestore(snap.docs.first)
          : null;
    } catch (e) {
      debugPrint('Error loading session: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Smenalar tarixini yuklash
  Future<void> loadHistory() async {
    try {
      final snap = await _firestore
          .collection('sessions')
          .orderBy('openedAt', descending: true)
          .limit(100)
          .get();
      _history = snap.docs.map((d) => CashSession.fromFirestore(d)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading session history: $e');
    }
  }

  /// Smena ochish
  Future<bool> openSession(int openingCash, {String? cashierName}) async {
    if (isOpen) return false;
    try {
      final session = CashSession(
        openingCash: openingCash,
        openedAt: DateTime.now(),
        cashierName: cashierName,
      );
      final ref =
          await _firestore.collection('sessions').add(session.toFirestore());
      _current = CashSession(
        id: ref.id,
        openingCash: openingCash,
        openedAt: DateTime.now(),
        cashierName: cashierName,
      );
      notifyListeners();
      ActivityLog.record(
          action: 'OPEN_SESSION',
          entity: 'CashSession',
          entityId: ref.id,
          details: 'Boshlang\'ich: $openingCash');
      return true;
    } catch (e) {
      debugPrint('Error opening session: $e');
      return false;
    }
  }

  /// Kirim/chiqim qo'shish
  Future<bool> addMovement(String type, int amount, String reason) async {
    if (_current?.id == null) return false;
    try {
      final movement = CashMovement(
        type: type,
        amount: amount,
        reason: reason,
        createdAt: DateTime.now(),
      );
      final updated = [..._current!.movements, movement];
      await _firestore.collection('sessions').doc(_current!.id).update({
        'movements': updated.map((m) => m.toMap()).toList(),
      });
      _current = CashSession(
        id: _current!.id,
        openingCash: _current!.openingCash,
        openedAt: _current!.openedAt,
        cashierName: _current!.cashierName,
        movements: updated,
      );
      notifyListeners();
      ActivityLog.record(
          action: type == 'in' ? 'CASH_IN' : 'CASH_OUT',
          entity: 'CashSession',
          entityId: _current!.id,
          details: '$amount · $reason');
      return true;
    } catch (e) {
      debugPrint('Error adding movement: $e');
      return false;
    }
  }

  /// Smena davomidagi savdolarni to'lov turlari bo'yicha yig'ish.
  /// Aralash to'lovlar uchun har sotuvning AYNAN naqd/karta/nasiya qismini
  /// (`payments` map) hisoblaymiz — shuning uchun kutilgan naqd to'g'ri chiqadi.
  Future<SessionSummary> sessionSummary() async {
    if (_current == null) return const SessionSummary();
    try {
      final snap = await _firestore
          .collection('sales')
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(_current!.openedAt))
          .get();
      int cash = 0, card = 0, debt = 0;
      for (final doc in snap.docs) {
        final data = doc.data();
        final payments = data['payments'] as Map<String, dynamic>?;
        if (payments != null && payments.isNotEmpty) {
          cash += ((payments['cash'] ?? 0) as num).toInt();
          card += ((payments['card'] ?? 0) as num).toInt();
          debt += ((payments['debt'] ?? 0) as num).toInt();
        } else {
          // Eski yozuvlar (payments yo'q) — paymentMethod bo'yicha
          final m = (data['paymentMethod'] ?? 'cash') as String;
          final amt = ((data['totalAmount'] ?? 0) as num).toInt();
          if (m == 'card') {
            card += amt;
          } else if (m == 'debt') {
            debt += amt;
          } else {
            cash += amt;
          }
        }
      }
      return SessionSummary(
        cashSales: cash,
        cardSales: card,
        debtSales: debt,
        salesCount: snap.docs.length,
      );
    } catch (e) {
      debugPrint('Error session summary: $e');
      return const SessionSummary();
    }
  }

  /// Smena davomidagi naqd savdo (aralash to'lovning naqd qismi bilan).
  Future<int> _calcCashSales() async => (await sessionSummary()).cashSales;

  /// Kutilgan naqd (jonli hisob)
  Future<int> expectedCashNow() async {
    if (_current == null) return 0;
    final cashSales = await _calcCashSales();
    return _current!.openingCash +
        cashSales +
        _current!.movementsIn -
        _current!.movementsOut;
  }

  /// Smena yopish
  Future<CashSession?> closeSession(int countedCash) async {
    if (_current?.id == null) return null;
    try {
      final cashSales = await _calcCashSales();
      final expected = _current!.openingCash +
          cashSales +
          _current!.movementsIn -
          _current!.movementsOut;
      final difference = countedCash - expected;

      await _firestore.collection('sessions').doc(_current!.id).update({
        'status': 'closed',
        'closingCash': countedCash,
        'cashSales': cashSales,
        'expectedCash': expected,
        'difference': difference,
        'closedAt': FieldValue.serverTimestamp(),
      });

      final closed = CashSession(
        id: _current!.id,
        openingCash: _current!.openingCash,
        closingCash: countedCash,
        cashSales: cashSales,
        expectedCash: expected,
        difference: difference,
        status: 'closed',
        openedAt: _current!.openedAt,
        closedAt: DateTime.now(),
        cashierName: _current!.cashierName,
        movements: _current!.movements,
      );
      final sessionId = closed.id;
      _current = null;
      notifyListeners();
      ActivityLog.record(
          action: 'CLOSE_SESSION',
          entity: 'CashSession',
          entityId: sessionId,
          details: 'Farq: $difference');
      return closed;
    } catch (e) {
      debugPrint('Error closing session: $e');
      return null;
    }
  }
}
