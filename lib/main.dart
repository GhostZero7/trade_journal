import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';            // flutterfire configure output
import 'core/theme/theme_service.dart';    // NEW: dynamic theme handler
import 'core/theme/app_theme.dart';        // your light + dark themes
import 'routes/app_routes.dart';           // your route manager

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeService(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeService>(context);

    return MaterialApp(
      title: 'Trade Journal',
      debugShowCheckedModeBanner: false,

      // 🔥 Dynamic theme (auto switches based on ThemeService)
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,

      // Routing
      initialRoute: AppRoutes.login,
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}