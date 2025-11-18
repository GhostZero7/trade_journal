import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
      ),

      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [

          // 🔥 WORKING DARK MODE SWITCH
          SwitchListTile(
            value: theme.isDarkMode,
            title: const Text("Dark Mode"),
            onChanged: (v) => theme.toggleTheme(v),
          ),

          const SizedBox(height: 20),

          ListTile(
            tileColor: Colors.red.shade900,
            title: const Text("Delete Account",
                style: TextStyle(color: Colors.white)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onTap: () async {
              await FirebaseAuth.instance.currentUser?.delete();
              Navigator.pushNamedAndRemoveUntil(context, "/login", (_) => false);
            },
          ),

          const SizedBox(height: 40),
          Center(
            child: Text(
              "Version 1.0.0",
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ),
        ],
      ),
    );
  }
}
