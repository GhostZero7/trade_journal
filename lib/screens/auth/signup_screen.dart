import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../widgets/inputs/custom_text_field.dart';
import '../../../widgets/buttons/primary_button.dart';
import '../../../services/auth_service.dart';
import '../dashboard/dashboard_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _authService = AuthService();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  String? _errorMessage;

  void _handleSignup() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final user = await _authService.signUp(
      _emailCtrl.text.trim(),
      _passCtrl.text.trim(),
      _nameCtrl.text.trim(),
    );

    setState(() => _loading = false);

    if (user != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created successfully!')),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      }
    } else {
      setState(() => _errorMessage = "Signup failed. Try again.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Create Account ✨', style: AppTextStyles.heading1),
            const SizedBox(height: 8),
            const Text('Join the journal to track your trades',
                style: AppTextStyles.bodySecondary),
            const SizedBox(height: 32),

            CustomTextField(
              hintText: 'Full Name',
              keyboardType: TextInputType.name,
              controller: _nameCtrl,
            ),
            const SizedBox(height: 16),

            CustomTextField(
              hintText: 'Email',
              keyboardType: TextInputType.emailAddress,
              controller: _emailCtrl,
            ),
            const SizedBox(height: 16),

            CustomTextField(
              hintText: 'Password',
              obscureText: true,
              controller: _passCtrl,
            ),
            const SizedBox(height: 24),

            if (_errorMessage != null)
              Text(_errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 14)),

            const SizedBox(height: 16),

            _loading
                ? const Center(child: CircularProgressIndicator())
                : PrimaryButton(
                    text: 'Sign Up',
                    onPressed: _handleSignup,
                  ),

            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Already have an account? "),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Text(
                    'Login',
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
