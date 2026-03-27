import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../config/themes.dart';
import '../../../services/auth_service.dart';
import '../../../services/firestore_service.dart';
import '../../../services/gemini_service.dart';

class HireabilityScreen extends StatefulWidget {
  const HireabilityScreen({super.key});

  @override
  State<HireabilityScreen> createState() => _HireabilityScreenState();
}

class _HireabilityScreenState extends State<HireabilityScreen> {
  final _gemini = GeminiService();
  final _fs = FirestoreService();
  bool _isLoading = false;
  Map<String, dynamic>? _scores;
  Map<String, dynamic>? _aiAnalysis;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final user = context.read<AuthService>().userModel;
    if (user == null) { setState(() => _isLoading = false); return; }

    final profile = await _fs.getStudentProfile(user.uid);
    if (profile == null) { setState(() => _isLoading = false); return; }

    final data = profile.toMap();
    final scores = await _gemini.calculateHireability(data);
    final analysis = await _gemini.analyseStudentProfile(user.uid, data);

    // Save back to Firestore
    await FirebaseFirestore.instance.collection('students').doc(user.uid).update({
      'hireabilityScore': scores['total'],
      'strongestDomain': analysis['strongestDomain'],
      'weakAreas': analysis['weakAreas'],
      'suitableRoles': analysis['suitableRoles'],
    });

    setState(() {
      _scores = scores;
      _aiAnalysis = analysis;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hireability Score'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _loadData),
        ],
      ),
      body: _isLoading
          ? const _LoadingView()
          : _scores == null
              ? const _EmptyProfile()
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final total = _scores!['total'] as int;
    final color = total >= 75
        ? AppColors.secondary
        : total >= 50
            ? AppColors.warning
            : AppColors.accent;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ScoreHero(score: total, color: color)
              .animate()
              .fadeIn()
              .scale(begin: const Offset(0.85, 0.85)),

          const SizedBox(height: 24),

          const Text('Score Breakdown',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700))
              .animate()
              .fadeIn(delay: 200.ms),

          const SizedBox(height: 14),

          _DimCard(label: 'Resume Strength', score: _scores!['resumeScore'] as int,
              icon: Icons.description_outlined, color: AppColors.primary,
              tip: 'Add certifications and projects to improve')
              .animate().fadeIn(delay: 250.ms),

          _DimCard(label: 'Skill Readiness', score: _scores!['skillScore'] as int,
              icon: Icons.code_rounded, color: AppColors.secondary,
              tip: 'Add more technical skills to your profile')
              .animate().fadeIn(delay: 300.ms),

          _DimCard(label: 'Interview Readiness', score: _scores!['interviewScore'] as int,
              icon: Icons.record_voice_over_outlined, color: AppColors.warning,
              tip: 'Practice mock interviews and get certified')
              .animate().fadeIn(delay: 350.ms),

          _DimCard(label: 'Portfolio Strength', score: _scores!['portfolioScore'] as int,
              icon: Icons.work_outline_rounded, color: AppColors.violet,
              tip: 'Build more projects and complete internships')
              .animate().fadeIn(delay: 400.ms),

          _DimCard(label: 'Attendance', score: _scores!['attendanceScore'] as int,
              icon: Icons.check_circle_outline, color: AppColors.accent,
              tip: 'Maintain above 75% attendance')
              .animate().fadeIn(delay: 450.ms),

          const SizedBox(height: 24),

          if (_aiAnalysis != null) ...[
            const Text('AI Career Analysis',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700))
                .animate().fadeIn(delay: 500.ms),
            const SizedBox(height: 14),
            _AICard(analysis: _aiAnalysis!).animate().fadeIn(delay: 550.ms),
          ],

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _ScoreHero extends StatelessWidget {
  final int score;
  final Color color;
  const _ScoreHero({required this.score, required this.color});

  String get _verdict {
    if (score >= 80) return 'Highly Placeable 🚀';
    if (score >= 65) return 'Good Chances ✅';
    if (score >= 45) return 'Moderate Potential ⚡';
    return 'Needs Improvement 📈';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [color.withOpacity(0.15), color.withOpacity(0.05)]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(children: [
        Text('Hireability Score',
            style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
        const SizedBox(height: 12),
        TweenAnimationBuilder<int>(
          tween: IntTween(begin: 0, end: score),
          duration: const Duration(milliseconds: 1200),
          curve: Curves.easeOutCubic,
          builder: (_, v, __) => Text('$v%',
              style: TextStyle(
                  fontSize: 72, fontWeight: FontWeight.w800, color: color, letterSpacing: -2)),
        ),
        const SizedBox(height: 8),
        Text(_verdict,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: score / 100),
            duration: const Duration(milliseconds: 1400),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => LinearProgressIndicator(
              value: v,
              backgroundColor: color.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 8,
            ),
          ),
        ),
      ]),
    );
  }
}

