import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TradeService {
  final _db = FirebaseFirestore.instance;

  Future<void> addTrade({
    required String symbol,
    required String type,
    required double amount,
    required String result,
    required double profit,
    required String notes,
    String? screenshotUrl, // Add this parameter
  }) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    await _db.collection('trades').add({
      'userId': uid,
      'symbol': symbol,
      'type': type,
      'amount': amount,
      'result': result,
      'profit': profit,
      'notes': notes,
      'screenshotUrl': screenshotUrl, // Add this field
      'createdAt': Timestamp.now(),
    });
  }

  Stream<QuerySnapshot> getUserTrades() {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return _db
        .collection('trades')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}