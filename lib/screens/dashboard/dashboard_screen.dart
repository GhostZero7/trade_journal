// lib/screens/dashboard/dashboard_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/theme_service.dart';
import '../settings/settings_screen.dart';
import '../analytics/analytics_screen.dart';
import '../trades/all_trades_screen.dart';
import '../profile/profile_screen.dart'; 
import '../trades/trades_screen.dart';

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
  
  DateTime? currentBackPressTime;

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
  final GlobalKey _bottomNavKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadEverything();
    _saveLoginStatus();
  }

  // ============================
  // Save login status to SharedPreferences
  // ============================
  Future<void> _saveLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('lastLogin', DateTime.now().toIso8601String());
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
  // Handle back button press to close app
  // ============================
  Future<bool> _onWillPop() async {
    DateTime now = DateTime.now();
    if (currentBackPressTime == null || 
        now.difference(currentBackPressTime!) > const Duration(seconds: 2)) {
      currentBackPressTime = now;
      
      final theme = _getTheme(context);
      // Show snackbar message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Press back again to exit',
            style: TextStyle(color: theme.textLight),
          ),
          backgroundColor: theme.cardDark,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(20),
        ),
      );
      return false;
    }
    return true;
  }

  // ============================
  // Navigation & Indicator Helpers
  // ============================
  void _onNavTap(int idx) {
    if (idx == 0) {
      setState(() => _selectedIndex = idx);
    } else if (idx == 1) {
      setState(() => _selectedIndex = idx);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
      ).then((_) {
        if(mounted) setState(() => _selectedIndex = 0); 
      });
    } else if (idx == 2) {
      setState(() => _selectedIndex = idx);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
      ).then((_) {
        if(mounted) setState(() => _selectedIndex = 0);
      });
    }
  }
  
  // Custom logic to calculate the horizontal offset for the indicator.
  double _getIndicatorXOffset(int index, double screenWidth) {
    final itemWidth = screenWidth / 4.0;
    const indicatorSize = 48.0;

    switch (index) {
      case 0: // Home (1st slot)
        return (itemWidth / 2.0) - (indicatorSize / 2.0); 
      case 1: // Stats (3rd slot)
        return (itemWidth * 2.5) - (indicatorSize / 2.0); 
      case 2: // Profile (4th slot)
        return (itemWidth * 3.5) - (indicatorSize / 2.0); 
      default:
        return -indicatorSize; 
    }
  }

  // ============================
  // Theme Helper - Get current theme based on ThemeService
  // ============================
  AppColors _getTheme(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context, listen: true);
    return themeService.isDarkMode ? AppColors.dark : AppColors.light;
  }

  // ============================
  // UI - small reusable stat card
  // ============================
  Widget _smallStat({
    required BuildContext context,
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
    Color? borderColor,
  }) {
    final theme = _getTheme(context);
    final themeService = Provider.of<ThemeService>(context, listen: false);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardDark,
        borderRadius: BorderRadius.circular(kBorderRadius),
        border: Border.all(
          color: borderColor ?? theme.cardDark,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(themeService.isDarkMode ? 0.3 : 0.1),
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
                  style: AppTextStyles.bodySecondary(color: theme.textFaded).copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  )),
            ],
          ),
          const SizedBox(height: 10),
          Text(value, 
            style: AppTextStyles.heading2(color: iconColor).copyWith(
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
  Widget _buildMiniCalendar(BuildContext context) {
    final theme = _getTheme(context);
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
                  color: isToday ? theme.accent : theme.textLight,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: profitable ? theme.success : theme.textFaded.withOpacity(0.2),
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
        color: theme.cardDark,
        borderRadius: BorderRadius.circular(kBorderRadius),
        border: Border.all(
          color: theme.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _calendarNavButton(context, Icons.chevron_left, () {
                setState(() {
                  _calendarDate = DateTime(_calendarDate.year, _calendarDate.month - 1);
                });
                _loadProfitCalendar();
              }),
              Text('${_monthName(_calendarDate.month)} ${_calendarDate.year}',
                  style: AppTextStyles.heading2(color: theme.textLight).copyWith(
                    fontWeight: FontWeight.w700,
                  )),
              _calendarNavButton(context, Icons.chevron_right, () {
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
            ].map((day) => Text(day, style: AppTextStyles.bodySecondary(color: theme.textFaded).copyWith(
              fontWeight: FontWeight.w700, 
              fontSize: 13,
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

  Widget _calendarNavButton(BuildContext context, IconData icon, VoidCallback onPressed) {
    final theme = _getTheme(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.cardDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.textFaded.withOpacity(0.2)),
      ),
      child: IconButton(
        icon: Icon(icon, color: theme.textLight, size: 20),
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
  // NAV ITEM WIDGET
  // =============================
  Widget _navItem(BuildContext context, {required int index, required IconData icon, required String label}) {
    final theme = _getTheme(context);
    final bool active = _selectedIndex == index;
    final Color iconColor = active ? theme.cardDark : theme.textFaded; 

    return GestureDetector(
      onTap: () => _onNavTap(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
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
                color: active ? theme.primary : theme.textFaded,
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
    final themeService = Provider.of<ThemeService>(context, listen: true);
    final theme = _getTheme(context);
    final double screenWidth = MediaQuery.of(context).size.width;
    final pnlColor = totalProfit >= 0 ? theme.success : theme.error;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: theme.background,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: theme.background,
          automaticallyImplyLeading: false,
          title: Text('TradeMate', style: AppTextStyles.heading2(color: theme.primary).copyWith(
            fontWeight: FontWeight.w900,
          )),
          actions: [
            // Empty actions - no logout button
          ],
        ),

        // =============================
        // CENTER FLOATING BUTTON (+)
        // =============================
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            setState(() => _selectedIndex = -1); 
            Navigator.push(context, MaterialPageRoute(builder: (_) => const AddTradeScreen())).then((_) {
              if(mounted) setState(() => _selectedIndex = 0);
            });
          },
          elevation: 4,
          backgroundColor: theme.primary,
          shape: const CircleBorder(),
          child: Icon(Icons.add, size: 28, color: themeService.isDarkMode ? theme.background : Colors.white),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

        // =============================
        // CUSTOM BOTTOM NAV BAR
        // =============================
        bottomNavigationBar: Container(
          height: 70,
          key: _bottomNavKey,
          color: theme.background,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              if (_selectedIndex >= 0 && _selectedIndex <= 2)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                left: _getIndicatorXOffset(_selectedIndex, screenWidth),
                bottom: 12, 
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: theme.primary, 
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              
              BottomAppBar(
                height: 70,
                color: theme.cardDark,
                notchMargin: 8,
                shape: const CircularNotchedRectangle(),
                elevation: 8,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _navItem(context,
                      index: 0,
                      icon: Icons.home_outlined,
                      label: "Home",
                    ),

                    const SizedBox(width: 60),

                    _navItem(context,
                      index: 1,
                      icon: Icons.bar_chart_outlined,
                      label: "Stats",
                    ),
                    _navItem(context,
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

        // ============================
        // MAIN BODY CONTENT
        // ============================
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              await _loadEverything();
            },
            color: theme.primary,
            backgroundColor: theme.background,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header & Total PnL Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.cardDark,
                      borderRadius: BorderRadius.circular(kBorderRadius),
                      border: Border.all(color: theme.primary.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Welcome Back,', style: AppTextStyles.bodySecondary(color: theme.textFaded).copyWith(
                              fontSize: 14,
                            )),
                            const SizedBox(height: 4),
                            Text(userName.isEmpty ? 'Trader' : userName,
                                style: AppTextStyles.heading1(color: theme.textLight).copyWith(
                                  fontWeight: FontWeight.w900, 
                                  fontSize: 28,
                                )),
                            const SizedBox(height: 12),
                            Text('Total Lifetime P&L', style: AppTextStyles.bodySecondary(color: theme.textFaded).copyWith(
                              fontSize: 16,
                            )),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Icon(Icons.trending_up, color: pnlColor, size: 36),
                            const SizedBox(height: 8),
                            Text('\$${totalProfit.toStringAsFixed(2)}',
                                style: AppTextStyles.heading1(color: pnlColor).copyWith(
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

                  // Stats grid
                  Text('Performance Metrics', style: AppTextStyles.heading3(color: theme.textLight).copyWith(
                    fontWeight: FontWeight.w700,
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
                        context: context,
                        label: 'Win Rate',
                        value: '${winRate.toStringAsFixed(0)}%',
                        icon: Icons.check_circle_outline,
                        iconColor: theme.success,
                        borderColor: theme.success.withOpacity(0.3),
                      ),
                      _smallStat(
                        context: context,
                        label: 'Average PnL',
                        value: '\$${avgProfit.toStringAsFixed(2)}',
                        icon: Icons.calculate_outlined,
                        iconColor: theme.accent,
                        borderColor: theme.accent.withOpacity(0.3),
                      ),
                      _smallStat(
                        context: context,
                        label: 'Best Trade',
                        value: '\$${bestTrade.toStringAsFixed(2)}',
                        icon: Icons.rocket_launch_outlined,
                        iconColor: theme.primary,
                      ),
                      _smallStat(
                        context: context,
                        label: 'Worst Trade',
                        value: '\$${worstTrade.toStringAsFixed(2)}',
                        icon: Icons.heart_broken_outlined,
                        iconColor: theme.secondary,
                        borderColor: theme.secondary.withOpacity(0.3),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Calendar and Recent Trades
                  Text('Trading Journal', style: AppTextStyles.heading3(color: theme.textLight).copyWith(
                    fontWeight: FontWeight.w700,
                  )),
                  const SizedBox(height: 12),
                  
                  // Calendar
                  _buildMiniCalendar(context),

                  const SizedBox(height: 20),

                  // Recent trades header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Recent Activity', style: AppTextStyles.heading3(color: theme.textLight).copyWith(
                        fontWeight: FontWeight.w700,
                      )),
                      TextButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const AllTradesScreen()));
                        },
                        style: TextButton.styleFrom(foregroundColor: theme.accent),
                        child: const Text('View All >'),
                      )
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Recent trades list (stream)
                  Container(
                    decoration: BoxDecoration(
                      color: theme.cardDark,
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
                            child: Center(child: CircularProgressIndicator(color: theme.primary)),
                          );
                        }
                        if (!snap.hasData || snap.data!.docs.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.all(20),
                            child: Center(child: Text('No recent trades logged.', 
                              style: TextStyle(color: theme.textFaded)
                            )),
                          );
                        }

                        final docs = snap.data!.docs;
                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: docs.length,
                          separatorBuilder: (_, __) => Divider(height: 1, color: theme.textFaded.withOpacity(0.1)),
                          itemBuilder: (context, i) {
                            final t = docs[i];
                            final profit = double.tryParse(t['profit'].toString()) ?? 0.0;
                            final listPnlColor = profit >= 0 ? theme.success : theme.error;
                            
                            return ListTile(
                              tileColor: theme.cardDark,
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
                              title: Text(t['symbol'] ?? 'UNKNOWN', style: AppTextStyles.heading3(color: theme.textLight).copyWith(
                                fontWeight: FontWeight.w700,
                              )),
                              subtitle: Text('Lot ${t['lotSize'] ?? '—'} | ${_formatTimestamp(t['timestamp'])}', 
                                style: TextStyle(color: theme.textFaded, fontSize: 13)),
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