// Auth service
import 'package:firebase_auth/firebase_auth.dart';
import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Register a new user and create Firestore profile
  Future<User?> signUp(String email, String password, String name) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = cred.user;
      if (user != null) {
        await FirestoreService(uid: user.uid)
            .createUserProfile(name, email); // 🔥 auto setup
      }
      return user;
    } on FirebaseAuthException catch (e) {
      print('Signup error: \\${e.message}');
      return null;
    }
  }

  /// Log in existing user
  Future<User?> signIn(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // update last login timestamp
      await FirestoreService(uid: cred.user!.uid).updateLastLogin();
      return cred.user;
    } on FirebaseAuthException catch (e) {
      print('Login error: \\${e.message}');
      return null;
    }
  }

  Future<void> signOut() async => await _auth.signOut();
}
