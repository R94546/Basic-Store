import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/client.dart';

/// Mijozlar provideri
class ClientProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Client> _clients = [];
  bool _isLoading = false;

  List<Client> get clients => _clients;
  bool get isLoading => _isLoading;

  Future<void> loadClients() async {
    _isLoading = true;
    notifyListeners();
    try {
      final snap = await _firestore
          .collection('clients')
          .orderBy('createdAt', descending: true)
          .get();
      _clients = snap.docs.map((d) => Client.fromFirestore(d)).toList();
    } catch (e) {
      debugPrint('Error loading clients: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Client? findByName(String name) {
    final lower = name.toLowerCase().trim();
    for (final c in _clients) {
      if (c.name.toLowerCase().trim() == lower) return c;
    }
    return null;
  }

  Future<Client?> addClient(Client client) async {
    try {
      final ref = await _firestore.collection('clients').add(client.toFirestore());
      final created = Client(
        id: ref.id,
        name: client.name,
        phone: client.phone,
        address: client.address,
        note: client.note,
        createdAt: DateTime.now(),
      );
      _clients.insert(0, created);
      notifyListeners();
      return created;
    } catch (e) {
      debugPrint('Error adding client: $e');
      return null;
    }
  }

  Future<bool> updateClient(Client client) async {
    if (client.id == null) return false;
    try {
      await _firestore.collection('clients').doc(client.id).update({
        'name': client.name,
        if (client.phone != null) 'phone': client.phone,
        if (client.address != null) 'address': client.address,
        if (client.note != null) 'note': client.note,
      });
      final i = _clients.indexWhere((c) => c.id == client.id);
      if (i != -1) _clients[i] = client;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating client: $e');
      return false;
    }
  }

  /// Nom bo'yicha topadi yoki yangi yaratadi (POS qarz uchun).
  Future<Client?> getOrCreateByName(String name, {String? phone}) async {
    if (_clients.isEmpty) await loadClients();
    final existing = findByName(name);
    if (existing != null) return existing;
    return addClient(Client(name: name, phone: phone, createdAt: DateTime.now()));
  }
}
