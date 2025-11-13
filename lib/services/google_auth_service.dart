import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firestore_service.dart';

class GoogleAuthService {
  final _googleSignIn = GoogleSignIn();
  final _auth = FirebaseAuth.instance;

  Future<User?> signInWithGoogle() async {
    try {
      // Begin interactive sign in process
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      // Obtain the auth details from the request
      final googleAuth = await googleUser.authentication;

      // Create a credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with Google credential
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      // Create user profile in Firestore if new
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        await FirestoreService(uid: user!.uid)
            .createUserProfile(user.displayName ?? '', user.email ?? '');
      } else {
        await FirestoreService(uid: user!.uid).updateLastLogin();
      }

      return user;
    } catch (e) {
      print('Google sign-in error: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
