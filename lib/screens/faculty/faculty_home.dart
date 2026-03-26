import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/themes.dart';
import '../../config/constants.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_sevice.dart';
import '../auth/login_screen.dart';

class FacultyHome extends StatefulWidget {
  const FacultyHome({super.key});

  @override
  State<FacultyHome> createState() => _FacultyHomeState();
}

class _FacultyHomeState extends State<FacultyHome> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().userModel;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final pages = [
      _FacultyDashboard(name: user?.name ?? 'Faculty'),
      const _UploadNotesTab(),
      const _PostResultsTab(),
      const _AnnouncementsTab(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
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
                _navItem(1, Icons.upload_file_rounded, 'Notes'),
                _navItem(2, Icons.grading_rounded, 'Results'),
                _navItem(3, Icons.campaign_rounded, 'Announce'),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.facultyColor.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: isActive
                    ? AppColors.facultyColor
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
                        ? AppColors.facultyColor
                        : AppColors.lightMuted)),
          ],
        ),
      ),
    );
  }
}

// ─── Faculty Dashboard ─────────────────────────────
class _FacultyDashboard extends StatelessWidget {
  final String name;
  const _FacultyDashboard({required this.name});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SmartPlace — Faculty'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await context.read<AuthService>().logout();
              if (context.mounted) {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()));
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
            // Welcome
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.facultyColor, Color(0xFF00A884)],
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.facultyColor.withOpacity(0.3),
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
                                color: Colors.white70, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text(name,
                            style: const TextStyle(
                                fontFamily: 'Syne',
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('Faculty Portal',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.person_rounded,
                      color: Colors.white54, size: 48),
                ],
              ),
            ).animate().fadeIn().slideY(begin: 0.2),

            const SizedBox(height: 28),

            const Text('Quick Actions',
                style: TextStyle(
                    fontFamily: 'Syne',
                    fontSize: 18,
                    fontWeight: FontWeight.w700))
                .animate()
                .fadeIn(delay: 100.ms),

            const SizedBox(height: 14),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: [
                _FacultyActionCard(
                    icon: Icons.upload_file_rounded,
                    label: 'Upload Notes',
                    subtitle: 'Share PDFs with students',
                    color: AppColors.primary),
                _FacultyActionCard(
                    icon: Icons.grading_rounded,
                    label: 'Post Results',
                    subtitle: 'Enter student marks',
                    color: AppColors.secondary),
                _FacultyActionCard(
                    icon: Icons.campaign_rounded,
                    label: 'Announce',
                    subtitle: 'Post campus news',
                    color: AppColors.warning),
                _FacultyActionCard(
                    icon: Icons.analytics_outlined,
                    label: 'Student Stats',
                    subtitle: 'View readiness',
                    color: AppColors.accent),
              ],
            ).animate().fadeIn(delay: 200.ms),
          ],
        ),
      ),
    );
  }
}

class _FacultyActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  const _FacultyActionCard(
      {required this.icon,
      required this.label,
      required this.subtitle,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 28),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontFamily: 'Syne',
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
              Text(subtitle,
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.lightMuted)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Upload Notes Tab ─────────────────────────────
class _UploadNotesTab extends StatefulWidget {
  const _UploadNotesTab();

  @override
  State<_UploadNotesTab> createState() => _UploadNotesTabState();
}

class _UploadNotesTabState extends State<_UploadNotesTab> {
  final _titleCtrl = TextEditingController();
  String? _selectedDept;
  int? _selectedSemester;
  PlatformFile? _selectedFile;
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().userModel;

    return Scaffold(
      appBar: AppBar(title: const Text('Upload Notes')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('Note Title'),
            const SizedBox(height: 8),
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                hintText: 'e.g. DBMS Unit 3 — Normalization',
                prefixIcon: Icon(Icons.title),
              ),
            ),

            const SizedBox(height: 16),
            _buildLabel('Department'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedDept,
              decoration:
                  const InputDecoration(prefixIcon: Icon(Icons.business)),
              hint: const Text('Select department'),
              items: AppConstants.courses
                  .map((c) => DropdownMenuItem(
                      value: c,
                      child:
                          Text(c, style: const TextStyle(fontSize: 13))))
                  .toList(),
              onChanged: (v) => setState(() => _selectedDept = v),
            ),

            const SizedBox(height: 16),
            _buildLabel('Semester'),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: _selectedSemester,
              decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.calendar_today)),
              hint: const Text('Select semester'),
              items: AppConstants.semesters
                  .map((s) => DropdownMenuItem(
                      value: s, child: Text('Semester $s')))
                  .toList(),
              onChanged: (v) => setState(() => _selectedSemester = v),
            ),

            const SizedBox(height: 20),
            _buildLabel('PDF File'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final result = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['pdf'],
                );
                if (result != null) {
                  setState(() => _selectedFile = result.files.first);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _selectedFile != null
                        ? AppColors.secondary
                        : AppColors.lightBorder,
                    style: BorderStyle.solid,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: _selectedFile != null
                      ? AppColors.secondary.withOpacity(0.05)
                      : Colors.transparent,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _selectedFile != null
                          ? Icons.check_circle_rounded
                          : Icons.upload_file_rounded,
                      color: _selectedFile != null
                          ? AppColors.secondary
                          : AppColors.lightMuted,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _selectedFile != null
                          ? _selectedFile!.name
                          : 'Tap to select PDF',
                      style: TextStyle(
                        color: _selectedFile != null
                            ? AppColors.secondary
                            : AppColors.lightMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.facultyColor),
                onPressed: _isUploading ? null : () => _upload(user),
                child: _isUploading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Upload Notes'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _upload(user) async {
    if (_titleCtrl.text.isEmpty ||
        _selectedDept == null ||
        _selectedSemester == null ||
        _selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      await FirestoreService().uploadNote(
        title: _titleCtrl.text.trim(),
        department: _selectedDept!,
        semester: _selectedSemester!,
        uploadedBy: user?.name ?? 'Faculty',
        fileBytes: _selectedFile!.bytes!,
        fileName: _selectedFile!.name,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Notes uploaded successfully!'),
            backgroundColor: AppColors.secondary,
          ),
        );
        _titleCtrl.clear();
        setState(() {
          _selectedFile = null;
          _selectedDept = null;
          _selectedSemester = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }

    setState(() => _isUploading = false);
  }

  Widget _buildLabel(String text) => Text(text,
      style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5));
}

