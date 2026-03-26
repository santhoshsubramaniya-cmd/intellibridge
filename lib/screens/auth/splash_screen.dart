import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/themes.dart';
import '../../services/auth_service.dart';
import 'login_screen.dart';
import '../student/student_home.dart';
import '../faculty/faculty_home.dart';
import '../admin/admin_home.dart';
import '../recruiter/recruiter_home.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _goTo(const LoginScreen());
      return;
    }

    final authService = context.read<AuthService>();
    final profile = await authService.fetchUserProfile(user.uid);

    if (!mounted) return;

    if (profile == null) {
      _goTo(const LoginScreen());
      return;
    }

    // Route based on role
    switch (profile.role) {
      case 'student':
        _goTo(const StudentHome());
        break;
      case 'faculty':
        _goTo(const FacultyHome());
        break;
      case 'admin':
        _goTo(const AdminHome());
        break;
      case 'recruiter':
        _goTo(const RecruiterHome());
        break;
      default:
        _goTo(const LoginScreen());
    }
  }

  void _goTo(Widget screen) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Icon
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.4),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.school_rounded,
                color: Colors.white,
                size: 48,
              ),
            )
                .animate()
                .fadeIn(duration: 600.ms)
                .scale(begin: const Offset(0.5, 0.5)),

            const SizedBox(height: 24),

            // App Name
            const Text(
              'SmartPlace',
              style: TextStyle(
                fontFamily: 'Syne',
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -1,
              ),
            )
                .animate()
                .fadeIn(delay: 300.ms, duration: 600.ms)
                .slideY(begin: 0.3),

            const SizedBox(height: 8),

            // Tagline
            const Text(
              'Campus to Career — Powered by AI',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.darkMuted,
                letterSpacing: 0.5,
              ),
            )
                .animate()
                .fadeIn(delay: 500.ms, duration: 600.ms),

            const SizedBox(height: 60),

            // Loading indicator
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation(AppColors.primary),
              ),
            )
                .animate()
                .fadeIn(delay: 800.ms),
          ],
        ),
      ),
    );
  }
}
