// recruiter_home.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../config/themes.dart';
import '../auth/login_screen.dart';

class RecruiterHome extends StatelessWidget {
  const RecruiterHome({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().userModel;
    return Scaffold(
      appBar: AppBar(
        title: const Text('SmartPlace — Recruiter'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthService>().logout();
              if (context.mounted) {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()));
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 70, height: 70,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: AppColors.recruiterColor.withOpacity(0.15),
              ),
              child: const Icon(Icons.work_outline,
                  color: AppColors.recruiterColor, size: 36),
            ),
            const SizedBox(height: 20),
            Text(
              'Welcome, ${user?.name ?? 'Recruiter'} 💼',
              style: const TextStyle(
                  fontFamily: 'Syne',
                  fontSize: 22,
                  fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text('Recruiter Portal — Week 8 coming soon!',
                style: TextStyle(color: AppColors.lightMuted)),
          ],
        ),
      ),
    );
  }
}