// ─── Post Results Tab ─────────────────────────────
class _PostResultsTab extends StatefulWidget {
  const _PostResultsTab();

  @override
  State<_PostResultsTab> createState() => _PostResultsTabState();
}

class _PostResultsTabState extends State<_PostResultsTab> {
  final _emailCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  int? _selectedSemester;
  double _marks = 70;
  bool _isPosting = false;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().userModel;

    return Scaffold(
      appBar: AppBar(title: const Text('Post Results')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('Student Email'),
            const SizedBox(height: 8),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'student@email.com',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),

            const SizedBox(height: 16),
            _buildLabel('Subject'),
            const SizedBox(height: 8),
            TextField(
              controller: _subjectCtrl,
              decoration: const InputDecoration(
                hintText: 'e.g. Database Management',
                prefixIcon: Icon(Icons.book_outlined),
              ),
            ),

            const SizedBox(height: 16),
            _buildLabel('Semester'),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: _selectedSemester,
              decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.calendar_today)),
              hint: const Text('Select semester'),
              items: AppConstants.semesters
                  .map((s) => DropdownMenuItem(
                      value: s, child: Text('Semester $s')))
                  .toList(),
              onChanged: (v) => setState(() => _selectedSemester = v),
            ),

            const SizedBox(height: 16),
            Row(
              children: [
                _buildLabel('Marks'),
                const Spacer(),
                Text(
                  '${_marks.toInt()}/100',
                  style: const TextStyle(
                    fontFamily: 'Syne',
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Slider(
              value: _marks,
              min: 0,
              max: 100,
              divisions: 100,
              activeColor: AppColors.secondary,
              onChanged: (v) => setState(() => _marks = v),
            ),

            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary),
                onPressed: _isPosting ? null : () => _post(user),
                child: _isPosting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Post Result'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _post(user) async {
    if (_emailCtrl.text.isEmpty ||
        _subjectCtrl.text.isEmpty ||
        _selectedSemester == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() => _isPosting = true);

    await FirestoreService().postResult(
      studentEmail: _emailCtrl.text.trim(),
      subject: _subjectCtrl.text.trim(),
      marks: _marks.toInt(),
      semester: _selectedSemester!,
      uploadedBy: user?.name ?? 'Faculty',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Result posted!'),
          backgroundColor: AppColors.secondary,
        ),
      );
      _emailCtrl.clear();
      _subjectCtrl.clear();
      setState(() {
        _marks = 70;
        _selectedSemester = null;
      });
    }

    setState(() => _isPosting = false);
  }

  Widget _buildLabel(String text) => Text(text,
      style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5));
}

// ─── Announcements Tab ────────────────────────────
class _AnnouncementsTab extends StatefulWidget {
  const _AnnouncementsTab();

  @override
  State<_AnnouncementsTab> createState() => _AnnouncementsTabState();
}

class _AnnouncementsTabState extends State<_AnnouncementsTab> {
  final _titleCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  bool _isPosting = false;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().userModel;

    return Scaffold(
      appBar: AppBar(title: const Text('Post Announcement')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('Title'),
            const SizedBox(height: 8),
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                hintText: 'e.g. Exam Schedule Updated',
                prefixIcon: Icon(Icons.title),
              ),
            ),

            const SizedBox(height: 16),
            _buildLabel('Message'),
            const SizedBox(height: 8),
            TextField(
              controller: _messageCtrl,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Write your announcement here...',
                alignLabelWithHint: true,
              ),
            ),

            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warning),
                onPressed: _isPosting ? null : () => _post(user),
                child: _isPosting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Post Announcement',
                        style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _post(user) async {
    if (_titleCtrl.text.isEmpty || _messageCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() => _isPosting = true);

    await FirestoreService().postAnnouncement(
      title: _titleCtrl.text.trim(),
      message: _messageCtrl.text.trim(),
      postedBy: user?.name ?? 'Faculty',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Announcement posted!'),
          backgroundColor: AppColors.secondary,
        ),
      );
      _titleCtrl.clear();
      _messageCtrl.clear();
    }

    setState(() => _isPosting = false);
  }

  Widget _buildLabel(String text) => Text(text,
      style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5));
}
