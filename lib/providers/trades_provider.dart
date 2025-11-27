import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TradesProvider with ChangeNotifier {
  final List<Map<String, dynamic>> _trades = [];
  final _firestore = FirebaseFirestore.instance;
  bool isLoading = false;

  List<Map<String, dynamic>> get trades => _trades;

  // Utility function to format timestamp data for display
  String _formatTimestamp(dynamic ts) {
    if (ts is Timestamp) {
      return ts.toDate().toString(); // Return as a standard date string or customize as needed
    }
    return ts?.toString() ?? 'N/A';
  }

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
      // Data retrieved from Firestore is Map<String, dynamic>
      final data = doc.data();

      _trades.add({
        'id': doc.id,
        ...data,
        // Ensure createdAt is always a Timestamp if it exists, otherwise null/String
        'createdAt': data['createdAt'] is Timestamp ? data['createdAt'] : _formatTimestamp(data['createdAt']),
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
      // Use server timestamp for creation
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Refresh data to include the new trade
    await fetchTrades();
  }

  Future<void> updateTrade(String id, Map<String, dynamic> trade) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    
    // We update the trade data, but ensure 'createdAt' is NOT overwritten 
    // unless explicitly needed. Firestore set() or update() will handle this.
    // Since the Map passed from the screen already contains the original 'createdAt'
    // or a new one, we can just pass the map.
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('trades')
        .doc(id)
        .update(trade); 

    // Refresh data to update the local list
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