// Profile screen
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../settings/settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F10),
      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            // Avatar
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey.shade800,
              backgroundImage:
                  user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
              child: user?.photoURL == null
                  ? const Icon(Icons.person, size: 50, color: Colors.white)
                  : null,
            ),

            const SizedBox(height: 20),

            // Name
            Text(
              user?.displayName ?? "Unknown User",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 5),

            // Email
            Text(
              user?.email ?? "",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade400,
              ),
            ),

            const SizedBox(height: 30),

            // Stats container
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: const [
                  _ProfileStat(label: "Trades", value: "0"),
                  _ProfileStat(label: "Win Rate", value: "0%"),
                  _ProfileStat(label: "P/L", value: "\$0.00"),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Buttons
            _profileButton(
              icon: Icons.edit_outlined,
              text: "Edit Profile",
              onTap: () {},
            ),

            _profileButton(
              icon: Icons.settings_outlined,
              text: "Settings",
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()));
              },
            ),

            _profileButton(
              icon: Icons.logout,
              text: "Logout",
              color: Colors.red,
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacementNamed(context, "/login");
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final String label;
  final String value;
  const _ProfileStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 5),
        Text(label, style: TextStyle(color: Colors.grey.shade400)),
      ],
    );
  }
}

Widget _profileButton({
  required IconData icon,
  required String text,
  required VoidCallback onTap,
  Color color = Colors.white,
}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 10),
    child: ListTile(
      onTap: onTap,
      tileColor: Colors.grey.shade900,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: Icon(icon, color: color),
      title: Text(text, style: TextStyle(color: color, fontSize: 16)),
      trailing: const Icon(Icons.chevron_right, color: Colors.white),
    ),
  );
}
