import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// AuthProvider - hozircha oddiy placeholder
/// Google Sign-In keyinroq qo'shiladi
class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => currentUser != null;

  // Hozircha oddiy anonymous sign in (keyinroq Google qo'shamiz)
  Future<void> signInAnonymously() async {
    try {
      await _auth.signInAnonymously();
      notifyListeners();
    } catch (e) {
      debugPrint('Sign In Error: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    notifyListeners();
  }
}
