import 'package:cloud_firestore/cloud_firestore.dart';

/// Qarzga to'lov
class DebtPayment {
  final int amount;
  final DateTime createdAt;

  DebtPayment({required this.amount, required this.createdAt});

  factory DebtPayment.fromMap(Map<String, dynamic> map) => DebtPayment(
        amount: map['amount'] ?? 0,
        createdAt:
            (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'amount': amount,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

/// Nasiya (qarz) yozuvi
class Debt {
  final String? id;
  final String clientId;
  final String clientName;
  final String? saleId;
  final int? saleNumber;
  final int amount;            // Umumiy qarz
  final List<DebtPayment> payments;
  final DateTime? dueDate;     // Qaytarish muddati
  final DateTime createdAt;

  Debt({
    this.id,
    required this.clientId,
    required this.clientName,
    this.saleId,
    this.saleNumber,
    required this.amount,
    this.payments = const [],
    this.dueDate,
    required this.createdAt,
  });

  int get paid => payments.fold(0, (s, p) => s + p.amount);
  int get remaining => (amount - paid).clamp(0, amount);
  bool get isPaid => remaining <= 0;
  bool get isOverdue =>
      !isPaid && dueDate != null && dueDate!.isBefore(DateTime.now());
  String get status => isPaid ? 'paid' : (isOverdue ? 'overdue' : 'open');

  factory Debt.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Debt(
      id: doc.id,
      clientId: data['clientId'] ?? '',
      clientName: data['clientName'] ?? '',
      saleId: data['saleId'],
      saleNumber: data['saleNumber'],
      amount: data['amount'] ?? 0,
      payments: (data['payments'] as List<dynamic>?)
              ?.map((e) => DebtPayment.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      dueDate: (data['dueDate'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'clientId': clientId,
      'clientName': clientName,
      if (saleId != null) 'saleId': saleId,
      if (saleNumber != null) 'saleNumber': saleNumber,
      'amount': amount,
      'payments': payments.map((p) => p.toMap()).toList(),
      if (dueDate != null) 'dueDate': Timestamp.fromDate(dueDate!),
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
