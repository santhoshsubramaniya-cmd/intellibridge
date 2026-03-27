import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/themes.dart';
import '../../config/constants.dart';
import '../../services/auth_service.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  String _selectedRole = AppConstants.roleStudent;
  String? _selectedCourse;
  int? _selectedSemester;
  String? _selectedDept;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _errorMessage;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordCtrl.text != _confirmCtrl.text) {
      setState(() => _errorMessage = 'Passwords do not match');
      return;
    }
    setState(() => _errorMessage = null);

    final authService = context.read<AuthService>();
    final result = await authService.register(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text.trim(),
      role: _selectedRole,
      department: _selectedDept ??
          (_selectedRole == AppConstants.roleStudent
              ? _selectedCourse ?? ''
              : ''),
      phone: _phoneCtrl.text.trim(),
      course: _selectedRole == AppConstants.roleStudent
          ? _selectedCourse
          : null,
      semester: _selectedRole == AppConstants.roleStudent
          ? _selectedSemester
          : null,
    );

    if (!mounted) return;

    if (result == AuthResult.success) {
      // Sign out immediately so the Firebase Auth session doesn't
      // persist and bypass the approval check on next app launch
      await authService.logout();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _selectedRole == AppConstants.roleAdmin
                ? '✅ Account created! You can login now.'
                : '✅ Account created! Awaiting admin approval.',
          ),
          backgroundColor: AppColors.secondary,
        ),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } else {
      setState(() => _errorMessage = result.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                const Text(
                  'Join SmartPlace 🎓',
                  style: TextStyle(
                    fontFamily: 'Syne',
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ).animate().fadeIn().slideY(begin: 0.2),

                const SizedBox(height: 8),
                const Text(
                  'Your campus-to-career journey starts here',
                  style: TextStyle(
                      fontSize: 14, color: AppColors.lightMuted),
                ).animate().fadeIn(delay: 100.ms),

                const SizedBox(height: 32),

                // Role selection
                _buildLabel('I am a...'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _roleChip(AppConstants.roleStudent, '🎓', 'Student'),
                    const SizedBox(width: 8),
                    _roleChip(AppConstants.roleFaculty, '👨‍🏫', 'Faculty'),
                    const SizedBox(width: 8),
                    _roleChip(
                        AppConstants.roleRecruiter, '💼', 'Recruiter'),
                    _roleChip(
                        AppConstants.roleAdmin, '🛡️', 'Admin'),
                  ],
                ).animate().fadeIn(delay: 150.ms),

                const SizedBox(height: 24),

                // Name
                _buildLabel('Full Name'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Enter your full name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) =>
                      v!.isEmpty ? 'Please enter your name' : null,
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 16),

                // Email
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
                ).animate().fadeIn(delay: 250.ms),

                const SizedBox(height: 16),

                // Phone
                _buildLabel('Phone Number'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    hintText: 'Enter your phone number',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: (v) =>
                      v!.isEmpty ? 'Please enter your phone' : null,
                ).animate().fadeIn(delay: 300.ms),

                const SizedBox(height: 16),

                // Student-specific fields
                if (_selectedRole == AppConstants.roleStudent) ...[
                  _buildLabel('Course'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedCourse,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.school_outlined),
                    ),
                    hint: const Text('Select your course'),
                    items: AppConstants.courses
                        .map((c) => DropdownMenuItem(
                              value: c,
                              child: Text(c,
                                  style: const TextStyle(fontSize: 13)),
                            ))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _selectedCourse = v),
                    validator: (v) =>
                        v == null ? 'Please select a course' : null,
                  ).animate().fadeIn(delay: 320.ms),

                  const SizedBox(height: 16),

                  _buildLabel('Current Semester'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: _selectedSemester,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    hint: const Text('Select semester'),
                    items: AppConstants.semesters
                        .map((s) => DropdownMenuItem(
                              value: s,
                              child: Text('Semester $s'),
                            ))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _selectedSemester = v),
                    validator: (v) =>
                        v == null ? 'Please select a semester' : null,
                  ).animate().fadeIn(delay: 340.ms),

                  const SizedBox(height: 16),
                ],

                // Faculty department
                if (_selectedRole == AppConstants.roleFaculty) ...[
                  _buildLabel('Department'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedDept,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.business_outlined),
                    ),
                    hint: const Text('Select department'),
                    items: AppConstants.courses
                        .map((c) => DropdownMenuItem(
                              value: c,
                              child: Text(c,
                                  style: const TextStyle(fontSize: 13)),
                            ))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _selectedDept = v),
                    validator: (v) =>
                        v == null ? 'Please select a department' : null,
                  ).animate().fadeIn(delay: 320.ms),

                  const SizedBox(height: 16),
                ],

                // Password
                _buildLabel('Password'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Create a password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) => v!.length < 6
                      ? 'Password must be at least 6 characters'
                      : null,
                ).animate().fadeIn(delay: 360.ms),

                const SizedBox(height: 16),

                // Confirm password
                _buildLabel('Confirm Password'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: _obscureConfirm,
                  decoration: InputDecoration(
                    hintText: 'Confirm your password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirm
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () => setState(
                          () => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: (v) =>
                      v!.isEmpty ? 'Please confirm your password' : null,
                ).animate().fadeIn(delay: 380.ms),

                const SizedBox(height: 16),

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
                          child: Text(_errorMessage!,
                              style: const TextStyle(
                                  color: AppColors.accent, fontSize: 13)),
                        ),
                      ],
                    ),
                  ).animate().shake(),
                  const SizedBox(height: 12),
                ],

                // Notice for non-admin roles
                if (_selectedRole != AppConstants.roleAdmin) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.warning.withOpacity(0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: AppColors.warning, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Your account will require admin approval before you can log in.',
                            style: TextStyle(
                                color: AppColors.warning, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Register button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: auth.isLoading ? null : _register,
                    child: auth.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Create Account'),
                  ),
                ).animate().fadeIn(delay: 400.ms),

                const SizedBox(height: 24),

                // Login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account? ',
                        style:
                            TextStyle(color: AppColors.lightMuted)),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 450.ms),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _roleChip(String role, String emoji, String label) {
    final isSelected = _selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withOpacity(0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.lightBorder,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.lightMuted,
                ),
              ),
            ],
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
