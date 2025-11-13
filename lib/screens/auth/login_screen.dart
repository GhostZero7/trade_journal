import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../widgets/inputs/custom_text_field.dart';
import '../../../widgets/buttons/primary_button.dart';
import '../../../services/auth_service.dart';
import '../../../services/google_auth_service.dart';
import '../dashboard/dashboard_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authService = AuthService();
  final _googleAuth = GoogleAuthService();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  String? _errorMessage;

  void _handleLogin() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final user = await _authService.signIn(
      _emailCtrl.text.trim(),
      _passwordCtrl.text.trim(),
    );

    setState(() => _loading = false);

    if (user != null) {
      // Navigate to dashboard
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      }
    } else {
      setState(() => _errorMessage = "Invalid email or password");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Welcome Back 👋', style: AppTextStyles.heading1),
            const SizedBox(height: 8),
            const Text('Login to your account', style: AppTextStyles.bodySecondary),
            const SizedBox(height: 32),

            TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(hintText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _passwordCtrl,
              decoration: const InputDecoration(hintText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 16),

            if (_errorMessage != null)
              Text(_errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 14)),

            const SizedBox(height: 24),

            _loading
                ? const Center(child: CircularProgressIndicator())
                : PrimaryButton(
                    text: 'Login',
                    onPressed: _handleLogin,
                  ),

            const SizedBox(height: 16),

            Center(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final user = await _googleAuth.signInWithGoogle();
                  if (user != null && context.mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const DashboardScreen()),
                    );
                  }
                },
                icon: Image.asset('lib/assets/images/google_logo.png', height: 20),
                label: const Text(
                  'Sign in with Google',
                  style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  side: const BorderSide(color: Colors.grey),
                  backgroundColor: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Don't have an account? "),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SignupScreen()),
                  ),
                  child: const Text(
                    'Sign Up',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