class _DimCard extends StatelessWidget {
  final String label;
  final int score;
  final IconData icon;
  final Color color;
  final String tip;
  const _DimCard({required this.label, required this.score,
      required this.icon, required this.color, required this.tip});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkBorder
                : AppColors.lightBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
          Text('$score%',
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w800, color: color)),
        ]),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: score / 100),
            duration: const Duration(milliseconds: 1000),
            builder: (_, v, __) => LinearProgressIndicator(
              value: v,
              backgroundColor: color.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 6,
            ),
          ),
        ),
        if (score < 70) ...[
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.lightbulb_outline, size: 13, color: AppColors.warning),
            const SizedBox(width: 4),
            Expanded(child: Text(tip,
                style: const TextStyle(fontSize: 11, color: AppColors.lightMuted))),
          ]),
        ],
      ]),
    );
  }
}

class _AICard extends StatelessWidget {
  final Map<String, dynamic> analysis;
  const _AICard({required this.analysis});

  @override
  Widget build(BuildContext context) {
    final roles = List<String>.from(analysis['suitableRoles'] ?? []);
    final weak = List<String>.from(analysis['weakAreas'] ?? []);
    final actions = List<String>.from(analysis['topActions'] ?? []);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6)),
          child: const Text('AI ANALYSIS',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                  color: AppColors.primary, letterSpacing: 0.8)),
        ),
        const SizedBox(height: 14),

        Text(analysis['profileSummary'] ?? '',
            style: const TextStyle(fontSize: 13, height: 1.7)),

        const SizedBox(height: 14),

        Row(children: [
          const Text('Strongest Domain',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.lightMuted)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6)),
            child: Text(analysis['strongestDomain'] ?? '—',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                    color: AppColors.secondary)),
          ),
        ]),

        if (roles.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text('Best Fit Roles',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.lightMuted)),
          const SizedBox(height: 6),
          Wrap(spacing: 6, runSpacing: 6,
              children: roles.map((r) => _tag(r, AppColors.primary)).toList()),
        ],

        if (weak.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text('Areas to Improve',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.lightMuted)),
          const SizedBox(height: 6),
          Wrap(spacing: 6, runSpacing: 6,
              children: weak.map((w) => _tag(w, AppColors.warning)).toList()),
        ],

        if (actions.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text('Top Actions',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.lightMuted)),
          const SizedBox(height: 8),
          ...actions.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    width: 20, height: 20,
                    decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.15),
                        shape: BoxShape.circle),
                    child: Center(
                        child: Text('${e.key + 1}',
                            style: const TextStyle(fontSize: 10,
                                fontWeight: FontWeight.w700, color: AppColors.primary))),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(e.value,
                      style: const TextStyle(fontSize: 13, height: 1.4))),
                ]),
              )),
        ],
      ]),
    );
  }

  Widget _tag(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withOpacity(0.25))),
        child: Text(text,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
      );
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        CircularProgressIndicator(color: AppColors.primary),
        SizedBox(height: 20),
        Text('AI is analysing your profile...',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        SizedBox(height: 8),
        Text('This takes a few seconds',
            style: TextStyle(color: AppColors.lightMuted, fontSize: 13)),
      ]),
    );
  }
}

class _EmptyProfile extends StatelessWidget {
  const _EmptyProfile();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.person_outline, size: 64, color: AppColors.lightMuted),
        SizedBox(height: 16),
        Text('Complete your profile first',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        SizedBox(height: 8),
        Text('Add skills, projects and internships\nto get your AI score',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.lightMuted, fontSize: 13)),
      ]),
    );
  }
}
