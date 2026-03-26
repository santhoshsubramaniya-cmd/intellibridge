import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/themes.dart';
import '../../config/constants.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/gemini_service.dart';
import '../../models/drive_model.dart';

class AdminDrivesScreen extends StatefulWidget {
  const AdminDrivesScreen({super.key});
  @override
  State<AdminDrivesScreen> createState() => _AdminDrivesScreenState();
}

class _AdminDrivesScreenState extends State<AdminDrivesScreen> {
  final _companyCtrl = TextEditingController();
  final _roleCtrl = TextEditingController();
  final _packageCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  DateTime? _visitDate;
  double _minCgpa = 7.0;
  double _percentileCutoff = 50.0;
  List<String> _selectedSkills = [];
  bool _isPosting = false;

  final _gemini = GeminiService();
  final _fs = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Placement Drives')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Add drive form
            const Text('Add New Drive', style: TextStyle(fontFamily: 'Syne', fontSize: 18, fontWeight: FontWeight.w700)).animate().fadeIn(),
            const SizedBox(height: 16),

            _buildLabel('Company Name'),
            const SizedBox(height: 8),
            TextField(controller: _companyCtrl, decoration: const InputDecoration(hintText: 'e.g. TCS, Infosys', prefixIcon: Icon(Icons.business_outlined))),

            const SizedBox(height: 14),
            _buildLabel('Role'),
            const SizedBox(height: 8),
            TextField(controller: _roleCtrl, decoration: const InputDecoration(hintText: 'e.g. Software Engineer', prefixIcon: Icon(Icons.work_outline))),

            const SizedBox(height: 14),
            _buildLabel('Package'),
            const SizedBox(height: 8),
            TextField(controller: _packageCtrl, decoration: const InputDecoration(hintText: 'e.g. 3.5 LPA', prefixIcon: Icon(Icons.currency_rupee))),

