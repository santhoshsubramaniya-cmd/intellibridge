import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/themes.dart';
import '../../config/constants.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';

class RecruiterHome extends StatefulWidget {
  const RecruiterHome({super.key});

  @override
  State<RecruiterHome> createState() => _RecruiterHomeState();
}

class _RecruiterHomeState extends State<RecruiterHome> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pages = [
      const _RecruiterDashboard(),
      const _PostJobTab(),
      const _ApplicantsTab(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          border: Border(
              top: BorderSide(
                  color: isDark
                      ? AppColors.darkBorder
                      : AppColors.lightBorder)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(0, Icons.dashboard_rounded, 'Dashboard'),
                _navItem(1, Icons.post_add_rounded, 'Post Job'),
                _navItem(2, Icons.people_rounded, 'Applicants'),
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
            const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.recruiterColor.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: isActive
                    ? AppColors.recruiterColor
                    : AppColors.lightMuted,
                size: 22),
            const SizedBox(height: 3),
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: isActive
                        ? FontWeight.w700
                        : FontWeight.w400,
                    color: isActive
                        ? AppColors.recruiterColor
                        : AppColors.lightMuted)),
          ],
        ),
      ),
    );
  }
}

// ─── Recruiter Dashboard ──────────────────────────
class _RecruiterDashboard extends StatelessWidget {
  const _RecruiterDashboard();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().userModel;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recruiter Portal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await context.read<AuthService>().logout();
              if (context.mounted) {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(
                        builder: (_) => const LoginScreen()));
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
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AppColors.recruiterColor,
                    Color(0xFFE67700)
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.recruiterColor.withOpacity(0.3),
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
                        const Text('Welcome back,',
                            style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13)),
                        const SizedBox(height: 4),
                        Text(user?.name ?? 'Recruiter',
                            style: const TextStyle(
                                fontFamily: 'Syne',
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(height: 6),
                        const Text(
                            'Find the best placement-ready students',
                            style: TextStyle(
                                color: Colors.white60,
                                fontSize: 12)),
                      ],
                    ),
                  ),
                  const Icon(Icons.work_rounded,
                      color: Colors.white38, size: 48),
                ],
              ),
            ).animate().fadeIn().slideY(begin: 0.2),

            const SizedBox(height: 24),

            // Stats
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('jobs')
                  .where('postedBy',
                      isEqualTo: user?.uid ?? '')
                  .snapshots(),
              builder: (context, snap) {
                final jobCount = snap.data?.docs.length ?? 0;
                return Row(
                  children: [
                    _StatBox(
                        label: 'Jobs Posted',
                        value: '$jobCount',
                        color: AppColors.primary),
                    const SizedBox(width: 12),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('applications')
                          .snapshots(),
                      builder: (context, appSnap) {
                        final appCount =
                            appSnap.data?.docs.length ?? 0;
                        return _StatBox(
                            label: 'Total Applicants',
                            value: '$appCount',
                            color: AppColors.secondary);
                      },
                    ),
                    const SizedBox(width: 12),
                    _StatBox(
                        label: 'AI Ranked',
                        value: '✓',
                        color: AppColors.warning),
                  ],
                );
              },
            ).animate().fadeIn(delay: 200.ms),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatBox(
      {required this.label, required this.value, required this.color});

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
          children: [
            Text(value,
                style: TextStyle(
                    fontFamily: 'Syne',
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: color)),
            Text(label,
                style: const TextStyle(
                    fontSize: 10, color: AppColors.lightMuted),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ─── Post Job Tab ─────────────────────────────────
class _PostJobTab extends StatefulWidget {
  const _PostJobTab();

  @override
  State<_PostJobTab> createState() => _PostJobTabState();
}

class _PostJobTabState extends State<_PostJobTab> {
  final _titleCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _skillsCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _packageCtrl = TextEditingController();
  double _minCgpa = 6.5;
  bool _isPosting = false;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().userModel;

    return Scaffold(
      appBar: AppBar(title: const Text('Post a Job')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _field(_titleCtrl, 'Job Title',
                'e.g. Junior Software Engineer', Icons.work_outline),
            _field(_companyCtrl, 'Company Name', 'Your Company Ltd.',
                Icons.business_outlined),
            _field(_locationCtrl, 'Location',
                'Bangalore / Remote', Icons.location_on_outlined),
            _field(_packageCtrl, 'Package',
                'e.g. 4.5 LPA', Icons.currency_rupee),
            _field(_skillsCtrl, 'Required Skills (comma separated)',
                'Python, SQL, Machine Learning', Icons.code_rounded),
            _field(_descCtrl, 'Job Description',
                'Describe the role...', Icons.description_outlined,
                maxLines: 4),

            const SizedBox(height: 8),
            Row(
              children: [
                const Expanded(
                    child: Text('Minimum CGPA',
                        style: TextStyle(
                            fontWeight: FontWeight.w600))),
                Text(_minCgpa.toStringAsFixed(1),
                    style: const TextStyle(
                        fontFamily: 'Syne',
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        fontSize: 18)),
              ],
            ),
            Slider(
              value: _minCgpa,
              min: 5.0,
              max: 9.5,
              divisions: 18,
              activeColor: AppColors.primary,
              onChanged: (v) => setState(() => _minCgpa = v),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.recruiterColor),
                onPressed: _isPosting
                    ? null
                    : () => _post(user?.uid ?? '',
                        user?.name ?? 'Recruiter'),
                icon: _isPosting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_rounded),
                label: Text(
                    _isPosting ? 'Posting...' : 'Post Job'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label,
      String hint, IconData icon,
      {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3)),
          const SizedBox(height: 6),
          TextField(
            controller: ctrl,
            maxLines: maxLines,
            decoration: InputDecoration(
                hintText: hint, prefixIcon: Icon(icon)),
          ),
        ],
      ),
    );
  }

  Future<void> _post(String userId, String recruiterName) async {
    if (_titleCtrl.text.isEmpty || _companyCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please fill title and company')),
      );
      return;
    }
    setState(() => _isPosting = true);

    final skills = _skillsCtrl.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    await FirebaseFirestore.instance.collection('jobs').add({
      'title': _titleCtrl.text.trim(),
      'company': _companyCtrl.text.trim(),
      'location': _locationCtrl.text.trim(),
      'package': _packageCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'requiredSkills': skills,
      'minCgpa': _minCgpa,
      'postedBy': userId,
      'recruiterName': recruiterName,
      'postedAt': FieldValue.serverTimestamp(),
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Job posted successfully!'),
          backgroundColor: AppColors.secondary,
        ),
      );
      _titleCtrl.clear();
      _companyCtrl.clear();
      _locationCtrl.clear();
      _packageCtrl.clear();
      _skillsCtrl.clear();
      _descCtrl.clear();
    }
    setState(() => _isPosting = false);
  }
}

