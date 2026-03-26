import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../config/themes.dart';
import '../../../services/auth_service.dart';
import '../../../services/percentile_service.dart';
import '../../../services/placement_drive_service.dart';
import '../../../services/gemini_service.dart';
import '../../../models/placement_drive_model.dart';
import 'training_plan_screen.dart';

class PercentileScreen extends StatefulWidget {
  const PercentileScreen({super.key});

  @override
  State<PercentileScreen> createState() => _PercentileScreenState();
}

class _PercentileScreenState extends State<PercentileScreen> {
  final _percentileService = PercentileService();
  final _driveService = PlacementDriveService();
  final _gemini = GeminiService();

  Map<String, dynamic> _percentileData = {};
  List<PlacementDrive> _drives = [];
  Map<String, Map<String, dynamic>> _eligibilityMap = {};
  Map<String, bool> _loadingPlan = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = context.read<AuthService>().userModel;
    if (user == null) return;

    final percentile =
        await _percentileService.getStudentPercentile(user.uid);
    final drives = await _driveService.getUpcomingDrives();

    final eligMap = <String, Map<String, dynamic>>{};
    for (final drive in drives) {
      final elig = await _percentileService.checkDriveEligibility(
        userId: user.uid,
        driveId: drive.id,
      );
      eligMap[drive.id] = elig;
    }

    if (mounted) {
      setState(() {
        _percentileData = percentile;
        _drives = drives;
        _eligibilityMap = eligMap;
        _isLoading = false;
      });
    }
  }

  Future<void> _generatePlan(PlacementDrive drive) async {
    final user = context.read<AuthService>().userModel;
    if (user == null) return;

    setState(() => _loadingPlan[drive.id] = true);

    // Check if plan already exists
    final existing =
        await _driveService.getTrainingPlan(user.uid, drive.id);
    Map<String, dynamic> plan;

    if (existing != null) {
      plan = existing;
    } else {
      plan = await _gemini.generateTrainingPlan(
        userId: user.uid,
        driveId: drive.id,
        company: drive.company,
        role: drive.role,
        requiredSkills: drive.requiredSkills,
        daysLeft: drive.daysLeft,
      );
    }

    if (mounted) {
      setState(() => _loadingPlan[drive.id] = false);
      if (plan.isNotEmpty && !plan.containsKey('error')) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TrainingPlanScreen(
              plan: plan,
              company: drive.company,
              role: drive.role,
              daysLeft: drive.daysLeft,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Could not generate plan. Try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Placement Standing'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadData();
            },
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
                  _PercentileHero(data: _percentileData)
                      .animate()
                      .fadeIn()
                      .slideY(begin: 0.2),

                  const SizedBox(height: 24),

                  _BreakdownCard(data: _percentileData)
                      .animate()
                      .fadeIn(delay: 100.ms),

                  const SizedBox(height: 28),

                  const Text(
                    'Upcoming Drives & Eligibility',
                    style: TextStyle(
                        fontFamily: 'Syne',
                        fontSize: 18,
                        fontWeight: FontWeight.w700),
                  ).animate().fadeIn(delay: 200.ms),

                  const SizedBox(height: 14),

                  if (_drives.isEmpty)
                    _EmptyDrives()
                  else
                    ..._drives.asMap().entries.map((e) {
                      final drive = e.value;
                      final elig =
                          _eligibilityMap[drive.id] ?? {};
                      return _DriveEligibilityCard(
                        drive: drive,
                        eligibility: elig,
                        isLoadingPlan:
                            _loadingPlan[drive.id] ?? false,
                        onGeneratePlan: () => _generatePlan(drive),
                      )
                          .animate()
                          .fadeIn(
                              delay: Duration(
                                  milliseconds: 300 + e.key * 80))
                          .slideY(begin: 0.1);
                    }),

                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }
}

// ─── Percentile Hero Card ─────────────────────────
class _PercentileHero extends StatelessWidget {
  final Map<String, dynamic> data;
  const _PercentileHero({required this.data});

  @override
  Widget build(BuildContext context) {
    final percentile = data['overallPercentile'] ?? 0;
    final score = (data['hireabilityScore'] ?? 0.0) as double;
    final rank = data['rank'] ?? 0;
    final total = data['totalStudents'] ?? 0;

    final color = percentile >= 75
        ? AppColors.secondary
        : percentile >= 50
            ? AppColors.warning
            : AppColors.accent;

    final label = percentile >= 90
        ? 'Top Performer 🏆'
        : percentile >= 75
            ? 'Above Average ✅'
            : percentile >= 50
                ? 'Average Range ⚡'
                : 'Room to Grow 📈';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              TweenAnimationBuilder<int>(
                tween: IntTween(begin: 0, end: percentile),
                duration: const Duration(milliseconds: 1200),
                builder: (_, val, __) => Text(
                  '$val',
                  style: TextStyle(
                    fontFamily: 'Syne',
                    fontSize: 72,
                    fontWeight: FontWeight.w800,
                    color: color,
                    height: 1,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'th %ile',
                  style: TextStyle(
                    fontFamily: 'Syne',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Syne',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentile / 100,
              backgroundColor: color.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MetricPill(
                  label: 'Hireability',
                  value: '${score.toStringAsFixed(0)}%',
                  color: color),
              _MetricPill(
                  label: 'Rank',
                  value: '#$rank / $total',
                  color: AppColors.primary),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  final String label, value;
  final Color color;
  const _MetricPill(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontFamily: 'Syne',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: color)),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.lightMuted)),
        ],
      ),
    );
  }
}

