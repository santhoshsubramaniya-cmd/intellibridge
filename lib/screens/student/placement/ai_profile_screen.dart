import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../config/themes.dart';
import '../../../config/constants.dart';
import '../../../services/auth_service.dart';
import '../../../services/firestore_service.dart';
import '../../../services/gemini_service.dart';
import '../../../models/student_model.dart';

class AIProfileScreen extends StatefulWidget {
  const AIProfileScreen({super.key});

  @override
  State<AIProfileScreen> createState() => _AIProfileScreenState();
}

class _AIProfileScreenState extends State<AIProfileScreen> {
  final _fs = FirestoreService();
  final _gemini = GeminiService();

  StudentProfile? _profile;
  Map<String, dynamic> _careerGap = {};
  bool _isLoading = true;
  bool _isRunning = false;
  String? _selectedTargetRole;

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

  Future<void> _analyseGap() async {
    if (_selectedTargetRole == null || _profile == null) return;
    final user = context.read<AuthService>().userModel;
    if (user == null) return;

    setState(() => _isRunning = true);

    final requiredSkills =
        AppConstants.roleSkills[_selectedTargetRole!] ?? [];
    final result = await _gemini.analyseCareerGap(
      userId: user.uid,
      targetRole: _selectedTargetRole!,
      requiredSkills: requiredSkills,
      minCgpa: 6.5,
    );

    if (mounted) {
      setState(() {
        _careerGap = result;
        _isRunning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Career Profile')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // AI summary card (if analysed)
                  if (_profile?.strongestDomain != null)
                    _ProfileSummaryCard(profile: _profile!)
                        .animate()
                        .fadeIn()
                        .slideY(begin: 0.2),

                  if (_profile?.strongestDomain != null)
                    const SizedBox(height: 24),

                  // Career gap analyser
                  const Text('Career Gap Analyser',
                          style: TextStyle(
                              fontFamily: 'Syne',
                              fontSize: 18,
                              fontWeight: FontWeight.w700))
                      .animate()
                      .fadeIn(delay: 100.ms),
                  const SizedBox(height: 6),
                  const Text(
                    'Pick your target role to see exactly what you\'re missing.',
                    style: TextStyle(
                        fontSize: 13, color: AppColors.lightMuted),
                  ).animate().fadeIn(delay: 120.ms),
                  const SizedBox(height: 16),

                  // Role selector
                  _RoleSelector(
                    selectedRole: _selectedTargetRole,
                    onSelect: (r) =>
                        setState(() => _selectedTargetRole = r),
                  ).animate().fadeIn(delay: 150.ms),

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: (_selectedTargetRole == null ||
                              _isRunning)
                          ? null
                          : _analyseGap,
                      icon: _isRunning
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white))
                          : const Icon(Icons.search_rounded,
                              size: 18),
                      label: Text(_isRunning
                          ? 'Analysing Gap...'
                          : 'Analyse Career Gap'),
                    ),
                  ).animate().fadeIn(delay: 180.ms),

                  // Gap result
                  if (_careerGap.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _CareerGapResult(
                      gap: _careerGap,
                      role: _selectedTargetRole ?? '',
                    ).animate().fadeIn().slideY(begin: 0.1),
                  ],

                  // Skills the student currently has
                  if (_profile != null &&
                      _profile!.skills.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    const Text('Your Current Skills',
                            style: TextStyle(
                                fontFamily: 'Syne',
                                fontSize: 18,
                                fontWeight: FontWeight.w700))
                        .animate()
                        .fadeIn(delay: 250.ms),
                    const SizedBox(height: 12),
                    _SkillsDisplay(skills: _profile!.skills)
                        .animate()
                        .fadeIn(delay: 280.ms),
                  ],

                  // Weak areas
                  if (_profile != null &&
                      _profile!.weakAreas.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text('Areas to Improve',
                            style: TextStyle(
                                fontFamily: 'Syne',
                                fontSize: 18,
                                fontWeight: FontWeight.w700))
                        .animate()
                        .fadeIn(delay: 300.ms),
                    const SizedBox(height: 12),
                    _WeakAreasDisplay(areas: _profile!.weakAreas)
                        .animate()
                        .fadeIn(delay: 320.ms),
                  ],

                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }
}

