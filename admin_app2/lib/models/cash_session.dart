import 'package:cloud_firestore/cloud_firestore.dart';

/// Kassadan kirim/chiqim harakati
class CashMovement {
  final String type; // 'in' (kirim) yoki 'out' (chiqim)
  final int amount;
  final String reason;
  final DateTime createdAt;

  CashMovement({
    required this.type,
    required this.amount,
    required this.reason,
    required this.createdAt,
  });

  bool get isIn => type == 'in';

  factory CashMovement.fromMap(Map<String, dynamic> map) {
    return CashMovement(
      type: map['type'] ?? 'in',
      amount: map['amount'] ?? 0,
      reason: map['reason'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'amount': amount,
      'reason': reason,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

/// Kassa smenasi (ochilish/yopilish)
class CashSession {
  final String? id;
  final int openingCash;       // Ochilishdagi naqd
  final int? closingCash;      // Yopilishda sanab chiqilgan naqd
  final int? cashSales;        // Smena davomidagi naqd savdo
  final int? expectedCash;     // Kutilgan naqd
  final int? difference;       // Farq (sanalgan - kutilgan)
  final String status;         // 'open' yoki 'closed'
  final DateTime openedAt;
  final DateTime? closedAt;
  final String? cashierName;
  final List<CashMovement> movements;

  CashSession({
    this.id,
    required this.openingCash,
    this.closingCash,
    this.cashSales,
    this.expectedCash,
    this.difference,
    this.status = 'open',
    required this.openedAt,
    this.closedAt,
    this.cashierName,
    this.movements = const [],
  });

  bool get isOpen => status == 'open';

  int get movementsIn =>
      movements.where((m) => m.isIn).fold(0, (s, m) => s + m.amount);
  int get movementsOut =>
      movements.where((m) => !m.isIn).fold(0, (s, m) => s + m.amount);

  factory CashSession.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CashSession(
      id: doc.id,
      openingCash: data['openingCash'] ?? 0,
      closingCash: data['closingCash'],
      cashSales: data['cashSales'],
      expectedCash: data['expectedCash'],
      difference: data['difference'],
      status: data['status'] ?? 'open',
      openedAt: (data['openedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      closedAt: (data['closedAt'] as Timestamp?)?.toDate(),
      cashierName: data['cashierName'],
      movements: (data['movements'] as List<dynamic>?)
              ?.map((e) => CashMovement.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'openingCash': openingCash,
      if (closingCash != null) 'closingCash': closingCash,
      if (cashSales != null) 'cashSales': cashSales,
      if (expectedCash != null) 'expectedCash': expectedCash,
      if (difference != null) 'difference': difference,
      'status': status,
      'openedAt': Timestamp.fromDate(openedAt),
      if (closedAt != null) 'closedAt': Timestamp.fromDate(closedAt!),
      if (cashierName != null) 'cashierName': cashierName,
      'movements': movements.map((m) => m.toMap()).toList(),
    };
  }
}
