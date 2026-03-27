import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../config/themes.dart';
import '../../../services/auth_service.dart';
import '../../../services/gemini_service.dart';
import '../../../services/firestore_service.dart';

class AIProfileScreen extends StatefulWidget {
  const AIProfileScreen({super.key});

  @override
  State<AIProfileScreen> createState() => _AIProfileScreenState();
}

class _AIProfileScreenState extends State<AIProfileScreen> {
  final _gemini = GeminiService();
  final _fs = FirestoreService();
  Map<String, dynamic>? _studentData;
  bool _isAnalysing = false;
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
    if (mounted) {
      setState(() {
        _studentData = profile?.toMap();
        _isLoading = false;
      });
    }
  }

  Future<void> _runAnalysis() async {
    final user = context.read<AuthService>().userModel;
    if (user == null) return;
    setState(() => _isAnalysing = true);

    // FIX: analyseStudentProfile requires (userId, data) — two params
    final data = _studentData ?? {};
    final result = await _gemini.analyseStudentProfile(user.uid, data);

    if (mounted) {
      setState(() {
        _studentData = {...data, ...result};
        _isAnalysing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Profile'),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _isAnalysing ? null : _runAnalysis)
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeroCard(
                    score: (_studentData?['hireabilityScore'] ?? 0.0)
                        .toDouble(),
                    percentile:
                        _studentData?['overallPercentile'] ?? 0,
                    isAnalysing: _isAnalysing,
                    onAnalyse: _runAnalysis,
                  ).animate().fadeIn(),

                  if (_studentData?['hireabilityBreakdown'] != null) ...[
                    const SizedBox(height: 24),
                    const Text('Breakdown',
                            style: TextStyle(
                                fontFamily: 'Syne',
                                fontSize: 18,
                                fontWeight: FontWeight.w700))
                        .animate()
                        .fadeIn(delay: 100.ms),
                    const SizedBox(height: 12),
                    _BreakdownCard(
                            breakdown: Map<String, dynamic>.from(
                                _studentData!['hireabilityBreakdown']))
                        .animate()
                        .fadeIn(delay: 200.ms),
                  ],

                  if (_studentData?['profileSummary'] != null) ...[
                    const SizedBox(height: 20),
                    _InsightCard(
                            title: '🤖 AI Assessment',
                            content: _studentData!['profileSummary'],
                            color: AppColors.primary)
                        .animate()
                        .fadeIn(delay: 300.ms),
                  ],

                  if (_studentData?['immediateAction'] != null) ...[
                    const SizedBox(height: 12),
                    _InsightCard(
                            title: '⚡ Do This Now',
                            content: _studentData!['immediateAction'],
                            color: AppColors.accent)
                        .animate()
                        .fadeIn(delay: 350.ms),
                  ],

                  if (_studentData?['suitableRoles'] != null) ...[
                    const SizedBox(height: 20),
                    const Text('Best Roles For You',
                            style: TextStyle(
                                fontFamily: 'Syne',
                                fontSize: 18,
                                fontWeight: FontWeight.w700))
                        .animate()
                        .fadeIn(delay: 400.ms),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List<String>.from(
                              _studentData!['suitableRoles'])
                          .map((r) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                    color: AppColors.secondary
                                        .withOpacity(0.1),
                                    borderRadius:
                                        BorderRadius.circular(20),
                                    border: Border.all(
                                        color: AppColors.secondary
                                            .withOpacity(0.3))),
                                child: Text(r,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.secondary)),
                              ))
                          .toList(),
                    ).animate().fadeIn(delay: 450.ms),
                  ],

                  if (_studentData?['topSkillsToLearn'] != null) ...[
                    const SizedBox(height: 20),
                    const Text('Top Skills to Learn',
                            style: TextStyle(
                                fontFamily: 'Syne',
                                fontSize: 18,
                                fontWeight: FontWeight.w700))
                        .animate()
                        .fadeIn(delay: 500.ms),
                    const SizedBox(height: 10),
                    ...List<String>.from(
                            _studentData!['topSkillsToLearn'])
                        .asMap()
                        .entries
                        .map((e) => Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius:
                                      BorderRadius.circular(10),
                                  border: Border.all(
                                      color: Theme.of(context)
                                                  .brightness ==
                                              Brightness.dark
                                          ? AppColors.darkBorder
                                          : AppColors.lightBorder)),
                              child: Row(children: [
                                Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                        color: AppColors.primary
                                            .withOpacity(0.12),
                                        shape: BoxShape.circle),
                                    child: Center(
                                        child: Text('${e.key + 1}',
                                            style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight:
                                                    FontWeight.w700,
                                                color:
                                                    AppColors.primary)))),
                                const SizedBox(width: 12),
                                Text(e.value,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14)),
                              ]),
                            ).animate().fadeIn(
                                delay: Duration(
                                    milliseconds: 500 + e.key * 80))),
                  ],

                  if (_studentData?['profileSummary'] == null)
                    _CTACard(
                            isAnalysing: _isAnalysing,
                            onTap: _runAnalysis)
                        .animate()
                        .fadeIn(),

                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final double score;
  final int percentile;
  final bool isAnalysing;
  final VoidCallback onAnalyse;
  const _HeroCard(
      {required this.score,
      required this.percentile,
      required this.isAnalysing,
      required this.onAnalyse});

  Color get color => score >= 75
      ? AppColors.secondary
      : score >= 50
          ? AppColors.warning
          : AppColors.accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            AppColors.primary.withOpacity(0.12),
            AppColors.secondary.withOpacity(0.08)
          ]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withOpacity(0.2))),
      child: Column(children: [
        const Text('Hireability Score',
            style: TextStyle(
                fontSize: 13,
                color: AppColors.lightMuted,
                letterSpacing: 0.5)),
        const SizedBox(height: 12),
        isAnalysing
            ? const Column(children: [
                SizedBox(
                    height: 60,
                    width: 60,
                    child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation(AppColors.primary))),
                SizedBox(height: 12),
                Text('Gemini AI analysing...',
                    style: TextStyle(
                        color: AppColors.lightMuted, fontSize: 13))
              ])
            : Column(children: [
                Text('${score.toStringAsFixed(0)}%',
                    style: TextStyle(
                        fontFamily: 'Syne',
                        fontSize: 64,
                        fontWeight: FontWeight.w800,
                        color: color,
                        height: 1)),
                const SizedBox(height: 8),
                Text(
                    score >= 75
                        ? '🚀 Highly Placeable!'
                        : score >= 50
                            ? '⚡ Good Progress'
                            : '📈 Needs Improvement',
                    style: TextStyle(
                        fontFamily: 'Syne',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: color)),
                const SizedBox(height: 6),
                Text('Top $percentile% of students',
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.lightMuted)),
                const SizedBox(height: 14),
                ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                        value: score / 100,
                        backgroundColor: color.withOpacity(0.15),
                        valueColor: AlwaysStoppedAnimation(color),
                        minHeight: 8)),
              ]),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: isAnalysing ? null : onAnalyse,
            icon: const Icon(Icons.auto_awesome_rounded, size: 16),
            label:
                Text(isAnalysing ? 'Analysing...' : 'Run AI Analysis'),
          ),
        ),
      ]),
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  final Map<String, dynamic> breakdown;
  const _BreakdownCard({required this.breakdown});

  @override
  Widget build(BuildContext context) {
    final items = [
      ['Resume Strength', breakdown['resumeStrength'] ?? 0, AppColors.primary],
      [
        'Skill Readiness',
        breakdown['skillReadiness'] ?? 0,
        AppColors.secondary
      ],
      [
        'Interview Readiness',
        breakdown['interviewReadiness'] ?? 0,
        AppColors.warning
      ],
      [
        'Portfolio Strength',
        breakdown['portfolioStrength'] ?? 0,
        AppColors.accent
      ],
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkBorder
                  : AppColors.lightBorder)),
      child: Column(
          children: items
              .map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Expanded(
                                child: Text(item[0] as String,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600))),
                            Text('${item[1]}%',
                                style: TextStyle(
                                    fontFamily: 'Syne',
                                    fontWeight: FontWeight.w700,
                                    color: item[2] as Color,
                                    fontSize: 14))
                          ]),
                          const SizedBox(height: 6),
                          ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                  value: (item[1] as int) / 100,
                                  backgroundColor:
                                      (item[2] as Color).withOpacity(0.12),
                                  valueColor: AlwaysStoppedAnimation(
                                      item[2] as Color),
                                  minHeight: 6)),
                        ]),
                  ))
              .toList()),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final String title, content;
  final Color color;
  const _InsightCard(
      {required this.title,
      required this.content,
      required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: color.withOpacity(0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.2))),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                      fontFamily: 'Syne',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: color)),
              const SizedBox(height: 8),
              Text(content,
                  style: const TextStyle(
                      fontSize: 13,
                      height: 1.6,
                      color: AppColors.lightMuted))
            ]),
      );
}

class _CTACard extends StatelessWidget {
  final bool isAnalysing;
  final VoidCallback onTap;
  const _CTACard({required this.isAnalysing, required this.onTap});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.secondary]),
            borderRadius: BorderRadius.circular(18)),
        child: Column(children: [
          const Icon(Icons.auto_awesome_rounded,
              color: Colors.white, size: 40),
          const SizedBox(height: 12),
          const Text('Run Your First AI Analysis',
              style: TextStyle(
                  fontFamily: 'Syne',
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text(
              'Gemini AI will analyse all your academic data and build your career intelligence profile.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 20),
          ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary),
              onPressed: isAnalysing ? null : onTap,
              child: Text(
                  isAnalysing ? 'Analysing...' : '⚡ Analyse My Profile'))
        ]),
      );
}
