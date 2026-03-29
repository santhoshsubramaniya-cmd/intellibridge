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
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  String _role = AppConstants.roleStudent;
  String? _course;
  int? _semester;
  String? _dept;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose(); _phoneCtrl.dispose();
    _passCtrl.dispose(); _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passCtrl.text != _confirmCtrl.text) {
      setState(() => _error = 'Passwords do not match');
      return;
    }
    setState(() => _error = null);

    final auth = context.read<AuthService>();
    final result = await auth.register(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text.trim(),
      role: _role,
      department: _dept ?? _course ?? '',
      phone: _phoneCtrl.text.trim(),
      course: _role == AppConstants.roleStudent ? _course : null,
      semester: _role == AppConstants.roleStudent ? _semester : null,
    );

    if (!mounted) return;

    if (result == AuthResult.success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_role == AppConstants.roleAdmin
            ? '✅ Account created! You can login now.'
            : '✅ Account created! Awaiting admin approval.'),
        backgroundColor: AppColors.secondary,
      ));
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    } else {
      setState(() => _error = result.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Join InteliBridge 🎓',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                ).animate().fadeIn().slideY(begin: 0.2),

                const SizedBox(height: 24),

                // Role chips
                _label('I am a...'),
                const SizedBox(height: 10),
                Row(children: [
                  _roleChip(AppConstants.roleStudent, '🎓', 'Student'),
                  const SizedBox(width: 8),
                  _roleChip(AppConstants.roleFaculty, '👨‍🏫', 'Faculty'),
                  const SizedBox(width: 8),
                  _roleChip(AppConstants.roleRecruiter, '💼', 'Recruiter'),
                ]),

                const SizedBox(height: 20),

                _label('Full Name'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(hintText: 'Enter your name', prefixIcon: Icon(Icons.person_outline)),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),

                const SizedBox(height: 16),
                _label('Email'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(hintText: 'Enter email', prefixIcon: Icon(Icons.email_outlined)),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),

                const SizedBox(height: 16),
                _label('Phone'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(hintText: 'Phone number', prefixIcon: Icon(Icons.phone_outlined)),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),

                if (_role == AppConstants.roleStudent) ...[
                  const SizedBox(height: 16),
                  _label('Course'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _course,
                    decoration: const InputDecoration(prefixIcon: Icon(Icons.school_outlined)),
                    hint: const Text('Select course'),
                    items: AppConstants.courses.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13)))).toList(),
                    onChanged: (v) => setState(() => _course = v),
                    validator: (v) => v == null ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  _label('Semester'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: _semester,
                    decoration: const InputDecoration(prefixIcon: Icon(Icons.calendar_today_outlined)),
                    hint: const Text('Select semester'),
                    items: AppConstants.semesters.map((s) => DropdownMenuItem(value: s, child: Text('Semester $s'))).toList(),
                    onChanged: (v) => setState(() => _semester = v),
                    validator: (v) => v == null ? 'Required' : null,
                  ),
                ],

                if (_role == AppConstants.roleFaculty) ...[
                  const SizedBox(height: 16),
                  _label('Department'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _dept,
                    decoration: const InputDecoration(prefixIcon: Icon(Icons.business_outlined)),
                    hint: const Text('Select department'),
                    items: AppConstants.courses.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13)))).toList(),
                    onChanged: (v) => setState(() => _dept = v),
                    validator: (v) => v == null ? 'Required' : null,
                  ),
                ],

                const SizedBox(height: 16),
                _label('Password'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    hintText: 'Create password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) => (v?.length ?? 0) < 6 ? 'Min 6 characters' : null,
                ),

                const SizedBox(height: 16),
                _label('Confirm Password'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(hintText: 'Confirm password', prefixIcon: Icon(Icons.lock_outline)),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),

                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.error_outline, color: AppColors.accent, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.accent, fontSize: 13))),
                    ]),
                  ).animate().shake(),
                ],

                if (_role != AppConstants.roleAdmin) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                    ),
                    child: const Row(children: [
                      Icon(Icons.info_outline, color: AppColors.warning, size: 18),
                      SizedBox(width: 8),
                      Expanded(child: Text('Requires admin approval before login.',
                        style: TextStyle(color: AppColors.warning, fontSize: 12))),
                    ]),
                  ),
                ],

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: auth.isLoading ? null : _register,
                    child: auth.isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Create Account'),
                  ),
                ),

                const SizedBox(height: 20),

                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text('Already have an account? ', style: TextStyle(color: AppColors.lightMuted)),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text('Login', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                  ),
                ]),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _roleChip(String role, String emoji, String label) {
    final isSelected = _role == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _role = role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withOpacity(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.lightBorder,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600,
              color: isSelected ? AppColors.primary : AppColors.lightMuted,
            )),
          ]),
        ),
      ),
    );
  }

  Widget _label(String t) => Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.3));
}
