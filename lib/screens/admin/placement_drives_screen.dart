import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../config/themes.dart';
import '../../../config/constants.dart';
import '../../../services/auth_service.dart';
import '../../../services/firestore_service.dart';
import '../../../services/gemini_service.dart';
import '../../../services/placement_drive_service.dart';
import '../../../models/placement_drive_model.dart';

class PlacementDrivesScreen extends StatefulWidget {
  const PlacementDrivesScreen({super.key});

  @override
  State<PlacementDrivesScreen> createState() =>
      _PlacementDrivesScreenState();
}

class _PlacementDrivesScreenState extends State<PlacementDrivesScreen> {
  final _driveService = PlacementDriveService();
  final _fs = FirestoreService();
  final _gemini = GeminiService();

  final _companyCtrl = TextEditingController();
  final _roleCtrl = TextEditingController();
  final _packageCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _skillsCtrl = TextEditingController();

  DateTime? _visitDate;
  double _cgpaCutoff = 6.5;
  double _percentileCutoff = 50;
  bool _isAdding = false;
  bool _isPosting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Placement Drives'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => setState(() => _isAdding = !_isAdding),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Add drive form
            if (_isAdding) _buildAddDriveForm(),

            const Text('Upcoming Drives',
                style: TextStyle(
                    fontFamily: 'Syne',
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),

            const SizedBox(height: 14),

            // Drives list
            StreamBuilder<List<PlacementDrive>>(
              stream: _driveService.getDrivesStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator());
                }
                if (snapshot.data!.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: Text('No drives added yet',
                          style:
                              TextStyle(color: AppColors.lightMuted)),
                    ),
                  );
                }

                return Column(
                  children: snapshot.data!.map((drive) {
                    return _AdminDriveCard(
                      drive: drive,
                      onDelete: () => _driveService
                          .deleteDrive(drive.id)
                          .then((_) => setState(() {})),
                      onNotify: () => _notifyStudents(drive),
                    ).animate().fadeIn().slideY(begin: 0.1);
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddDriveForm() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Add New Drive',
              style: TextStyle(
                  fontFamily: 'Syne',
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),

          _buildField(_companyCtrl, 'Company Name', Icons.business),
          _buildField(_roleCtrl, 'Job Role', Icons.work_outline),
          _buildField(_packageCtrl, 'Package (e.g. 4.5 LPA)',
              Icons.currency_rupee),
          _buildField(_skillsCtrl, 'Required Skills (comma separated)',
              Icons.code_rounded),
          _buildField(
              _descCtrl, 'Description', Icons.description_outlined,
              maxLines: 3),

          const SizedBox(height: 14),

          // Date picker
          GestureDetector(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate:
                    DateTime.now().add(const Duration(days: 30)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (date != null) setState(() => _visitDate = date);
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: _visitDate != null
                        ? AppColors.primary
                        : AppColors.lightBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded,
                      size: 18, color: AppColors.lightMuted),
                  const SizedBox(width: 10),
                  Text(
                    _visitDate != null
                        ? '${_visitDate!.day}/${_visitDate!.month}/${_visitDate!.year}'
                        : 'Select Visit Date',
                    style: TextStyle(
                        color: _visitDate != null
                            ? null
                            : AppColors.lightMuted),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // CGPA cutoff
          Row(
            children: [
              const Expanded(
                  child: Text('Min CGPA',
                      style: TextStyle(fontWeight: FontWeight.w600))),
              Text(_cgpaCutoff.toStringAsFixed(1),
                  style: const TextStyle(
                      fontFamily: 'Syne',
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      fontSize: 18)),
            ],
          ),
          Slider(
            value: _cgpaCutoff,
            min: 5.0,
            max: 9.5,
            divisions: 18,
            activeColor: AppColors.primary,
            onChanged: (v) => setState(() => _cgpaCutoff = v),
          ),

          // Percentile cutoff
          Row(
            children: [
              const Expanded(
                  child: Text('Min Percentile',
                      style: TextStyle(fontWeight: FontWeight.w600))),
              Text('${_percentileCutoff.toInt()}th',
                  style: const TextStyle(
                      fontFamily: 'Syne',
                      fontWeight: FontWeight.w800,
                      color: AppColors.secondary,
                      fontSize: 18)),
            ],
          ),
          Slider(
            value: _percentileCutoff,
            min: 10,
            max: 90,
            divisions: 16,
            activeColor: AppColors.secondary,
            onChanged: (v) => setState(() => _percentileCutoff = v),
          ),

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isPosting ? null : _postDrive,
              icon: _isPosting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_rounded, size: 18),
              label: Text(_isPosting
                  ? 'Posting & Notifying...'
                  : 'Post Drive & Alert Students'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(
      TextEditingController ctrl, String hint, IconData icon,
      {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon),
        ),
      ),
    );
  }

  Future<void> _postDrive() async {
    if (_companyCtrl.text.isEmpty ||
        _roleCtrl.text.isEmpty ||
        _visitDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please fill company, role and date')),
      );
      return;
    }

    setState(() => _isPosting = true);

    final skills = _skillsCtrl.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final drive = PlacementDrive(
      id: '',
      company: _companyCtrl.text.trim(),
      visitDate: _visitDate!,
      package: _packageCtrl.text.trim(),
      cgpaCutoff: _cgpaCutoff,
      percentileCutoff: _percentileCutoff.toInt(),
      requiredSkills: skills,
      description: _descCtrl.text.trim(),
      role: _roleCtrl.text.trim(),
      createdAt: DateTime.now(),
    );

    final driveId = await _driveService.addDrive(drive);

    // Notify all eligible students
    await _notifyStudentsForNewDrive(drive.copyWith(id: driveId));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Drive posted and students notified!'),
          backgroundColor: AppColors.secondary,
        ),
      );
      setState(() {
        _isAdding = false;
        _isPosting = false;
      });
      _companyCtrl.clear();
      _roleCtrl.clear();
      _packageCtrl.clear();
      _skillsCtrl.clear();
      _descCtrl.clear();
      _visitDate = null;
    }
  }

  Future<void> _notifyStudentsForNewDrive(PlacementDrive drive) async {
    final user = context.read<AuthService>().userModel;
    final students = await _fs.getAllStudents();

    for (final student in students) {
      final alertMsg = await _gemini.generateSmartAlert(
        studentName: student.name,
        company: drive.company,
        currentPercentile: 50, // default until calculated
        requiredPercentile: drive.percentileCutoff,
        daysLeft: drive.daysLeft,
        skillGaps: drive.requiredSkills.take(2).toList(),
      );

      await _fs.createAlert(
        userId: student.uid,
        type: 'placement_drive',
        title: '🔔 ${drive.company} Drive — ${drive.daysLeft} days away!',
        message: alertMsg,
      );
    }
  }

  Future<void> _notifyStudents(PlacementDrive drive) async {
    await _notifyStudentsForNewDrive(drive);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Students notified!'),
          backgroundColor: AppColors.secondary,
        ),
      );
    }
  }
}