// ─── Score Breakdown Card ─────────────────────────
class _BreakdownCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _BreakdownCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final score = (data['hireabilityScore'] ?? 0.0) as double;

    // Derive approximate sub-scores from overall
    final cgpaScore = (score * 0.25).clamp(0.0, 25.0);
    final skillScore = (score * 0.20).clamp(0.0, 20.0);
    final internScore = (score * 0.20).clamp(0.0, 20.0);
    final attendanceScore = (score * 0.15).clamp(0.0, 15.0);
    final projectScore = (score * 0.20).clamp(0.0, 20.0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkBorder
              : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Score Breakdown',
              style: TextStyle(
                  fontFamily: 'Syne',
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          _BreakdownRow(label: 'CGPA', score: cgpaScore, max: 25),
          _BreakdownRow(label: 'Skills', score: skillScore, max: 20),
          _BreakdownRow(label: 'Internships', score: internScore, max: 20),
          _BreakdownRow(
              label: 'Attendance', score: attendanceScore, max: 15),
          _BreakdownRow(label: 'Projects', score: projectScore, max: 20),
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final String label;
  final double score, max;
  const _BreakdownRow(
      {required this.label, required this.score, required this.max});

  @override
  Widget build(BuildContext context) {
    final pct = (score / max).clamp(0.0, 1.0);
    final color = pct >= 0.7
        ? AppColors.secondary
        : pct >= 0.4
            ? AppColors.warning
            : AppColors.accent;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: Text(label,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600))),
              Text(
                '${score.toStringAsFixed(0)} / ${max.toInt()}',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: color.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Drive Eligibility Card ───────────────────────
class _DriveEligibilityCard extends StatelessWidget {
  final PlacementDrive drive;
  final Map<String, dynamic> eligibility;
  final bool isLoadingPlan;
  final VoidCallback onGeneratePlan;

  const _DriveEligibilityCard({
    required this.drive,
    required this.eligibility,
    required this.isLoadingPlan,
    required this.onGeneratePlan,
  });

  @override
  Widget build(BuildContext context) {
    final isEligible = eligibility['eligible'] ?? false;
    final cgpaOk = eligibility['cgpaOk'] ?? false;
    final percentileOk = eligibility['percentileOk'] ?? false;
    final gap = (eligibility['percentileGap'] ?? 0).toInt();
    final daysLeft = eligibility['daysLeft'] ?? drive.daysLeft;

    final borderColor =
        isEligible ? AppColors.secondary : AppColors.accent;
    final statusColor =
        isEligible ? AppColors.secondary : AppColors.accent;
    final statusText =
        isEligible ? '✅ Eligible' : '❌ Not Eligible';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(drive.company,
                        style: const TextStyle(
                            fontFamily: 'Syne',
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                    Text(
                      '${drive.role} · ${drive.package}',
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.lightMuted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(statusText,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: statusColor)),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Requirement checks
          Row(
            children: [
              _CheckChip(
                label:
                    'CGPA ≥ ${drive.cgpaCutoff.toStringAsFixed(1)}',
                passes: cgpaOk,
              ),
              const SizedBox(width: 8),
              _CheckChip(
                label: '${drive.percentileCutoff}th %ile',
                passes: percentileOk,
              ),
              const SizedBox(width: 8),
              _CheckChip(
                label: '$daysLeft days',
                passes: daysLeft > 0,
                neutral: true,
              ),
            ],
          ),

          if (!isEligible && gap > 0) ...[
            const SizedBox(height: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppColors.warning.withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.trending_up_rounded,
                      color: AppColors.warning, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Need $gap more percentile points. Generate a plan!',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.warning),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Skills
          if (drive.requiredSkills.isNotEmpty) ...[
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: drive.requiredSkills
                  .take(5)
                  .map((s) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(s,
                            style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.primary)),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 12),
          ],

          // CTA
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isLoadingPlan ? null : onGeneratePlan,
              style: ElevatedButton.styleFrom(
                backgroundColor: isEligible
                    ? AppColors.secondary
                    : AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              icon: isLoadingPlan
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.map_rounded, size: 16),
              label: Text(
                isLoadingPlan
                    ? 'Generating AI Plan...'
                    : isEligible
                        ? 'View Training Plan'
                        : 'Generate Catch-Up Plan',
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckChip extends StatelessWidget {
  final String label;
  final bool passes;
  final bool neutral;
  const _CheckChip(
      {required this.label,
      required this.passes,
      this.neutral = false});

  @override
  Widget build(BuildContext context) {
    final color = neutral
        ? AppColors.lightMuted
        : passes
            ? AppColors.secondary
            : AppColors.accent;
    final icon = neutral
        ? Icons.schedule_rounded
        : passes
            ? Icons.check_circle_rounded
            : Icons.cancel_rounded;

    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color)),
        ],
      ),
    );
  }
}

class _EmptyDrives extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        children: [
          Icon(Icons.work_outline_rounded,
              size: 48, color: AppColors.lightMuted),
          SizedBox(height: 12),
          Text('No upcoming drives',
              style: TextStyle(
                  fontFamily: 'Syne',
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
          SizedBox(height: 6),
          Text('Admin will post placement drives here',
              style: TextStyle(
                  color: AppColors.lightMuted, fontSize: 13)),
        ],
      ),
    );
  }
}
