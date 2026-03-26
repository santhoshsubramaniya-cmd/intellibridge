import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/themes.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_sevice.dart';
import '../auth/login_screen.dart';
import 'campus/campus_dashboard.dart';
import 'campus/notes_screen.dart';
import 'campus/results_screen.dart';
import 'campus/announcements_screen.dart';
import 'alerts/alerts_screen.dart';

class StudentHome extends StatefulWidget {
  const StudentHome({super.key});

  @override
  State<StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome> {
  int _currentIndex = 0;
  final _firestoreService = FirestoreService();

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const CampusDashboard(),
      const NotesScreen(),
      const ResultsScreen(),
      const AnnouncementsScreen(),
      const AlertsScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().userModel;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(0, Icons.home_rounded, 'Home'),
                _navItem(1, Icons.menu_book_rounded, 'Notes'),
                _navItem(2, Icons.bar_chart_rounded, 'Results'),
                _navItem(3, Icons.campaign_rounded, 'News'),
                _navItem(4, Icons.notifications_rounded, 'Alerts'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? AppColors.primary : AppColors.lightMuted,
              size: 22,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight:
                    isActive ? FontWeight.w700 : FontWeight.w400,
                color:
                    isActive ? AppColors.primary : AppColors.lightMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
