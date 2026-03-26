import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/themes.dart';
import '../../services/auth_service.dart';
import 'register_screen.dart';
import '../forgot_password_screen.dart';
import '../student/student_home.dart';
import '../faculty/faculty_home.dart';
import '../admin/admin_home.dart';
import '../recruiter/recruiter_home.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _errorMessage = null);

    final authService = context.read<AuthService>();
    final result = await authService.login(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text.trim(),
    );

    if (!mounted) return;

    if (result == AuthResult.success) {
      final role = authService.userModel?.role;
      Widget home;
      switch (role) {
        case 'faculty':
          home = const FacultyHome();
          break;
        case 'admin':
          home = const AdminHome();
          break;
        case 'recruiter':
          home = const RecruiterHome();
          break;
        default:
          home = const StudentHome();
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => home),
      );
    } else {
      setState(() => _errorMessage = result.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),

                // Header
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.secondary],
                        ),
                      ),
                      child: const Icon(
                        Icons.school_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'SmartPlace',
                      style: TextStyle(
                        fontFamily: 'Syne',
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.2),

                const SizedBox(height: 48),

                const Text(
                  'Welcome\nBack 👋',
                  style: TextStyle(
                    fontFamily: 'Syne',
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2),

                const SizedBox(height: 8),

                Text(
                  'Log in to your campus-to-career platform',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? AppColors.darkMuted
                        : AppColors.lightMuted,
                  ),
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 40),

                // Email field
                _buildLabel('Email Address'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'Enter your email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) =>
                      v!.isEmpty ? 'Please enter your email' : null,
                ).animate().fadeIn(delay: 300.ms),

                const SizedBox(height: 20),

                // Password field
                _buildLabel('Password'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Enter your password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) =>
                      v!.isEmpty ? 'Please enter your password' : null,
                ).animate().fadeIn(delay: 400.ms),

                const SizedBox(height: 12),

                // Forgot password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ForgotPasswordScreen()),
                    ),
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ),
                ).animate().fadeIn(delay: 450.ms),

                // Error message
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.accent.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppColors.accent, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                                color: AppColors.accent, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn().shake(),
                  const SizedBox(height: 16),
                ],

                const SizedBox(height: 8),

                // Login button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: auth.isLoading ? null : _login,
                    child: auth.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Login'),
                  ),
                ).animate().fadeIn(delay: 500.ms),

                const SizedBox(height: 32),

                // Register link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: TextStyle(
                        color: isDark
                            ? AppColors.darkMuted
                            : AppColors.lightMuted,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const RegisterScreen()),
                      ),
                      child: const Text(
                        'Create Account',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 600.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }
}
