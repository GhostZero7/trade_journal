import 'package:flutter/material.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // You can match the theme logic from dashboard_screen.dart or simplify
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFF00FF80) : const Color(0xFF00C853);
    final backgroundColor = isDark ? const Color(0xFF121212) : const Color(0xFFFAFAFA);
    final appBarColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: appBarColor, 
        title: Text('Analytics & Charts', style: TextStyle(color: primaryColor)),
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 80, color: primaryColor),
            const SizedBox(height: 16),
            Text('Analytics coming soon!', 
              style: TextStyle(
                color: textColor,
                fontSize: 20,
                fontWeight: FontWeight.w600
              )
            ),
            const SizedBox(height: 8),
            Text('Detailed charts and performance metrics will appear here.', 
              style: TextStyle(
                color: textColor.withOpacity(0.7),
                fontSize: 16
              )
            ),
          ],
        ),
      ),
    );
  }
}