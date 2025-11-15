import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool darkMode = true;
  String currency = "USD";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F10),
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),

      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [

          // Dark mode toggle
          SwitchListTile(
            value: darkMode,
            title: const Text("Dark Mode", style: TextStyle(color: Colors.white)),
            activeColor: Colors.blue,
            onChanged: (v) => setState(() => darkMode = v),
          ),

          const SizedBox(height: 20),

          // Currency dropdown
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Currency",
                    style: TextStyle(color: Colors.white, fontSize: 16)),
                const SizedBox(height: 10),
                DropdownButton<String>(
                  value: currency,
                  dropdownColor: Colors.grey.shade900,
                  style: const TextStyle(color: Colors.white),
                  items: ["USD", "ZMW", "ZAR", "EUR", "GBP"]
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => currency = v!),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          ListTile(
            tileColor: Colors.red.shade900,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            title: const Text("Delete Account",
                style: TextStyle(color: Colors.white)),
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
