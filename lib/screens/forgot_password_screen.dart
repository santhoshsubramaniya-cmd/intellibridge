import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/themes.dart';
import '../../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _sent = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _errorMessage = null);

    final authService = context.read<AuthService>();
    final result =
        await authService.resetPassword(_emailCtrl.text.trim());

    if (!mounted) return;

    if (result == AuthResult.success) {
      setState(() => _sent = true);
    } else {
      setState(() => _errorMessage = result.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _sent ? _buildSuccessView() : _buildFormView(auth),
        ),
      ),
    );
  }

  Widget _buildFormView(AuthService auth) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),

          const Text(
            'Forgot\nPassword? 🔐',
            style: TextStyle(
              fontFamily: 'Syne',
              fontSize: 32,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ).animate().fadeIn().slideY(begin: 0.2),

          const SizedBox(height: 12),

          const Text(
            'Enter your registered email and we\'ll send you a password reset link.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.lightMuted,
              height: 1.5,
            ),
          ).animate().fadeIn(delay: 100.ms),

          const SizedBox(height: 40),

          const Text(
            'Email Address',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
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
          ).animate().fadeIn(delay: 200.ms),

          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: AppColors.accent.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: AppColors.accent, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_errorMessage!,
                        style: const TextStyle(
                            color: AppColors.accent, fontSize: 13)),
                  ),
                ],
              ),
            ).animate().shake(),
          ],

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: auth.isLoading ? null : _resetPassword,
              child: auth.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Send Reset Link'),
            ),
          ).animate().fadeIn(delay: 300.ms),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.secondary.withOpacity(0.15),
            ),
            child: const Icon(
              Icons.mark_email_read_outlined,
              color: AppColors.secondary,
              size: 40,
            ),
          ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),

          const SizedBox(height: 24),

          const Text(
            'Check Your Email!',
            style: TextStyle(
              fontFamily: 'Syne',
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 12),

          Text(
            'We sent a password reset link to\n${_emailCtrl.text}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.lightMuted,
              height: 1.6,
            ),
          ).animate().fadeIn(delay: 300.ms),

          const SizedBox(height: 40),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to Login'),
            ),
          ).animate().fadeIn(delay: 400.ms),
        ],
      ),
    );
  }
}
