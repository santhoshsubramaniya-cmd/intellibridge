import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../config/themes.dart';
import '../../../services/auth_service.dart';
import '../../../services/firestore_service.dart';
import '../../../services/gemini_service.dart';
import '../../../models/student_model.dart';

class HireabilityScreen extends StatefulWidget {
  const HireabilityScreen({super.key});

  @override
  State<HireabilityScreen> createState() => _HireabilityScreenState();
}

class _HireabilityScreenState extends State<HireabilityScreen> {
  final _fs = FirestoreService();
  final _gemini = GeminiService();

  StudentProfile? _profile;
  Map<String, dynamic> _analysis = {};
  bool _isLoading = true;
  bool _isAnalysing = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = context.read<AuthService>().userModel;
    if (user == null) return;
    final profile = await _fs.getStudentProfile(user.uid);
    if (mounted) {
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    }
  }

  Future<void> _runAnalysis() async {
    final user = context.read<AuthService>().userModel;
    if (user == null) return;
    setState(() => _isAnalysing = true);

    final result = await _gemini.analyseStudentProfile(user.uid);

    // Refresh profile after analysis
    final updated = await _fs.getStudentProfile(user.uid);

    if (mounted) {
      setState(() {
        _analysis = result;
        _profile = updated;
        _isAnalysing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hireability Score'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: _isAnalysing ? null : _runAnalysis,
              icon: _isAnalysing
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary))
                  : const Icon(Icons.auto_awesome_rounded,
                      size: 16, color: AppColors.primary),
              label: Text(
                _isAnalysing ? 'Analysing...' : 'Run AI',
                style: const TextStyle(
                    color: AppColors.primary, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main score card
                  _HireabilityScoreCard(profile: _profile)
                      .animate()
                      .fadeIn()
                      .slideY(begin: 0.2),

                  const SizedBox(height: 24),

                  // 4-dimension breakdown
                  if (_profile != null) ...[
                    const Text('AI Dimension Breakdown',
                            style: TextStyle(
                                fontFamily: 'Syne',
                                fontSize: 18,
                                fontWeight: FontWeight.w700))
                        .animate()
                        .fadeIn(delay: 100.ms),
                    const SizedBox(height: 14),
                    _DimensionBreakdown(profile: _profile!)
                        .animate()
                        .fadeIn(delay: 150.ms),
                    const SizedBox(height: 24),
                  ],

                  // AI analysis results
                  if (_analysis.isNotEmpty) ...[
                    _AIAnalysisCard(analysis: _analysis)
                        .animate()
                        .fadeIn()
                        .slideY(begin: 0.1),
                    const SizedBox(height: 24),
                  ],

                  // Profile stats
                  if (_profile != null) ...[
                    const Text('Profile Components',
                            style: TextStyle(
                                fontFamily: 'Syne',
                                fontSize: 18,
                                fontWeight: FontWeight.w700))
                        .animate()
                        .fadeIn(delay: 200.ms),
                    const SizedBox(height: 14),
                    _ProfileComponents(profile: _profile!)
                        .animate()
                        .fadeIn(delay: 250.ms),
                    const SizedBox(height: 24),
                  ],

                  // Run AI CTA if no analysis yet
                  if (_analysis.isEmpty && !_isAnalysing) ...[
                    _RunAnalysisBanner(onTap: _runAnalysis)
                        .animate()
                        .fadeIn(delay: 300.ms),
                    const SizedBox(height: 24),
                  ],

                  // Suitable roles
                  if (_profile != null &&
                      _profile!.suitableRoles.isNotEmpty) ...[
                    const Text('Suitable Roles for You',
                            style: TextStyle(
                                fontFamily: 'Syne',
                                fontSize: 18,
                                fontWeight: FontWeight.w700))
                        .animate()
                        .fadeIn(delay: 350.ms),
                    const SizedBox(height: 14),
                    _SuitableRoles(roles: _profile!.suitableRoles)
                        .animate()
                        .fadeIn(delay: 400.ms),
                    const SizedBox(height: 24),
                  ],

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}

// ─── Main Score Card ──────────────────────────────
class _HireabilityScoreCard extends StatelessWidget {
  final StudentProfile? profile;
  const _HireabilityScoreCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final score = profile?.hireabilityScore.toInt() ?? 0;
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

    final tip = score >= 80
        ? 'You are in great shape! Focus on interview prep now.'
        : score >= 65
            ? 'Strong profile. Add 1–2 more projects or a certification.'
            : score >= 45
                ? 'Add internship experience and polish your skills list.'
                : 'Start with certifications and personal projects.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: score),
            duration: const Duration(milliseconds: 1400),
            curve: Curves.easeOut,
            builder: (_, val, __) => Text(
              '$val%',
              style: const TextStyle(
                fontFamily: 'Syne',
                fontSize: 80,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(verdict,
              style: const TextStyle(
                  fontFamily: 'Syne',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score / 100,
              backgroundColor: Colors.white.withOpacity(0.25),
              valueColor:
                  const AlwaysStoppedAnimation(Colors.white),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_rounded,
                    color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(tip,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          height: 1.5)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Dimension Breakdown ──────────────────────────
class _DimensionBreakdown extends StatelessWidget {
  final StudentProfile profile;
  const _DimensionBreakdown({required this.profile});

  @override
  Widget build(BuildContext context) {
    final score = profile.hireabilityScore;
    // Approximate dimension scores
    final dims = [
      {
        'label': 'Resume Strength',
        'score': (score * 0.28).clamp(0, 100),
        'icon': Icons.description_rounded,
        'color': AppColors.primary,
        'tip': 'Skills, projects, and certifications',
      },
      {
        'label': 'Skill Readiness',
        'score': (score * 0.25).clamp(0, 100),
        'icon': Icons.code_rounded,
        'color': AppColors.secondary,
        'tip': 'Technical and domain expertise',
      },
      {
        'label': 'Interview Readiness',
        'score': (score * 0.22).clamp(0, 100),
        'icon': Icons.record_voice_over_rounded,
        'color': AppColors.warning,
        'tip': 'Communication and problem solving',
      },
      {
        'label': 'Portfolio Strength',
        'score': (score * 0.25).clamp(0, 100),
        'icon': Icons.work_rounded,
        'color': AppColors.accent,
        'tip': 'Projects, internships, and experience',
      },
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: dims
          .map((d) => _DimensionTile(
                label: d['label'] as String,
                score: (d['score'] as double).toInt(),
                icon: d['icon'] as IconData,
                color: d['color'] as Color,
                tip: d['tip'] as String,
              ))
          .toList(),
    );
  }
}

class _DimensionTile extends StatelessWidget {
  final String label, tip;
  final int score;
  final IconData icon;
  final Color color;
  const _DimensionTile(
      {required this.label,
      required this.score,
      required this.icon,
      required this.color,
      required this.tip});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
              Text('$score%',
                  style: TextStyle(
                      fontFamily: 'Syne',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: color)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: score / 100,
              backgroundColor: color.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(
                  fontFamily: 'Syne',
                  fontWeight: FontWeight.w700,
                  fontSize: 12)),
          Text(tip,
              style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.lightMuted,
                  height: 1.4)),
        ],
      ),
    );
  }
}

// ─── AI Analysis Card ─────────────────────────────
class _AIAnalysisCard extends StatelessWidget {
  final Map<String, dynamic> analysis;
  const _AIAnalysisCard({required this.analysis});

  @override
  Widget build(BuildContext context) {
    final weakAreas = List<String>.from(analysis['weakAreas'] ?? []);
    final topSkills =
        List<String>.from(analysis['topSkillsToLearn'] ?? []);
    final summary = analysis['profileSummary'] ?? '';
    final action = analysis['immediateAction'] ?? '';
    final strongDomain = analysis['strongestDomain'] ?? '';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.08),
            AppColors.secondary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_awesome_rounded,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AI Analysis',
                      style: TextStyle(
                          fontFamily: 'Syne',
                          fontWeight: FontWeight.w700,
                          fontSize: 15)),
                  Text('Powered by Gemini',
                      style: TextStyle(
                          fontSize: 11,
                          color: AppColors.lightMuted)),
                ],
              ),
            ],
          ),

          if (summary.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(summary,
                style: const TextStyle(
                    fontSize: 13,
                    height: 1.6,
                    color: AppColors.lightMuted)),
          ],

          if (strongDomain.isNotEmpty) ...[
            const SizedBox(height: 14),
            _AnalysisRow(
              icon: Icons.star_rounded,
              color: AppColors.warning,
              label: 'Strongest Domain',
              value: strongDomain,
            ),
          ],

          if (action.isNotEmpty) ...[
            const SizedBox(height: 10),
            _AnalysisRow(
              icon: Icons.bolt_rounded,
              color: AppColors.secondary,
              label: 'Immediate Action',
              value: action,
            ),
          ],

          if (weakAreas.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text('Weak Areas',
                style: TextStyle(
                    fontFamily: 'Syne',
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: weakAreas
                  .map((a) => _Tag(label: a, color: AppColors.accent))
                  .toList(),
            ),
          ],

          if (topSkills.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text('Skills to Learn Next',
                style: TextStyle(
                    fontFamily: 'Syne',
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: topSkills
                  .map((s) => _Tag(label: s, color: AppColors.primary))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _AnalysisRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label, value;
  const _AnalysisRow(
      {required this.icon,
      required this.color,
      required this.label,
      required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: color)),
                Text(value,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color)),
    );
  }
}