class _AdminDriveCard extends StatelessWidget {
  final PlacementDrive drive;
  final VoidCallback onDelete;
  final VoidCallback onNotify;
  const _AdminDriveCard({
    required this.drive,
    required this.onDelete,
    required this.onNotify,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                    Text('${drive.role} · ${drive.package}',
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.lightMuted)),
                  ],
                ),
              ),
              Text(
                '${drive.daysLeft}d',
                style: const TextStyle(
                    fontFamily: 'Syne',
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.warning),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            children: [
              _Chip(
                  label:
                      'CGPA ≥ ${drive.cgpaCutoff.toStringAsFixed(1)}',
                  color: AppColors.primary),
              _Chip(
                  label: '${drive.percentileCutoff}th %ile',
                  color: AppColors.secondary),
              _Chip(
                  label:
                      '${drive.visitDate.day}/${drive.visitDate.month}/${drive.visitDate.year}',
                  color: AppColors.warning),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onNotify,
                  icon: const Icon(Icons.notifications_rounded, size: 14),
                  label: const Text('Re-notify'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded,
                      size: 14),
                  label: const Text('Delete'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    side: const BorderSide(color: AppColors.accent),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

extension on PlacementDrive {
  PlacementDrive copyWith({String? id}) {
    return PlacementDrive(
      id: id ?? this.id,
      company: company,
      visitDate: visitDate,
      package: package,
      cgpaCutoff: cgpaCutoff,
      percentileCutoff: percentileCutoff,
      requiredSkills: requiredSkills,
      description: description,
      role: role,
      createdAt: createdAt,
    );
  }
}
