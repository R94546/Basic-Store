import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/debt.dart';

/// Nasiya (qarz) provideri
class DebtProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Debt> _debts = [];
  bool _isLoading = false;

  List<Debt> get debts => _debts;
  bool get isLoading => _isLoading;

  /// Umumiy qaytarilmagan qarz
  int get totalOutstanding =>
      _debts.fold(0, (s, d) => s + d.remaining);

  /// Ochiq (to'lanmagan) qarzlar
  List<Debt> get openDebts => _debts.where((d) => !d.isPaid).toList();

  List<Debt> byClient(String clientId) =>
      _debts.where((d) => d.clientId == clientId).toList();

  int outstandingByClient(String clientId) =>
      byClient(clientId).fold(0, (s, d) => s + d.remaining);

  Future<void> loadDebts() async {
    _isLoading = true;
    notifyListeners();
    try {
      final snap = await _firestore
          .collection('debts')
          .orderBy('createdAt', descending: true)
          .get();
      _debts = snap.docs.map((d) => Debt.fromFirestore(d)).toList();
    } catch (e) {
      debugPrint('Error loading debts: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Yangi qarz qo'shish (POS savdosidan)
  Future<bool> addDebt(Debt debt) async {
    try {
      final ref = await _firestore.collection('debts').add(debt.toFirestore());
      _debts.insert(0, Debt(
        id: ref.id,
        clientId: debt.clientId,
        clientName: debt.clientName,
        saleId: debt.saleId,
        saleNumber: debt.saleNumber,
        amount: debt.amount,
        payments: debt.payments,
        dueDate: debt.dueDate,
        createdAt: DateTime.now(),
      ));
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error adding debt: $e');
      return false;
    }
  }

  /// Qarzga to'lov qo'shish
  Future<bool> payDebt(String debtId, int amount) async {
    final i = _debts.indexWhere((d) => d.id == debtId);
    if (i == -1) return false;
    try {
      final payment = DebtPayment(amount: amount, createdAt: DateTime.now());
      final updated = [..._debts[i].payments, payment];
      await _firestore.collection('debts').doc(debtId).update({
        'payments': updated.map((p) => p.toMap()).toList(),
      });
      final d = _debts[i];
      _debts[i] = Debt(
        id: d.id,
        clientId: d.clientId,
        clientName: d.clientName,
        saleId: d.saleId,
        saleNumber: d.saleNumber,
        amount: d.amount,
        payments: updated,
        dueDate: d.dueDate,
        createdAt: d.createdAt,
      );
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error paying debt: $e');
      return false;
    }
  }
}
