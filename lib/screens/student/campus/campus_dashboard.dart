import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../config/themes.dart';
import '../../../services/auth_service.dart';
import '../../../services/firestore_sevice.dart';
import '../../auth/login_screen.dart';

class CampusDashboard extends StatelessWidget {
  const CampusDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().userModel;
    final fs = FirestoreService();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9),
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                ),
              ),
              child: const Icon(Icons.school_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Text('SmartPlace'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await context.read<AuthService>().logout();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome card
            _WelcomeCard(name: user?.name ?? 'Student',
                course: user?.course ?? '',
                semester: user?.semester ?? 1)
                .animate()
                .fadeIn()
                .slideY(begin: 0.2),

            const SizedBox(height: 24),

            // Quick stats
            const Text(
              'Your Profile',
              style: TextStyle(
                fontFamily: 'Syne',
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ).animate().fadeIn(delay: 100.ms),

            const SizedBox(height: 12),

            Row(
              children: [
                _StatCard(
                  icon: Icons.school_outlined,
                  label: 'Course',
                  value: user?.course?.split(' ').first ?? '—',
                  color: AppColors.primary,
                ),
                const SizedBox(width: 12),
                _StatCard(
                  icon: Icons.calendar_today_outlined,
                  label: 'Semester',
                  value: 'Sem ${user?.semester ?? '—'}',
                  color: AppColors.secondary,
                ),
                const SizedBox(width: 12),
                _StatCard(
                  icon: Icons.person_outline,
                  label: 'Role',
                  value: 'Student',
                  color: AppColors.warning,
                ),
              ],
            ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 28),

            // Quick actions
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontFamily: 'Syne',
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ).animate().fadeIn(delay: 300.ms),

            const SizedBox(height: 12),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                _ActionCard(
                  icon: Icons.menu_book_rounded,
                  label: 'Study Notes',
                  subtitle: 'Access faculty notes',
                  color: AppColors.primary,
                  onTap: () {},
                ),
                _ActionCard(
                  icon: Icons.bar_chart_rounded,
                  label: 'My Results',
                  subtitle: 'View semester marks',
                  color: AppColors.secondary,
                  onTap: () {},
                ),
                _ActionCard(
                  icon: Icons.campaign_rounded,
                  label: 'Announcements',
                  subtitle: 'Latest campus news',
                  color: AppColors.warning,
                  onTap: () {},
                ),
                _ActionCard(
                  icon: Icons.work_outline_rounded,
                  label: 'Placement',
                  subtitle: 'Coming in Week 3',
                  color: AppColors.accent,
                  onTap: () {},
                ),
              ],
            ).animate().fadeIn(delay: 400.ms),

            const SizedBox(height: 28),

            // Latest announcements preview
            const Text(
              'Latest Announcements',
              style: TextStyle(
                fontFamily: 'Syne',
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ).animate().fadeIn(delay: 500.ms),

            const SizedBox(height: 12),

            StreamBuilder(
              stream: FirestoreService().getAnnouncements(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs.take(3).toList();
                if (docs.isEmpty) {
                  return _EmptyState(
                    icon: Icons.campaign_outlined,
                    message: 'No announcements yet',
                  );
                }
                return Column(
                  children: docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return _AnnouncementPreview(
                      title: data['title'] ?? 'Announcement',
                      message: data['message'] ?? '',
                      postedBy: data['postedBy'] ?? '',
                    );
                  }).toList(),
                );
              },
            ).animate().fadeIn(delay: 600.ms),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  final String name;
  final String course;
  final int semester;
  const _WelcomeCard(
      {required this.name,
      required this.course,
      required this.semester});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF4B44CC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  style: const TextStyle(
                    fontFamily: 'Syne',
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$course · Semester $semester',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_rounded,
                color: Colors.white, size: 30),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatCard(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Syne',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.lightMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const _ActionCard(
      {required this.icon,
      required this.label,
      required this.subtitle,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Syne',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.lightMuted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AnnouncementPreview extends StatelessWidget {
  final String title;
  final String message;
  final String postedBy;
  const _AnnouncementPreview(
      {required this.title,
      required this.message,
      required this.postedBy});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.campaign_rounded,
              color: AppColors.warning, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.lightMuted),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 36, color: AppColors.lightMuted),
          const SizedBox(height: 8),
          Text(message,
              style: const TextStyle(
                  color: AppColors.lightMuted, fontSize: 13)),
        ],
      ),
    );
  }
}
