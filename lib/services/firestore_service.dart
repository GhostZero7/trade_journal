// Firebase service
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String uid;

  FirestoreService({required this.uid});

  Future<void> createUserProfile(String name, String email) async {
    final userDoc = _db.collection('users').doc(uid);

    await userDoc.set({
      'name': name,
      'email': email,
      'joinedAt': FieldValue.serverTimestamp(),
      'lastLogin': FieldValue.serverTimestamp(),
    });

    // default settings
    await userDoc.collection('settings').doc('profile').set({
      'theme': 'light',
      'notifications': true,
    });
  }

  Future<void> updateLastLogin() async {
    await _db.collection('users').doc(uid).update({
      'lastLogin': FieldValue.serverTimestamp(),
    });
  }
}