// ─── Profile Summary ──────────────────────────────
class _ProfileSummaryCard extends StatelessWidget {
  final StudentProfile profile;
  const _ProfileSummaryCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.secondary.withOpacity(0.07),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.psychology_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('AI Career Profile',
                        style: TextStyle(
                            fontFamily: 'Syne',
                            fontWeight: FontWeight.w700,
                            fontSize: 15)),
                    Text(
                      profile.strongestDomain != null
                          ? 'Strongest in: ${profile.strongestDomain}'
                          : 'Profile analysed',
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.lightMuted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${profile.hireabilityScore.toInt()}%',
                  style: const TextStyle(
                      fontFamily: 'Syne',
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.secondary),
                ),
              ),
            ],
          ),
          if (profile.suitableRoles.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text('Best Fit Roles',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.lightMuted)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: profile.suitableRoles
                  .take(3)
                  .map((r) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: AppColors.primary
                                  .withOpacity(0.25)),
                        ),
                        child: Text(r,
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary)),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Role Selector ────────────────────────────────
class _RoleSelector extends StatelessWidget {
  final String? selectedRole;
  final ValueChanged<String> onSelect;
  const _RoleSelector(
      {required this.selectedRole, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final roles = AppConstants.roleSkills.keys.toList();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: roles.map((role) {
        final isSelected = selectedRole == role;
        return GestureDetector(
          onTap: () => onSelect(role),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withOpacity(0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.lightBorder,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Text(role,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected
                        ? FontWeight.w700
                        : FontWeight.w400,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.lightMuted)),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Career Gap Result ────────────────────────────
class _CareerGapResult extends StatelessWidget {
  final Map<String, dynamic> gap;
  final String role;
  const _CareerGapResult(
      {required this.gap, required this.role});

  @override
  Widget build(BuildContext context) {
    final readiness = gap['overallReadiness'] ?? 0;
    final weeks = gap['weeksToReady'] ?? 0;
    final actions =
        List<String>.from(gap['priorityActions'] ?? []);
    final gapData = gap['skillGap'] as Map<String, dynamic>? ?? {};
    final haveSkills = List<String>.from(gapData['have'] ?? []);
    final missingSkills =
        List<String>.from(gapData['missing'] ?? []);
    final cgpaStatus = gap['cgpaStatus'] ?? 'unknown';
    final expGap = gap['experienceGap'] ?? '';

    final color = readiness >= 70
        ? AppColors.secondary
        : readiness >= 45
            ? AppColors.warning
            : AppColors.accent;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Readiness score header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Gap Analysis Result',
                        style: TextStyle(
                            fontFamily: 'Syne',
                            fontWeight: FontWeight.w700,
                            fontSize: 16)),
                    Text('For $role',
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.lightMuted)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('$readiness%',
                      style: TextStyle(
                          fontFamily: 'Syne',
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: color)),
                  const Text('Ready',
                      style: TextStyle(
                          fontSize: 11,
                          color: AppColors.lightMuted)),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: readiness / 100,
              backgroundColor: color.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 6,
            ),
          ),

          const SizedBox(height: 14),

          // Quick stats
          Row(
            children: [
              _QuickStat(
                label: 'Weeks Needed',
                value: '$weeks',
                color: AppColors.primary,
                icon: Icons.schedule_rounded,
              ),
              const SizedBox(width: 10),
              _QuickStat(
                label: 'CGPA',
                value: cgpaStatus == 'meets' ? '✅' : '⚠️',
                color: cgpaStatus == 'meets'
                    ? AppColors.secondary
                    : AppColors.warning,
                icon: Icons.school_rounded,
              ),
            ],
          ),

          if (expGap.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.07),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppColors.warning.withOpacity(0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline,
                      color: AppColors.warning, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(expGap,
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.warning,
                            height: 1.5)),
                  ),
                ],
              ),
            ),
          ],

          // Skill breakdown
          if (haveSkills.isNotEmpty || missingSkills.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (haveSkills.isNotEmpty)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.check_circle_rounded,
                                color: AppColors.secondary,
                                size: 14),
                            SizedBox(width: 4),
                            Text('You Have',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.secondary)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: haveSkills
                              .map((s) => _SkillTag(
                                    label: s,
                                    color: AppColors.secondary,
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                if (haveSkills.isNotEmpty && missingSkills.isNotEmpty)
                  const SizedBox(width: 12),
                if (missingSkills.isNotEmpty)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.cancel_rounded,
                                color: AppColors.accent, size: 14),
                            SizedBox(width: 4),
                            Text('Missing',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.accent)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: missingSkills
                              .map((s) => _SkillTag(
                                    label: s,
                                    color: AppColors.accent,
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],

          // Priority actions
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Priority Actions',
                style: TextStyle(
                    fontFamily: 'Syne',
                    fontWeight: FontWeight.w700,
                    fontSize: 14)),
            const SizedBox(height: 8),
            ...actions.asMap().entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${e.key + 1}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(e.value,
                              style: const TextStyle(
                                  fontSize: 13, height: 1.5)),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }
}

class _QuickStat extends StatelessWidget {
  final String label, value;
  final Color color;
  final IconData icon;
  const _QuickStat(
      {required this.label,
      required this.value,
      required this.color,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: TextStyle(
                        fontFamily: 'Syne',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: color)),
                Text(label,
                    style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.lightMuted)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SkillTag extends StatelessWidget {
  final String label;
  final Color color;
  const _SkillTag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color)),
    );
  }
}

// ─── Skills Display ───────────────────────────────
class _SkillsDisplay extends StatelessWidget {
  final List<String> skills;
  const _SkillsDisplay({required this.skills});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: skills
          .map((s) => Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppColors.primary.withOpacity(0.25)),
                ),
                child: Text(s,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary)),
              ))
          .toList(),
    );
  }
}

// ─── Weak Areas Display ───────────────────────────
class _WeakAreasDisplay extends StatelessWidget {
  final List<String> areas;
  const _WeakAreasDisplay({required this.areas});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: areas
          .map((a) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.accent.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.arrow_up_rounded,
                        color: AppColors.accent, size: 16),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(a,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                    ),
                    const Text('Improve',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppColors.accent,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ))
          .toList(),
    );
  }
}