            const SizedBox(height: 14),
            _buildLabel('Visit Date'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(context: context, initialDate: DateTime.now().add(const Duration(days: 7)), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                if (picked != null) setState(() => _visitDate = picked);
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Theme.of(context).inputDecorationTheme.fillColor, border: Border.all(color: AppColors.lightBorder), borderRadius: BorderRadius.circular(12)),
                child: Row(children: [const Icon(Icons.calendar_today_outlined, size: 20, color: AppColors.lightMuted), const SizedBox(width: 10), Text(_visitDate == null ? 'Select visit date' : '${_visitDate!.day}/${_visitDate!.month}/${_visitDate!.year}', style: TextStyle(color: _visitDate == null ? AppColors.lightMuted : null))]),
              ),
            ),

            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _buildLabel('Min CGPA: ${_minCgpa.toStringAsFixed(1)}'),
                Slider(value: _minCgpa, min: 5, max: 10, divisions: 10, activeColor: AppColors.primary, onChanged: (v) => setState(() => _minCgpa = v)),
              ])),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _buildLabel('Percentile Cutoff: ${_percentileCutoff.toInt()}%'),
                Slider(value: _percentileCutoff, min: 0, max: 100, divisions: 20, activeColor: AppColors.secondary, onChanged: (v) => setState(() => _percentileCutoff = v)),
              ])),
            ]),

            const SizedBox(height: 14),
            _buildLabel('Required Skills'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: AppConstants.allSkills.take(20).map((skill) {
                final isSelected = _selectedSkills.contains(skill);
                return GestureDetector(
                  onTap: () => setState(() { if (isSelected) _selectedSkills.remove(skill); else _selectedSkills.add(skill); }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary.withOpacity(0.15) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isSelected ? AppColors.primary : AppColors.lightBorder),
                    ),
                    child: Text(skill, style: TextStyle(fontSize: 12, color: isSelected ? AppColors.primary : AppColors.lightMuted, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400)),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 14),
            _buildLabel('Description'),
            const SizedBox(height: 8),
            TextField(controller: _descCtrl, maxLines: 3, decoration: const InputDecoration(hintText: 'Additional details about the drive...')),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isPosting ? null : _postDrive,
                icon: _isPosting ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.add_rounded),
                label: Text(_isPosting ? 'Posting & Alerting Students...' : 'Post Drive & Alert Students'),
              ),
            ),

            const SizedBox(height: 32),
            const Text('Posted Drives', style: TextStyle(fontFamily: 'Syne', fontSize: 18, fontWeight: FontWeight.w700)).animate().fadeIn(),
            const SizedBox(height: 14),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('placement_drives').orderBy('visitDate').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                final drives = snapshot.data!.docs.map((d) => PlacementDrive.fromMap(d.data() as Map<String, dynamic>, d.id)).toList();
                if (drives.isEmpty) return const Text('No drives posted yet', style: TextStyle(color: AppColors.lightMuted));
                return Column(children: drives.map((drive) => _DriveListCard(drive: drive)).toList());
              },
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Future<void> _postDrive() async {
    if (_companyCtrl.text.isEmpty || _roleCtrl.text.isEmpty || _visitDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill company, role, and visit date')));
      return;
    }

    setState(() => _isPosting = true);

    // Post drive to Firestore
    final driveRef = await FirebaseFirestore.instance.collection('placement_drives').add({
      'company': _companyCtrl.text.trim(),
      'role': _roleCtrl.text.trim(),
      'package': _packageCtrl.text.trim(),
      'visitDate': Timestamp.fromDate(_visitDate!),
      'minCgpa': _minCgpa,
      'percentileCutoff': _percentileCutoff,
      'requiredSkills': _selectedSkills,
      'description': _descCtrl.text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Send alerts to all students using AI-generated messages
    final students = await _fs.getAllStudents();
    final daysLeft = _visitDate!.difference(DateTime.now()).inDays;

    for (final student in students) {
      final alertMsg = await _gemini.generatePlacementAlert(
        studentName: student.name,
        company: _companyCtrl.text.trim(),
        role: _roleCtrl.text.trim(),
        daysLeft: daysLeft,
        studentPercentile: 50,
        requiredPercentile: _percentileCutoff,
        readiness: 60,
      );

      await _fs.createAlert(
        userId: student.uid,
        type: 'placement_drive',
        title: '🏢 ${_companyCtrl.text.trim()} Drive — $daysLeft days away!',
        message: alertMsg,
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('✅ Drive posted! AI alerts sent to ${students.length} students.'),
        backgroundColor: AppColors.secondary,
      ));
      _companyCtrl.clear(); _roleCtrl.clear(); _packageCtrl.clear(); _descCtrl.clear();
      setState(() { _visitDate = null; _selectedSkills = []; _isPosting = false; });
    }
  }

  Widget _buildLabel(String text) => Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.5));
}

class _DriveListCard extends StatelessWidget {
  final PlacementDrive drive;
  const _DriveListCard({required this.drive});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: drive.isUrgent ? AppColors.accent.withOpacity(0.4) : (Theme.of(context).brightness == Brightness.dark ? AppColors.darkBorder : AppColors.lightBorder)),
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(drive.company, style: const TextStyle(fontFamily: 'Syne', fontWeight: FontWeight.w700, fontSize: 15)),
          Text('${drive.role} · ${drive.package}', style: const TextStyle(fontSize: 12, color: AppColors.lightMuted)),
          const SizedBox(height: 6),
          Text('${drive.visitDate.day}/${drive.visitDate.month}/${drive.visitDate.year} · CGPA ≥${drive.minCgpa}', style: const TextStyle(fontSize: 11, color: AppColors.lightMuted)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: drive.isUpcoming ? AppColors.secondary.withOpacity(0.1) : AppColors.lightMuted.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Text(drive.isUpcoming ? '${drive.daysLeft}d left' : 'Past', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: drive.isUpcoming ? AppColors.secondary : AppColors.lightMuted)),
        ),
      ]),
    );
  }
}
