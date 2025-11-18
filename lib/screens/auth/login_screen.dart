import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/theme_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/google_auth_service.dart';
import '../../../widgets/buttons/primary_button.dart';
import '../dashboard/dashboard_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _authService = AuthService();
  final _googleAuth = GoogleAuthService();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  bool _showPassword = false;
  String? _errorMessage;

  late AnimationController _controller;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  // Theme helper method
  AppColors _getTheme(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context, listen: true);
    return themeService.isDarkMode ? AppColors.dark : AppColors.light;
  }

  void _handleLogin() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final user = await _authService.signIn(
      _emailCtrl.text.trim(),
      _passwordCtrl.text.trim(),
    );

    if (!mounted) return;

    setState(() => _loading = false);

    if (user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } else {
      setState(() => _errorMessage = "Invalid email or password");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = _getTheme(context);
    
    return Scaffold(
      backgroundColor: theme.background,
      body: FadeTransition(
        opacity: _fadeIn,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // TITLE
                Text("Welcome Back 👋",
                    style: AppTextStyles.heading1().copyWith(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                    )),

                const SizedBox(height: 8),

                Text(
                  "Login to continue tracking your trades",
                  style: AppTextStyles.bodySecondary(color: theme.textFaded).copyWith(
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                // EMAIL INPUT (modern soft UI)
                Container(
                  decoration: BoxDecoration(
                    color: theme.cardDark,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(theme == AppColors.dark ? 0.3 : 0.05),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(color: theme.textLight),
                    decoration: InputDecoration(
                      labelText: "Email Address",
                      labelStyle: TextStyle(
                        fontSize: 15,
                        color: theme.textLight,
                      ),
                      filled: true,
                      fillColor: theme.cardDark,
                      prefixIcon: Icon(
                        Icons.email_outlined,
                        color: theme.primary,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 18,
                        horizontal: 16,
                      ),
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
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // PASSWORD INPUT WITH SHOW/HIDE
                Container(
                  decoration: BoxDecoration(
                    color: theme.cardDark,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(theme == AppColors.dark ? 0.3 : 0.05),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _passwordCtrl,
                    obscureText: !_showPassword,
                    style: TextStyle(color: theme.textLight),
                    decoration: InputDecoration(
                      labelText: "Password",
                      labelStyle: TextStyle(
                        fontSize: 15,
                        color: theme.textLight,
                      ),
                      filled: true,
                      fillColor: theme.cardDark,
                      prefixIcon: Icon(
                        Icons.lock_outline,
                        color: theme.primary,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showPassword ? Icons.visibility : Icons.visibility_off,
                          color: theme.textFaded,
                        ),
                        onPressed: () => setState(() => _showPassword = !_showPassword),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 18,
                        horizontal: 16,
                      ),
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
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // ERROR MESSAGE
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: theme.error, fontSize: 14),
                    ),
                  ),

                const SizedBox(height: 10),

                // LOGIN BUTTON
                _loading
                    ? CircularProgressIndicator(color: theme.primary)
                    : PrimaryButton(
                        text: 'Login',
                        onPressed: _handleLogin,
                      ),

                const SizedBox(height: 20),

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

                const SizedBox(height: 20),

                // GOOGLE LOGIN
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () async {
                      final user = await _googleAuth.signInWithGoogle();
                      if (user != null && mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const DashboardScreen()),
                        );
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: theme.textFaded),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: theme.cardDark,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'lib/assets/images/google_logo.png',
                          height: 22,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "Continue with Google",
                          style: TextStyle(
                              color: theme.textLight,
                              fontSize: 15,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                // SIGNUP NAV
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Don't have an account? ", 
                         style: TextStyle(color: theme.textFaded)),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SignupScreen()),
                      ),
                      child: Text(
                        "Sign Up",
                        style: TextStyle(
                          color: theme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}