import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../config/themes.dart';
import '../../../config/constants.dart';
import '../../../services/auth_service.dart';
import '../../../services/firestore_service.dart';
import '../../../services/percentile_service.dart';
import '../../../models/student_model.dart';

class ProfileUpdateScreen extends StatefulWidget {
  const ProfileUpdateScreen({super.key});

  @override
  State<ProfileUpdateScreen> createState() => _ProfileUpdateScreenState();
}

class _ProfileUpdateScreenState extends State<ProfileUpdateScreen> {
  final _fs = FirestoreService();
  final _percentileService = PercentileService();

  // Controllers
  final _cgpaCtrl = TextEditingController();
  final _attendanceCtrl = TextEditingController();
  final _projectCtrl = TextEditingController();
  final _certCtrl = TextEditingController();
  final _internCompanyCtrl = TextEditingController();
  final _internRoleCtrl = TextEditingController();
  final _internDurationCtrl = TextEditingController();

  List<String> _selectedSkills = [];
  List<Map<String, dynamic>> _internships = [];
  bool _isLoading = true;
  bool _isSaving = false;

  StudentProfile? _existing;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  @override
  void dispose() {
    _cgpaCtrl.dispose();
    _attendanceCtrl.dispose();
    _projectCtrl.dispose();
    _certCtrl.dispose();
    _internCompanyCtrl.dispose();
    _internRoleCtrl.dispose();
    _internDurationCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadExisting() async {
    final user = context.read<AuthService>().userModel;
    if (user == null) return;

    final profile = await _fs.getStudentProfile(user.uid);
    if (profile != null && mounted) {
      _cgpaCtrl.text = profile.cgpa.toStringAsFixed(1);
      _attendanceCtrl.text = profile.attendance.toString();
      _projectCtrl.text = profile.projectCount.toString();
      _certCtrl.text = profile.certCount.toString();
      setState(() {
        _existing = profile;
        _selectedSkills = List<String>.from(profile.skills);
        _internships =
            List<Map<String, dynamic>>.from(profile.internships);
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    final user = context.read<AuthService>().userModel;
    if (user == null) return;

    final cgpa = double.tryParse(_cgpaCtrl.text.trim()) ?? 0.0;
    final attendance = int.tryParse(_attendanceCtrl.text.trim()) ?? 0;
    final projects = int.tryParse(_projectCtrl.text.trim()) ?? 0;
    final certs = int.tryParse(_certCtrl.text.trim()) ?? 0;

    if (cgpa < 0 || cgpa > 10) {
      _snack('CGPA must be between 0 and 10');
      return;
    }
    if (attendance < 0 || attendance > 100) {
      _snack('Attendance must be between 0 and 100');
      return;
    }
    if (_selectedSkills.isEmpty) {
      _snack('Please select at least one skill');
      return;
    }

    setState(() => _isSaving = true);

    // Calculate new hireability score
    final newScore = _percentileService.calculateHireability(
      cgpa: cgpa,
      skillCount: _selectedSkills.length,
      internships: _internships.length,
      attendance: attendance,
      projects: projects,
      certs: certs,
    );

    await FirebaseFirestore.instance
        .collection('students')
        .doc(user.uid)
        .set({
      'uid': user.uid,
      'cgpa': cgpa,
      'attendance': attendance,
      'skills': _selectedSkills,
      'internships': _internships,
      'projectCount': projects,
      'certCount': certs,
      'hireabilityScore': newScore,
      'weakAreas': _existing?.weakAreas ?? [],
      'suitableRoles': _existing?.suitableRoles ?? [],
      'overallPercentile': _existing?.overallPercentile ?? 0,
      'deptPercentile': _existing?.deptPercentile ?? 0,
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Recalculate all percentiles
    await _percentileService.recalculateAllPercentiles();

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '✅ Profile updated! Hireability: ${newScore.toStringAsFixed(0)}%'),
          backgroundColor: AppColors.secondary,
        ),
      );
      Navigator.pop(context);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  void _addInternship() {
    if (_internCompanyCtrl.text.trim().isEmpty ||
        _internRoleCtrl.text.trim().isEmpty) return;

    setState(() {
      _internships.add({
        'company': _internCompanyCtrl.text.trim(),
        'role': _internRoleCtrl.text.trim(),
        'duration': _internDurationCtrl.text.trim(),
      });
      _internCompanyCtrl.clear();
      _internRoleCtrl.clear();
      _internDurationCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Profile'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Save',
                      style: TextStyle(fontWeight: FontWeight.w700)),
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
                  // Info banner
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.primary.withOpacity(0.2)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: AppColors.primary, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Keeping your profile up to date improves your hireability score and placement eligibility.',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppColors.primary,
                                height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(),

                  const SizedBox(height: 24),

                  // ── Academic Details ──────────────
                  _SectionHeader(
                          title: 'Academic Details',
                          icon: Icons.school_rounded,
                          color: AppColors.primary)
                      .animate()
                      .fadeIn(delay: 50.ms),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: _LabeledField(
                          label: 'CGPA (0–10)',
                          child: TextField(
                            controller: _cgpaCtrl,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            decoration: const InputDecoration(
                              hintText: '7.5',
                              prefixIcon:
                                  Icon(Icons.grade_rounded),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _LabeledField(
                          label: 'Attendance (%)',
                          child: TextField(
                            controller: _attendanceCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: '85',
                              prefixIcon: Icon(
                                  Icons.event_available_rounded),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 80.ms),

                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: _LabeledField(
                          label: 'Projects Count',
                          child: TextField(
                            controller: _projectCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: '3',
                              prefixIcon:
                                  Icon(Icons.folder_rounded),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _LabeledField(
                          label: 'Certifications',
                          child: TextField(
                            controller: _certCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: '2',
                              prefixIcon:
                                  Icon(Icons.verified_rounded),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 100.ms),

                  const SizedBox(height: 28),

                  // ── Skills ────────────────────────
                  _SectionHeader(
                          title: 'Technical Skills',
                          icon: Icons.code_rounded,
                          color: AppColors.secondary)
                      .animate()
                      .fadeIn(delay: 120.ms),
                  const SizedBox(height: 6),
                  Text(
                    '${_selectedSkills.length} selected',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.lightMuted),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: AppConstants.allSkills.map((skill) {
                      final isSelected =
                          _selectedSkills.contains(skill);
                      return GestureDetector(
                        onTap: () => setState(() {
                          if (isSelected) {
                            _selectedSkills.remove(skill);
                          } else {
                            _selectedSkills.add(skill);
                          }
                        }),
                        child: AnimatedContainer(
                          duration:
                              const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.secondary
                                    .withOpacity(0.15)
                                : Colors.transparent,
                            borderRadius:
                                BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.secondary
                                  : AppColors.lightBorder,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isSelected) ...[
                                const Icon(
                                    Icons.check_rounded,
                                    size: 12,
                                    color: AppColors.secondary),
                                const SizedBox(width: 4),
                              ],
                              Text(skill,
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w400,
                                      color: isSelected
                                          ? AppColors.secondary
                                          : AppColors.lightMuted)),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ).animate().fadeIn(delay: 140.ms),

                  const SizedBox(height: 28),

                  // ── Internships ───────────────────
                  _SectionHeader(
                          title: 'Internships',
                          icon: Icons.business_center_rounded,
                          color: AppColors.warning)
                      .animate()
                      .fadeIn(delay: 160.ms),
                  const SizedBox(height: 14),

                  // Existing internships
                  if (_internships.isNotEmpty) ...[
                    ..._internships.asMap().entries.map((e) =>
                        _InternshipChip(
                          data: e.value,
                          onDelete: () => setState(
                              () => _internships.removeAt(e.key)),
                        ).animate().fadeIn()),
                    const SizedBox(height: 12),
                  ],

                  // Add internship form
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color:
                              AppColors.warning.withOpacity(0.25)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Add Internship',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13)),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _internCompanyCtrl,
                          decoration: const InputDecoration(
                            hintText: 'Company name',
                            prefixIcon:
                                Icon(Icons.business_outlined),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _internRoleCtrl,
                          decoration: const InputDecoration(
                            hintText: 'Role / Position',
                            prefixIcon:
                                Icon(Icons.work_outline_rounded),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _internDurationCtrl,
                          decoration: const InputDecoration(
                            hintText: 'Duration (e.g. 2 months)',
                            prefixIcon:
                                Icon(Icons.schedule_rounded),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _addInternship,
                            icon: const Icon(Icons.add_rounded,
                                size: 16),
                            label: const Text('Add Internship'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.warning,
                              side: const BorderSide(
                                  color: AppColors.warning),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 180.ms),

                  const SizedBox(height: 32),

                  // Live hireability preview
                  _HireabilityPreview(
                    cgpa: double.tryParse(
                            _cgpaCtrl.text.trim()) ??
                        0.0,
                    skills: _selectedSkills.length,
                    internships: _internships.length,
                    attendance: int.tryParse(
                            _attendanceCtrl.text.trim()) ??
                        0,
                    projects: int.tryParse(
                            _projectCtrl.text.trim()) ??
                        0,
                    certs: int.tryParse(_certCtrl.text.trim()) ?? 0,
                    percentileService: _percentileService,
                  ).animate().fadeIn(delay: 200.ms),

                  const SizedBox(height: 24),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _save,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white))
                          : const Icon(Icons.save_rounded,
                              size: 18),
                      label: Text(
                          _isSaving ? 'Saving...' : 'Save Profile'),
                    ),
                  ).animate().fadeIn(delay: 220.ms),

                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }
}

// ─── Section Header ───────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  const _SectionHeader(
      {required this.title,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: const TextStyle(
                fontFamily: 'Syne',
                fontSize: 17,
                fontWeight: FontWeight.w700)),
      ],
    );
  }
}

// ─── Labeled Field ────────────────────────────────
class _LabeledField extends StatelessWidget {
  final String label;
  final Widget child;
  const _LabeledField(
      {required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
                color: AppColors.lightMuted)),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

// ─── Internship Chip ──────────────────────────────
class _InternshipChip extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onDelete;
  const _InternshipChip(
      {required this.data, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: AppColors.warning.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.business_center_rounded,
              color: AppColors.warning, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['company'] ?? '',
                    style: const TextStyle(
                        fontFamily: 'Syne',
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
                Text(
                    '${data['role'] ?? ''}${data['duration'] != null && (data['duration'] as String).isNotEmpty ? ' · ${data['duration']}' : ''}',
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.lightMuted)),
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.close_rounded,
                size: 16, color: AppColors.lightMuted),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

// ─── Live Hireability Preview ─────────────────────
class _HireabilityPreview extends StatelessWidget {
  final double cgpa;
  final int skills, internships, attendance, projects, certs;
  final PercentileService percentileService;

  const _HireabilityPreview({
    required this.cgpa,
    required this.skills,
    required this.internships,
    required this.attendance,
    required this.projects,
    required this.certs,
    required this.percentileService,
  });

  @override
  Widget build(BuildContext context) {
    final score = percentileService.calculateHireability(
      cgpa: cgpa,
      skillCount: skills,
      internships: internships,
      attendance: attendance,
      projects: projects,
      certs: certs,
    );

    final color = score >= 75
        ? AppColors.secondary
        : score >= 50
            ? AppColors.warning
            : AppColors.accent;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Live Hireability Preview',
                  style: TextStyle(
                      fontFamily: 'Syne',
                      fontWeight: FontWeight.w700,
                      fontSize: 14)),
              const Spacer(),
              Text(
                '${score.toStringAsFixed(0)}%',
                style: TextStyle(
                    fontFamily: 'Syne',
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: color),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score / 100,
              backgroundColor: color.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            score >= 75
                ? 'Excellent profile! You qualify for most drives.'
                : score >= 50
                    ? 'Good profile. Adding more skills will help.'
                    : 'Keep building. Add projects and certifications.',
            style: TextStyle(
                fontSize: 12, color: color, height: 1.4),
          ),
        ],
      ),
    );
  }
}
