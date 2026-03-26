import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../config/themes.dart';
import '../../../services/auth_service.dart';
import '../../../services/firestore_service.dart';
import '../../../models/student_model.dart';
import 'hireability_screen.dart';
import 'percentile_screen.dart';
import 'training_plan_screen.dart';
import '../../../services/placement_drive_service.dart';

class PlacementDashboard extends StatefulWidget {
  const PlacementDashboard({super.key});

  @override
  State<PlacementDashboard> createState() => _PlacementDashboardState();
}

class _PlacementDashboardState extends State<PlacementDashboard> {
  final _fs = FirestoreService();
  StudentProfile? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = context.read<AuthService>().userModel;
    if (user == null) return;
    final profile = await _fs.getStudentProfile(user.uid);
    setState(() {
      _profile = profile;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Career & Placement'),
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hireability score preview
                  if (_profile != null)
                    _HireabilityPreview(
                            score: _profile!.hireabilityScore.toInt())
                        .animate()
                        .fadeIn()
                        .slideY(begin: 0.2),

                  const SizedBox(height: 24),

                  const Text('Placement Tools',
                      style: TextStyle(
                          fontFamily: 'Syne',
                          fontSize: 18,
                          fontWeight: FontWeight.w700))
                      .animate()
                      .fadeIn(delay: 100.ms),

                  const SizedBox(height: 14),

                  // Feature cards
                  _PlacementFeatureCard(
                    icon: Icons.analytics_rounded,
                    title: 'Hireability Score',
                    subtitle: 'AI-powered multi-dimensional placement score',
                    color: AppColors.primary,
                    badge: _profile != null
                        ? '${_profile!.hireabilityScore.toInt()}%'
                        : null,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const HireabilityScreen()),
                    ),
                  ).animate().fadeIn(delay: 150.ms),

                  _PlacementFeatureCard(
                    icon: Icons.leaderboard_rounded,
                    title: 'Placement Standing',
                    subtitle: 'Your percentile rank + drive eligibility',
                    color: AppColors.secondary,
                    badge: _profile != null
                        ? '${_profile!.overallPercentile}th %ile'
                        : null,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const PercentileScreen()),
                    ),
                  ).animate().fadeIn(delay: 200.ms),

                  _PlacementFeatureCard(
                    icon: Icons.map_rounded,
                    title: 'AI Training Plans',
                    subtitle: 'Personalised day-by-day prep for each drive',
                    color: AppColors.warning,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const PercentileScreen()),
                    ),
                  ).animate().fadeIn(delay: 250.ms),

                  _PlacementFeatureCard(
                    icon: Icons.psychology_rounded,
                    title: 'AI Mentor Chat',
                    subtitle: 'Ask anything about your placement journey',
                    color: AppColors.accent,
                    badge: 'Week 6',
                    onTap: () {},
                  ).animate().fadeIn(delay: 300.ms),

                  _PlacementFeatureCard(
                    icon: Icons.computer_rounded,
                    title: 'Job Simulation',
                    subtitle: 'Complete real work tasks for your target role',
                    color: AppColors.primary,
                    badge: 'Week 9',
                    onTap: () {},
                  ).animate().fadeIn(delay: 350.ms),

                  _PlacementFeatureCard(
                    icon: Icons.record_voice_over_rounded,
                    title: 'Mock Interview',
                    subtitle: 'AI evaluates your answers with feedback',
                    color: AppColors.secondary,
                    badge: 'Week 9',
                    onTap: () {},
                  ).animate().fadeIn(delay: 400.ms),

                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }
}

class _HireabilityPreview extends StatelessWidget {
  final int score;
  const _HireabilityPreview({required this.score});

  @override
  Widget build(BuildContext context) {
    final color = score >= 75
        ? AppColors.secondary
        : score >= 50
            ? AppColors.warning
            : AppColors.accent;
    final verdict = score >= 80
        ? 'Highly Placeable 🚀'
        : score >= 65
            ? 'Good Chances ✅'
            : score >= 45
                ? 'Building Profile ⚡'
                : 'Just Getting Started 📈';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.12), color.withOpacity(0.04)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: score),
            duration: const Duration(milliseconds: 1200),
            builder: (_, val, __) => Text(
              '$val%',
              style: TextStyle(
                fontFamily: 'Syne',
                fontSize: 48,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Hireability Score',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppColors.lightMuted,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(verdict,
                    style: TextStyle(
                        fontFamily: 'Syne',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: color)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: score / 100,
                    backgroundColor: color.withOpacity(0.15),
                    valueColor: AlwaysStoppedAnimation(color),
                    minHeight: 5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlacementFeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final String? badge;
  final VoidCallback onTap;

  const _PlacementFeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkBorder
                : AppColors.lightBorder,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontFamily: 'Syne',
                          fontSize: 14,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.lightMuted)),
                ],
              ),
            ),
            if (badge != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(badge!,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: color)),
              ),
            ] else
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: AppColors.lightMuted),
          ],
        ),
      ),
    );
  }
}
