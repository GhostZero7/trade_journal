import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TradesProvider with ChangeNotifier {
  final List<Map<String, dynamic>> _trades = [];
  final _firestore = FirebaseFirestore.instance;
  bool isLoading = false;

  List<Map<String, dynamic>> get trades => _trades;

  Future<void> fetchTrades() async {
    isLoading = true;
    notifyListeners();

    final uid = FirebaseAuth.instance.currentUser!.uid;

    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('trades')
        .orderBy('createdAt', descending: true)
        .get();

    _trades.clear();

    for (var doc in snapshot.docs) {
      _trades.add({
        'id': doc.id,
        ...doc.data(),
      });
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> addTrade(Map<String, dynamic> trade) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('trades')
        .add({
      ...trade,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await fetchTrades();
  }

  Future<void> deleteTrade(String id) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('trades')
        .doc(id)
        .delete();

    _trades.removeWhere((t) => t['id'] == id);
    notifyListeners();
  }
}
