import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// AuthProvider - Email/parol orqali autentifikatsiya
class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => _auth.currentUser != null;
  Stream<User?> get authState => _auth.authStateChanges();

  /// Email/parol orqali kirish.
  /// Muvaffaqiyatli bo'lsa null qaytaradi, aks holda xato matnini.
  Future<String?> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      notifyListeners();
      switch (e.code) {
        case 'invalid-credential':
        case 'wrong-password':
        case 'user-not-found':
        case 'invalid-email':
          return "Email yoki parol noto'g'ri";
        default:
          return e.message ?? "Email yoki parol noto'g'ri";
      }
    } catch (e) {
      debugPrint('Sign In Error: $e');
      notifyListeners();
      return "Email yoki parol noto'g'ri";
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    notifyListeners();
  }
}
