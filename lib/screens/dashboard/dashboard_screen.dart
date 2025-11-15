// lib/screens/dashboard/dashboard_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../core/theme/theme_service.dart';
import '../settings/settings_screen.dart';
import '../analytics/analytics_screen.dart';
import '../trades/trades_screen.dart';

// ==============================================================
// 🎯 NEW IMPORTS FOR REAL SCREENS
// (Assuming screens are located in sibling directories like ../profile, ../analytics, etc.)
// ProfileScreen is the file you provided.
import '../profile/profile_screen.dart'; 
// Assuming you have these other files (replace placeholder definitions)



// --- THEME MANAGER ---
class DashboardTheme {
// ... (rest of DashboardTheme class content)
  final Color primary;
  final Color accent;
  final Color secondary;
  final Color background;
  final Color cardDark;
  final Color textLight;
  final Color textFaded;
  final Color success;
  final Color error;

  const DashboardTheme({
    required this.primary,
    required this.accent,
    required this.secondary,
    required this.background,
    required this.cardDark,
    required this.textLight,
    required this.textFaded,
    required this.success,
    required this.error,
  });

  // Dark theme (your original design)
  static DashboardTheme dark = DashboardTheme(
    primary: const Color(0xFF00FF80), // Neon Green/Teal
    accent: const Color(0xFF40C4FF),  // Bright Blue for highlights
    secondary: const Color(0xFFFF4545), // Bright Red for loss
    background: const Color(0xFF121212), // Deep Dark Background
    cardDark: const Color(0xFF1E1E1E), // Slightly Lighter Card
    textLight: const Color(0xFFE0E0E0), // Light Gray Text
    textFaded: const Color(0xFF888888), // Faded Grey Text
    success: const Color(0xFF00FF80),
    error: const Color(0xFFFF4545),
  );

  // Light theme (matching your dark theme design)
  static DashboardTheme light = DashboardTheme(
    primary: const Color(0xFF00C853), // Slightly darker green for light theme
    accent: const Color(0xFF2979FF),  // Deeper blue for light theme
    secondary: const Color(0xFFFF1744), // Bright Red for loss
    background: const Color(0xFFFAFAFA), // Light background
    cardDark: const Color(0xFFFFFFFF), // White cards
    textLight: const Color(0xFF212121), // Dark text
    textFaded: const Color(0xFF757575), // Grey text
    success: const Color(0xFF00C853),
    error: const Color(0xFFFF1744),
  );
}