// ─── Profile Components ───────────────────────────
class _ProfileComponents extends StatelessWidget {
  final StudentProfile profile;
  const _ProfileComponents({required this.profile});

  @override
  Widget build(BuildContext context) {
    final components = [
      {
        'icon': Icons.school_rounded,
        'label': 'CGPA',
        'value': profile.cgpa.toStringAsFixed(1),
        'subtitle': 'Academic performance',
        'color': AppColors.primary,
      },
      {
        'icon': Icons.code_rounded,
        'label': 'Skills',
        'value': '${profile.skills.length}',
        'subtitle': 'Technical skills listed',
        'color': AppColors.secondary,
      },
      {
        'icon': Icons.business_center_rounded,
        'label': 'Internships',
        'value': '${profile.internships.length}',
        'subtitle': 'Work experience',
        'color': AppColors.warning,
      },
      {
        'icon': Icons.folder_rounded,
        'label': 'Projects',
        'value': '${profile.projectCount}',
        'subtitle': 'Portfolio projects',
        'color': AppColors.accent,
      },
      {
        'icon': Icons.verified_rounded,
        'label': 'Certs',
        'value': '${profile.certCount}',
        'subtitle': 'Certifications earned',
        'color': AppColors.primary,
      },
      {
        'icon': Icons.event_available_rounded,
        'label': 'Attendance',
        'value': '${profile.attendance}%',
        'subtitle': 'Class attendance rate',
        'color': AppColors.secondary,
      },
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 0.9,
      children: components
          .map((c) => _ComponentTile(
                icon: c['icon'] as IconData,
                label: c['label'] as String,
                value: c['value'] as String,
                subtitle: c['subtitle'] as String,
                color: c['color'] as Color,
              ))
          .toList(),
    );
  }
}

