import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/cash_session.dart';

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
      return true;
    } catch (e) {
      debugPrint('Error adding movement: $e');
      return false;
    }
  }

  /// Smena davomidagi naqd savdoni hisoblash
  Future<int> _calcCashSales() async {
    if (_current == null) return 0;
    try {
      final snap = await _firestore
          .collection('sales')
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(_current!.openedAt))
          .get();
      int total = 0;
      for (final doc in snap.docs) {
        final data = doc.data();
        if ((data['paymentMethod'] ?? 'cash') == 'cash') {
          total += ((data['totalAmount'] ?? 0) as num).toInt();
        }
      }
      return total;
    } catch (e) {
      debugPrint('Error calc cash sales: $e');
      return 0;
    }
  }

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
      _current = null;
      notifyListeners();
      return closed;
    } catch (e) {
      debugPrint('Error closing session: $e');
      return null;
    }
  }
}
