// Dashboard screen
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../widgets/cards/stat_card.dart';
import '../../../services/firestore_service.dart';
import '../../../widgets/cards/stat_card.dart';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  String userName = "";
  String email = "";
  int totalTrades = 0;
  double totalProfit = 0.0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadTradeStats();
  }

  Future<void> _loadUserData() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      setState(() {
        userName = doc.data()?['name'] ?? 'Trader';
        email = doc.data()?['email'] ?? '';
      });
    }
  }

  Future<void> _loadTradeStats() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final trades = await _db
        .collection('trades')
        .doc(uid)
        .collection('user_trades')
        .get();

    setState(() {
      totalTrades = trades.docs.length;
      totalProfit = trades.docs.fold<double>(
        0.0,
        (sum, doc) => sum + double.tryParse(doc['profit'].toString())!,
      );
    });
  }

  void _logout() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: AppColors.primaryDark,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          )
        ],
      ),
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hi, $userName 👋', style: AppTextStyles.heading1),
            Text(email, style: AppTextStyles.bodySecondary),
            const SizedBox(height: 24),

            // --- STATS CARDS ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                StatCard(
                  title: 'Total Trades',
                  value: totalTrades.toString(),
                  icon: Icons.show_chart,
                ),
                StatCard(
                  title: 'Total Profit',
                  value: '\$${totalProfit.toStringAsFixed(2)}',
                  icon: Icons.monetization_on,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // --- RECENT TRADES ---
            Text('Recent Trades', style: AppTextStyles.heading2),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _db
                    .collection('trades')
                    .doc(_auth.currentUser!.uid)
                    .collection('user_trades')
                    .orderBy('timestamp', descending: true)
                    .limit(5)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text('No trades yet.'),
                    );
                  }

                  final trades = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: trades.length,
                    itemBuilder: (context, index) {
                      final trade = trades[index];
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          leading: const Icon(Icons.trending_up,
                              color: AppColors.primary),
                          title: Text(trade['symbol']),
                          subtitle: Text(
                              'Profit: \$${trade['profit']}  |  Lot: ${trade['lotSize']}'),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