class _ComponentTile extends StatelessWidget {
  final IconData icon;
  final String label, value, subtitle;
  final Color color;
  const _ComponentTile(
      {required this.icon,
      required this.label,
      required this.value,
      required this.subtitle,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 22),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                      fontFamily: 'Syne',
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: color)),
              Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 11)),
              Text(subtitle,
                  style: const TextStyle(
                      fontSize: 9,
                      color: AppColors.lightMuted,
                      height: 1.3)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Run Analysis Banner ──────────────────────────
class _RunAnalysisBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _RunAnalysisBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.secondary],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Row(
          children: [
            Icon(Icons.auto_awesome_rounded,
                color: Colors.white, size: 28),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Run AI Profile Analysis',
                      style: TextStyle(
                          fontFamily: 'Syne',
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15)),
                  SizedBox(height: 2),
                  Text(
                    'Get personalised insights, weak areas, and a career roadmap powered by Gemini AI.',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        height: 1.5),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white60, size: 16),
          ],
        ),
      ),
    );
  }
}

// ─── Suitable Roles ───────────────────────────────
class _SuitableRoles extends StatelessWidget {
  final List<String> roles;
  const _SuitableRoles({required this.roles});

  @override
  Widget build(BuildContext context) {
    final roleColors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.warning,
      AppColors.accent,
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: roles.asMap().entries.map((e) {
        final color = roleColors[e.key % roleColors.length];
        return Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.work_outline_rounded,
                  color: color, size: 14),
              const SizedBox(width: 6),
              Text(e.value,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: color)),
            ],
          ),
        );
      }).toList(),
    );
  }
}
