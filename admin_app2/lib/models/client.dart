import 'package:cloud_firestore/cloud_firestore.dart';

/// Mijoz (nasiya/qarz uchun)
class Client {
  final String? id;
  final String name;
  final String? phone;
  final String? address;
  final String? note;
  final DateTime createdAt;

  Client({
    this.id,
    required this.name,
    this.phone,
    this.address,
    this.note,
    required this.createdAt,
  });

  factory Client.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Client(
      id: doc.id,
      name: data['name'] ?? '',
      phone: data['phone'],
      address: data['address'],
      note: data['note'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      if (phone != null) 'phone': phone,
      if (address != null) 'address': address,
      if (note != null) 'note': note,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  Client copyWith({String? name, String? phone, String? address, String? note}) {
    return Client(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      note: note ?? this.note,
      createdAt: createdAt,
    );
  }
}
