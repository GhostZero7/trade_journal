/*import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/theme_service.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'core/constants/app_colors.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeService>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Trade Journal",

      // Theme Service
      theme: ThemeMode.themeData,

      // Initial Route
      initialRoute: '/login',

      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/dashboard': (context) => const DashboardScreen(),
      },
    );
  }
}
*/