// --- CONSTANTS ---
const double kBorderRadius = 12.0;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  String userName = '';
  String email = '';
  int totalTrades = 0;
  double totalProfit = 0.0;

  // Advanced stats
  double winRate = 0.0;
  double avgProfit = 0.0;
  double bestTrade = 0.0;
  double worstTrade = 0.0;

  // Calendar/profit map
  Map<DateTime, bool> _profitDays = {};
  DateTime _calendarDate = DateTime.now();

  // Bottom nav
  int _selectedIndex = 0;
  final GlobalKey _bottomNavKey = GlobalKey(); // Added for positioning logic

  // Theme
  bool _isDarkTheme = true;
  DashboardTheme get _theme => _isDarkTheme ? DashboardTheme.dark : DashboardTheme.light;

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
    _loadEverything();
  }

  Future<void> _loadThemePreference() async {
    // You can load from shared preferences or use system theme
    final brightness = MediaQuery.of(context).platformBrightness;
    setState(() {
      _isDarkTheme = brightness == Brightness.dark;
    });
  }

  Future<void> _loadEverything() async {
    await _loadUserData();
    await _computeTradeStats();
    await _loadProfitCalendar();
  }

  // ============================
  // Load basic user profile
  // ============================
  Future<void> _loadUserData() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          userName = (data['name'] ?? 'Trader') as String;
          email = (data['email'] ?? '') as String;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  // ============================
  // Compute aggregated trade stats
  // ============================
  Future<void> _computeTradeStats() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      final snapshot = await _db
          .collection('trades')
          .doc(uid)
          .collection('user_trades')
          .get();

      final docs = snapshot.docs;
      int tradesCount = docs.length;
      double profitSum = 0.0;
      int wins = 0;
      double best = double.negativeInfinity;
      double worst = double.infinity;

      for (final d in docs) {
        final profit = double.tryParse(d['profit'].toString()) ?? 0.0;
        profitSum += profit;
        if (profit > 0) wins++;
        if (profit > best) best = profit;
        if (profit < worst) worst = profit;
      }

      setState(() {
        totalTrades = tradesCount;
        totalProfit = profitSum;
        winRate = tradesCount == 0 ? 0.0 : (wins / tradesCount) * 100.0;
        avgProfit = tradesCount == 0 ? 0.0 : profitSum / tradesCount;
        bestTrade = best == double.negativeInfinity ? 0.0 : best;
        worstTrade = worst == double.infinity ? 0.0 : worst;
      });
    } catch (e) {
      print('Error computing trade stats: $e');
    }
  }

  // ============================
  // Build a calendar of profitable days
  // ============================
  Future<void> _loadProfitCalendar() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      final snapshot = await _db
          .collection('trades')
          .doc(uid)
          .collection('user_trades')
          .get();

      final Map<DateTime, bool> map = {};
      for (final d in snapshot.docs) {
        final ts = d['timestamp'] as Timestamp?;
        final profit = double.tryParse(d['profit'].toString()) ?? 0.0;
        if (ts == null) continue;
        final dt = ts.toDate();
        final day = DateTime(dt.year, dt.month, dt.day);
        
        if (map.containsKey(day)) {
          map[day] = map[day]! || profit > 0;
        } else {
          map[day] = profit > 0;
        }
      }

      setState(() => _profitDays = map);
    } catch (e) {
      print('Error loading profit calendar: $e');
    }
  }

  // ============================
  // Logout
  // ============================
  Future<void> _logout() async {
    await _auth.signOut();
    if (mounted) Navigator.of(context).pushReplacementNamed('/login');
  }

  // ============================
  // Navigation & Indicator Helpers
  // ============================
  void _onNavTap(int idx) {
    // Only navigate if index is not 0 (Home)
    if (idx == 0) {
      setState(() => _selectedIndex = idx);
      // Stay on Dashboard
    } else if (idx == 1) {
      setState(() => _selectedIndex = idx); // Update indicator immediately
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
      ).then((_) {
        // Reset to home when returning from another screen
        if(mounted) setState(() => _selectedIndex = 0); 
      });
    } else if (idx == 2) {
      setState(() => _selectedIndex = idx); // Update indicator immediately
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
      ).then((_) {
        // Reset to home when returning from another screen
        if(mounted) setState(() => _selectedIndex = 0);
      });
    }
  }
  
  // Custom logic to calculate the horizontal offset for the indicator.
  double _getIndicatorXOffset(int index, double screenWidth) {
    // We have 3 main navigational areas (Home, Stats, Profile) and one FAB area.
    // screenWidth is divided into 4 conceptual slots: [Home] [FAB] [Stats] [Profile]
    final itemWidth = screenWidth / 4.0;
    const indicatorSize = 48.0; // Corresponds to the width of the Container/nav item

    switch (index) {
      case 0: // Home (1st slot)
        return (itemWidth / 2.0) - (indicatorSize / 2.0); 
      case 1: // Stats (3rd slot)
        // Center of the 3rd slot: itemWidth * 2.5
        return (itemWidth * 2.5) - (indicatorSize / 2.0); 
      case 2: // Profile (4th slot)
        // Center of the 4th slot: itemWidth * 3.5
        return (itemWidth * 3.5) - (indicatorSize / 2.0); 
      default:
        // Set off-screen or to the first item if index is invalid/FAB
        return -indicatorSize; 
    }
  }

  // ============================
  // UI - small reusable stat card
  // ============================
  Widget _smallStat({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
    Color? borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _theme.cardDark,
        borderRadius: BorderRadius.circular(kBorderRadius),
        border: Border.all(
          color: borderColor ?? _theme.cardDark,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isDarkTheme ? 0.3 : 0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 8),
              Text(label,
                  style: AppTextStyles.bodySecondary.copyWith(
                      fontSize: 14, color: _theme.textFaded, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 10),
          Text(value, 
            style: AppTextStyles.heading2.copyWith(
              color: iconColor,
              fontWeight: FontWeight.w800,
              fontSize: 24,
            ),
          ),
        ],
      ),
    );
  }

  // ============================
  // Calendar widget
  // ============================
  Widget _buildMiniCalendar() {
    final now = _calendarDate;
    final first = DateTime(now.year, now.month, 1);
    final last = DateTime(now.year, now.month + 1, 0);
    final days = last.day;
    final startWeekday = first.weekday;

    final List<Widget> cells = [];

    for (int i = 1; i < startWeekday; i++) {
      cells.add(const SizedBox());
    }

    for (int d = 1; d <= days; d++) {
      final date = DateTime(now.year, now.month, d);
      final profitable = _profitDays[date] ?? false;
      final isToday = DateTime.now().year == date.year &&
          DateTime.now().month == date.month &&
          DateTime.now().day == date.day;

      cells.add(
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                d.toString(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isToday ? FontWeight.w900 : FontWeight.w600,
                  color: isToday ? _theme.accent : _theme.textLight,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: profitable ? _theme.success : _theme.textFaded.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
              )
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _theme.cardDark,
        borderRadius: BorderRadius.circular(kBorderRadius),
        border: Border.all(
          color: _theme.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _calendarNavButton(Icons.chevron_left, () {
                setState(() {
                  _calendarDate = DateTime(_calendarDate.year, _calendarDate.month - 1);
                });
                _loadProfitCalendar();
              }),
              Text('${_monthName(_calendarDate.month)} ${_calendarDate.year}',
                  style: AppTextStyles.heading2.copyWith(color: _theme.textLight, fontWeight: FontWeight.w700)),
              _calendarNavButton(Icons.chevron_right, () {
                setState(() {
                  _calendarDate = DateTime(_calendarDate.year, _calendarDate.month + 1);
                });
                _loadProfitCalendar();
              }),
            ],
          ),

          const SizedBox(height: 12),

          // Weekday headings
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              'M', 'T', 'W', 'T', 'F', 'S', 'S'
            ].map((day) => Text(day, style: AppTextStyles.bodySecondary.copyWith(
              color: _theme.textFaded, fontWeight: FontWeight.w700, fontSize: 13
            ))).toList(),
          ),

          const SizedBox(height: 8),

          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.0,
            children: cells,
          ),
        ],
      ),
    );
  }

  Widget _calendarNavButton(IconData icon, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        color: _theme.cardDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _theme.textFaded.withOpacity(0.2)),
      ),
      child: IconButton(
        icon: Icon(icon, color: _theme.textLight, size: 20),
        onPressed: onPressed,
      ),
    );
  }

  String _monthName(int m) {
    const months = [
      'January','February','March','April','May','June',
      'July','August','September','October','November','December'
    ];
    return months[m - 1];
  }

  // =============================
  // NAV ITEM WIDGET (SIMPLIFIED FOR CUSTOM INDICATOR)
  // =============================
  Widget _navItem({required int index, required IconData icon, required String label}) {
    final bool active = _selectedIndex == index;
    // Icon color flips to cardDark/white when active to contrast with the indicator
    final Color iconColor = active ? _theme.cardDark : _theme.textFaded; 

    return GestureDetector(
      onTap: () => _onNavTap(index),
      behavior: HitTestBehavior.opaque, // Ensures the entire area is tappable
      child: Container(
        // Set a fixed width for alignment calculation
        width: 48, 
        height: 70,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: active ? _theme.primary : _theme.textFaded,
                fontWeight: active ? FontWeight.bold : FontWeight.normal
              ),
            ),
          ],
        ),
      ),
    );
  }


  // ============================
  // Scaffold UI
  // ============================
  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    // Determine PnL color
    final pnlColor = totalProfit >= 0 ? _theme.success : _theme.error;

    return Scaffold(
      backgroundColor: _theme.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _theme.background,
        title: Text('TradeMate', style: AppTextStyles.heading2.copyWith(
          color: _theme.primary, 
          fontWeight: FontWeight.w900
        )),
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app, color: _theme.secondary),
            onPressed: _logout,
          )
        ],
      ),

      // =============================
      // CENTER FLOATING BUTTON (+)
      // =============================
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Set index to -1 so no tab is highlighted while on AddTrade screen
          setState(() => _selectedIndex = -1); 
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AddTradeScreen())).then((_) {
            // Reset to home when returning
            if(mounted) setState(() => _selectedIndex = 0);
          });
        },
        elevation: 4,
        backgroundColor: _theme.primary,
        shape: const CircleBorder(),
        child: Icon(Icons.add, size: 28, color: _isDarkTheme ? _theme.background : Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // =============================
      // CUSTOM BOTTOM NAV BAR (Stack for indicator)
      // =============================
      bottomNavigationBar: Container(
        height: 70,
        key: _bottomNavKey,
        color: _theme.background,
        child: Stack(
          alignment: Alignment.bottomCenter, // Helps center the children
          children: [
            // 1. Animated Indicator (The moving circular background)
            if (_selectedIndex >= 0 && _selectedIndex <= 2)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              // Calculate horizontal position
              left: _getIndicatorXOffset(_selectedIndex, screenWidth),
              // Position indicator slightly above the bottom line of the container
              bottom: 12, 
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  // Use primary color for the active indicator background
                  color: _theme.primary, 
                  shape: BoxShape.circle,
                ),
              ),
            ),
            
            // 2. The Notched Bottom Bar (Sits on top of the indicator layer)
            BottomAppBar(
              height: 70,
              color: _theme.cardDark,
              notchMargin: 8,
              shape: const CircularNotchedRectangle(),
              elevation: 8,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _navItem(
                    index: 0,
                    icon: Icons.home_outlined,
                    label: "Home",
                  ),

                  // Space for FAB
                  const SizedBox(width: 60),

                  _navItem(
                    index: 1,
                    icon: Icons.bar_chart_outlined,
                    label: "Stats",
                  ),
                  _navItem(
                    index: 2,
                    icon: Icons.person_outline,
                    label: "Profile",
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // end nav

      // main body
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await _loadEverything();
          },
          color: _theme.primary,
          backgroundColor: _theme.background,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ============================
                // Header & Total PnL Card
                // ============================
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _theme.cardDark,
                    borderRadius: BorderRadius.circular(kBorderRadius),
                    border: Border.all(color: _theme.primary.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Welcome Back,', style: AppTextStyles.bodySecondary.copyWith(
                            color: _theme.textFaded, fontSize: 14
                          )),
                          const SizedBox(height: 4),
                          Text(userName.isEmpty ? 'Trader' : userName,
                              style: AppTextStyles.heading1.copyWith(
                                color: _theme.textLight, 
                                fontWeight: FontWeight.w900, 
                                fontSize: 28
                              )),
                          const SizedBox(height: 12),
                          Text('Total Lifetime P&L', style: AppTextStyles.bodySecondary.copyWith(
                            color: _theme.textFaded, fontSize: 16
                          )),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Icon(Icons.trending_up, color: pnlColor, size: 36),
                          const SizedBox(height: 8),
                          Text('\$${totalProfit.toStringAsFixed(2)}',
                              style: AppTextStyles.heading1.copyWith(
                                color: pnlColor,
                                fontWeight: FontWeight.w900,
                                fontSize: 32,
                              )
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ============================
                // Stats grid (Win Rate / Avg / Best / Worst)
                // ============================
                Text('Performance Metrics', style: AppTextStyles.heading3.copyWith(
                  color: _theme.textLight, fontWeight: FontWeight.w700
                )),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: MediaQuery.of(context).size.width > 700 ? 4 : 2,
                  shrinkWrap: true,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _smallStat(
                      label: 'Win Rate',
                      value: '${winRate.toStringAsFixed(0)}%',
                      icon: Icons.check_circle_outline,
                      iconColor: _theme.success,
                      borderColor: _theme.success.withOpacity(0.3),
                    ),
                    _smallStat(
                      label: 'Average PnL',
                      value: '\$${avgProfit.toStringAsFixed(2)}',
                      icon: Icons.calculate_outlined,
                      iconColor: _theme.accent,
                      borderColor: _theme.accent.withOpacity(0.3),
                    ),
                    _smallStat(
                      label: 'Best Trade',
                      value: '\$${bestTrade.toStringAsFixed(2)}',
                      icon: Icons.rocket_launch_outlined,
                      iconColor: _theme.primary,
                    ),
                    _smallStat(
                      label: 'Worst Trade',
                      value: '\$${worstTrade.toStringAsFixed(2)}',
                      icon: Icons.heart_broken_outlined,
                      iconColor: _theme.secondary,
                      borderColor: _theme.secondary.withOpacity(0.3),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ============================
                // Calendar and Recent Trades
                // ============================
                Text('Trading Journal', style: AppTextStyles.heading3.copyWith(
                  color: _theme.textLight, fontWeight: FontWeight.w700
                )),
                const SizedBox(height: 12),
                
                // Calendar
                _buildMiniCalendar(),

                const SizedBox(height: 20),

                // Recent trades header
               /* Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Recent Activity', style: AppTextStyles.heading3.copyWith(
                      color: _theme.textLight, fontWeight: FontWeight.w700
                    )),
                    TextButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const AllTradesScreen()));
                      },
                      style: TextButton.styleFrom(foregroundColor: _theme.accent),
                      child: const Text('View All >'),
                    )
                  ],
                ),*/

                const SizedBox(height: 10),

                // Recent trades list (stream)
                Container(
                  decoration: BoxDecoration(
                    color: _theme.cardDark,
                    borderRadius: BorderRadius.circular(kBorderRadius),
                  ),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _db
                        .collection('trades')
                        .doc(_auth.currentUser?.uid)
                        .collection('user_trades')
                        .orderBy('timestamp', descending: true)
                        .limit(6)
                        .snapshots(),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return Padding(
                          padding: const EdgeInsets.all(20),
                          child: Center(child: CircularProgressIndicator(color: _theme.primary)),
                        );
                      }
                      if (!snap.hasData || snap.data!.docs.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(20),
                          child: Center(child: Text('No recent trades logged.', 
                            style: TextStyle(color: _theme.textFaded)
                          )),
                        );
                      }

                      final docs = snap.data!.docs;
                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: docs.length,
                        separatorBuilder: (_, __) => Divider(height: 1, color: _theme.textFaded.withOpacity(0.1)),
                        itemBuilder: (context, i) {
                          final t = docs[i];
                          final profit = double.tryParse(t['profit'].toString()) ?? 0.0;
                          final listPnlColor = profit >= 0 ? _theme.success : _theme.error;
                          
                          return ListTile(
                            tileColor: _theme.cardDark,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: listPnlColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                profit >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                                color: listPnlColor,
                                size: 20,
                              ),
                            ),
                            title: Text(t['symbol'] ?? 'UNKNOWN', style: AppTextStyles.heading3.copyWith(
                              color: _theme.textLight, fontWeight: FontWeight.w700
                            )),
                            subtitle: Text('Lot ${t['lotSize'] ?? '—'} | ${_formatTimestamp(t['timestamp'])}', 
                              style: TextStyle(color: _theme.textFaded, fontSize: 13)),
                            trailing: Text(
                              (profit >= 0 ? '+' : '') + '\$${profit.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: listPnlColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16
                              ),
                            ),
                            onTap: () {
                              // TODO: open trade details
                            },
                          );
                        },
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(dynamic ts) {
    if (ts == null) return '';
    if (ts is Timestamp) {
      final d = ts.toDate();
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    }
    return ts.toString();
  }
}

// NOTE: All placeholder screen classes (AddTradeScreen, AllTradesScreen, AnalyticsScreen, ProfileScreen) 
// have been removed from this file and replaced by the imports above.