import 'package:flutter/material.dart';

class AllTradesScreen extends StatelessWidget {
  const AllTradesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF9F9F9),

      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        title: Text(
          "All Trades",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? const Color(0xFF00FF80) : const Color(0xFF00C853),
          ),
        ),
        iconTheme: IconThemeData(
            color: isDark ? Colors.white : Colors.black87),
      ),

      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: demoTrades.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final trade = demoTrades[index];
          final bool isWin = trade['result'] == "Win";

          return Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isWin
                    ? (isDark ? const Color(0xFF00FF80) : const Color(0xFF00C853))
                    : Colors.redAccent.withOpacity(.7),
                width: 1.3,
              ),
            ),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Pair / Result row ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      trade['pair'],
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      trade['result'],
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isWin ? Colors.greenAccent : Colors.redAccent,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                Text(
                  "Amount: ZMW ${trade['amount']}",
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  trade['date'],
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[500] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}


// ---------------------------
// Dummy data (replace later)
// ---------------------------
final List<Map<String, dynamic>> demoTrades = [
  {
    "pair": "EUR/USD",
    "result": "Win",
    "amount": 150,
    "date": "2025-01-03",
  },
  {
    "pair": "BTC/USDT",
    "result": "Loss",
    "amount": -25,
    "date": "2025-01-02",
  },
  {
    "pair": "GBP/JPY",
    "result": "Win",
    "amount": 320,
    "date": "2025-01-01",
  },
  {
    "pair": "XAU/USD",
    "result": "Win",
    "amount": 100,
    "date": "2024-12-31",
  },
];
