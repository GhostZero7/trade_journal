import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/theme_service.dart';
import '../../../widgets/buttons/primary_button.dart';
import '../../../services/auth_service.dart';
import '../../../services/google_auth_service.dart';
import '../dashboard/dashboard_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  final _authService = AuthService();
  final _googleAuth = GoogleAuthService();

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _loading = false;
  bool _showPass = false;
  bool _showConfirmPass = false;

  String? _errorMessage;

  // NEW: Input errors
  bool _passMismatchError = false;
  bool _emailInUseError = false;

  late AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  // Theme helper method
  AppColors _getTheme(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context, listen: true);
    return themeService.isDarkMode ? AppColors.dark : AppColors.light;
  }

  void _handleSignup() async {
    setState(() {
      _errorMessage = null;
      _passMismatchError = false;
      _emailInUseError = false;
    });

    // Password match validation
    if (_passCtrl.text.trim() != _confirmCtrl.text.trim()) {
      setState(() {
        _passMismatchError = true;
      });
      return;
    }

    setState(() => _loading = true);

    try {
      final user = await _authService.signUp(
        _emailCtrl.text.trim(),
        _passCtrl.text.trim(),
        _nameCtrl.text.trim(),
      );

      setState(() => _loading = false);

      if (user != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created!')),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      } else {
        setState(() => _errorMessage = "Signup failed. Try again.");
      }
    } catch (e) {
      setState(() => _loading = false);

      if (e.toString().contains("email-already-in-use")) {
        setState(() => _emailInUseError = true);
      } else {
        setState(() => _errorMessage = e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = _getTheme(context);
    final passErrorText =
        _passMismatchError ? "Passwords do not match." : null;

    final emailErrorText =
        _emailInUseError ? "Email already in use." : null;

    return Scaffold(
      backgroundColor: theme.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Create Account ✨",
                style: AppTextStyles.heading1().copyWith(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Join and start tracking your trades",
                style: AppTextStyles.bodySecondary(color: theme.textFaded).copyWith(
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              _buildInput(
                context: context,
                controller: _nameCtrl,
                label: "Full Name",
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 18),

              _buildInput(
                context: context,
                controller: _emailCtrl,
                label: "Email",
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                isInputError: _emailInUseError,
                errorText: emailErrorText,
              ),
              const SizedBox(height: 18),

              _buildInput(
                context: context,
                controller: _passCtrl,
                label: "Password",
                icon: Icons.lock_outline,
                obscure: !_showPass,
                isInputError: _passMismatchError,
                errorText: passErrorText,
                suffix: IconButton(
                  icon: Icon(
                    _showPass ? Icons.visibility : Icons.visibility_off,
                    color: theme.textFaded,
                  ),
                  onPressed: () => setState(() => _showPass = !_showPass),
                ),
              ),
              const SizedBox(height: 18),

              _buildInput(
                context: context,
                controller: _confirmCtrl,
                label: "Confirm Password",
                icon: Icons.lock_person_outlined,
                obscure: !_showConfirmPass,
                isInputError: _passMismatchError,
                errorText: passErrorText,
                suffix: IconButton(
                  icon: Icon(
                    _showConfirmPass
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: theme.textFaded,
                  ),
                  onPressed: () =>
                      setState(() => _showConfirmPass = !_showConfirmPass),
                ),
              ),
              const SizedBox(height: 24),

              if (_errorMessage != null &&
                  !_passMismatchError &&
                  !_emailInUseError)
                Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: theme.error,
                    fontSize: 14,
                  ),
                ),
              const SizedBox(height: 12),

              _loading
                  ? CircularProgressIndicator(
                      color: theme.primary,
                    )
                  : PrimaryButton(
                      text: "Sign Up",
                      onPressed: _handleSignup,
                    ),

              const SizedBox(height: 22),

              // OR DIVIDER
              Row(
                children: [
                  Expanded(
                    child: Divider(
                      color: theme.textFaded,
                      thickness: 1,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      "or",
                      style: TextStyle(
                        color: theme.textFaded,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      color: theme.textFaded,
                      thickness: 1,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              OutlinedButton.icon(
                onPressed: () async {
                  final user = await _googleAuth.signInWithGoogle();
                  if (user != null && mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DashboardScreen(),
                      ),
                    );
                  }
                },
                icon: Image.asset(
                  "lib/assets/images/google_logo.png",
                  height: 20,
                ),
                label: Text(
                  "Sign up with Google",
                  style: TextStyle(
                    color: theme.textLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  side: BorderSide(color: theme.textFaded),
                  backgroundColor: theme.cardDark,
                ),
              ),

              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Already have an account? ", 
                       style: TextStyle(color: theme.textFaded)),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Text(
                      "Login",
                      style: TextStyle(
                        color: theme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
    bool isInputError = false,
    String? errorText,
    Widget? suffix,
  }) {
    final theme = _getTheme(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          style: TextStyle(color: theme.textLight),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(
              fontSize: 15,
              color: theme.textLight,
            ),

            filled: true,
            fillColor: theme.cardDark,

            prefixIcon: Icon(icon, color: theme.primary),
            suffixIcon: suffix,

            contentPadding: const EdgeInsets.symmetric(
              vertical: 18,
              horizontal: 16,
            ),

            // Theme-aware borders
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: theme.primary,
                width: 1.6,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: theme.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: theme.error,
                width: 1.8,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: theme.error,
                width: 2,
              ),
            ),

            errorText: isInputError ? errorText : null,
          ),
        ),

        // spacing under input
        if (isInputError)
          const SizedBox(height: 4),
      ],
    );
  }
}