// ─── Applicants Tab ───────────────────────────────
class _ApplicantsTab extends StatelessWidget {
  const _ApplicantsTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Applicants')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('applications')
            .orderBy('appliedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline,
                      size: 64, color: AppColors.lightMuted),
                  SizedBox(height: 16),
                  Text('No applicants yet',
                      style: TextStyle(
                          fontFamily: 'Syne',
                          fontSize: 18,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final score = data['hireabilityScore'] ?? 0;
              final color = score >= 75
                  ? AppColors.secondary
                  : score >= 50
                      ? AppColors.warning
                      : AppColors.accent;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: color.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          (data['studentName'] ?? 'S')[0]
                              .toUpperCase(),
                          style: TextStyle(
                              fontFamily: 'Syne',
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              color: color),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                              data['studentName'] ??
                                  'Student',
                              style: const TextStyle(
                                  fontFamily: 'Syne',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14)),
                          Text(
                              data['jobTitle'] ?? 'Position',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.lightMuted)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.end,
                      children: [
                        Text('$score%',
                            style: TextStyle(
                                fontFamily: 'Syne',
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                                color: color)),
                        const Text('Hireability',
                            style: TextStyle(
                                fontSize: 10,
                                color: AppColors.lightMuted)),
                      ],
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(
                      delay:
                          Duration(milliseconds: i * 60))
                  .slideX(begin: 0.1);
            },
          );
        },
      ),
    );
  }
}
