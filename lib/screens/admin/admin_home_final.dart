import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/themes.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
import '../auth/login_screen.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _currentIndex = 0;
  final _fs = FirestoreService();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final pages = [
      _AdminDashboard(fs: _fs),
      _ApprovalsTab(fs: _fs),       // now StreamBuilder — live updates
      _BroadcastTab(fs: _fs),
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
                _navItem(1, Icons.approval_rounded, 'Approvals'),
                _navItem(2, Icons.send_rounded, 'Broadcast'),
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.adminColor.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: isActive ? AppColors.adminColor : AppColors.lightMuted,
                size: 22),
            const SizedBox(height: 3),
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight:
                        isActive ? FontWeight.w700 : FontWeight.w400,
                    color: isActive
                        ? AppColors.adminColor
                        : AppColors.lightMuted)),
          ],
        ),
      ),
    );
  }
}

// ─── Dashboard ────────────────────────────────────
class _AdminDashboard extends StatelessWidget {
  final FirestoreService fs;
  const _AdminDashboard({required this.fs});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
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
      body: FutureBuilder<Map<String, dynamic>>(
        future: fs.getCollegeAnalytics(),
        builder: (context, snapshot) {
          final data = snapshot.data ?? {};
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [AppColors.adminColor, Color(0xFFCC3355)]),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.adminColor.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Row(children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Admin Dashboard',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 13)),
                          SizedBox(height: 4),
                          Text('SmartPlace',
                              style: TextStyle(
                                  fontFamily: 'Syne',
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800)),
                          SizedBox(height: 6),
                          Text('Manage students, faculty & campus',
                              style: TextStyle(
                                  color: Colors.white60, fontSize: 12)),
                        ],
                      ),
                    ),
                    Icon(Icons.admin_panel_settings_rounded,
                        color: Colors.white38, size: 48),
                  ]),
                ).animate().fadeIn().slideY(begin: 0.2),

                const SizedBox(height: 24),
                const Text('Platform Overview',
                        style: TextStyle(
                            fontFamily: 'Syne',
                            fontSize: 18,
                            fontWeight: FontWeight.w700))
                    .animate()
                    .fadeIn(delay: 100.ms),
                const SizedBox(height: 14),

                Row(children: [
                  _StatCard(
                      icon: Icons.people_rounded,
                      label: 'Students',
                      value: data['totalStudents']?.toString() ?? '—',
                      color: AppColors.primary),
                  const SizedBox(width: 12),
                  _StatCard(
                      icon: Icons.pending_actions_rounded,
                      label: 'Pending',
                      value: data['pendingApprovals']?.toString() ?? '—',
                      color: AppColors.warning),
                  const SizedBox(width: 12),
                  _StatCard(
                      icon: Icons.menu_book_rounded,
                      label: 'Notes',
                      value: data['totalNotes']?.toString() ?? '—',
                      color: AppColors.secondary),
                ]).animate().fadeIn(delay: 200.ms),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  const _StatCard(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

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
        child: Column(children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontFamily: 'Syne',
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: color)),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.lightMuted)),
        ]),
      ),
    );
  }
}

// ─── Approvals Tab ────────────────────────────────
// KEY FIX: Uses StreamBuilder instead of FutureBuilder.
// The list instantly updates when you tap Approve or Reject —
// no manual refresh, no restart needed.
class _ApprovalsTab extends StatelessWidget {
  final FirestoreService fs;
  const _ApprovalsTab({required this.fs});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pending Approvals')),
      body: StreamBuilder<List<UserModel>>(
        stream: fs.pendingUsersStream(),   // ← real-time stream
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data ?? [];

          if (users.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 64,
                      color: AppColors.secondary.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  const Text('All caught up!',
                      style: TextStyle(
                          fontFamily: 'Syne',
                          fontSize: 20,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  const Text('No pending approvals',
                      style: TextStyle(color: AppColors.lightMuted)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, i) {
              final user = users[i];
              return _ApprovalCard(
                user: user,
                onApprove: () async {
                  await fs.approveUser(user.uid);
                  // No setState needed — StreamBuilder rebuilds automatically
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('✅ ${user.name} approved!'),
                      backgroundColor: AppColors.secondary,
                    ));
                  }
                },
                onReject: () async {
                  // Confirm before deleting
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Reject User?'),
                      content: Text(
                          'This will permanently remove ${user.name}\'s account. Continue?'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel')),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Reject'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    await fs.rejectUser(user.uid);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('${user.name} rejected and removed'),
                        backgroundColor: AppColors.accent,
                      ));
                    }
                  }
                },
              )
                  .animate()
                  .fadeIn(delay: Duration(milliseconds: i * 80))
                  .slideY(begin: 0.1);
            },
          );
        },
      ),
    );
  }
}

class _ApprovalCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _ApprovalCard({
    required this.user,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final roleColor =
        user.isStudent ? AppColors.studentColor : AppColors.facultyColor;

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
          Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: roleColor.withOpacity(0.15),
                  shape: BoxShape.circle),
              child: Center(
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                  style: TextStyle(
                      fontFamily: 'Syne',
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: roleColor),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.name,
                      style: const TextStyle(
                          fontFamily: 'Syne',
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                  Text(user.email,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.lightMuted)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: roleColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(user.role.toUpperCase(),
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: roleColor)),
            ),
          ]),
          const SizedBox(height: 8),
          Text(
            user.isStudent
                ? '${user.course ?? ''} · Semester ${user.semester ?? ''}'
                : user.department,
            style: const TextStyle(
                fontSize: 12, color: AppColors.lightMuted),
          ),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onReject,
                icon: const Icon(Icons.close_rounded, size: 16),
                label: const Text('Reject'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  side: const BorderSide(color: AppColors.accent),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onApprove,
                icon: const Icon(Icons.check_rounded, size: 16),
                label: const Text('Approve'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

// ─── Broadcast Tab ────────────────────────────────
class _BroadcastTab extends StatefulWidget {
  final FirestoreService fs;
  const _BroadcastTab({required this.fs});

  @override
  State<_BroadcastTab> createState() => _BroadcastTabState();
}

class _BroadcastTabState extends State<_BroadcastTab> {
  final _titleCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Broadcast Alert')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.adminColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.adminColor.withOpacity(0.2)),
              ),
              child: const Row(children: [
                Icon(Icons.send_rounded,
                    color: AppColors.adminColor, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'This message will be sent to all approved students',
                    style: TextStyle(
                        fontSize: 13, color: AppColors.adminColor),
                  ),
                ),
              ]),
            ),

            const SizedBox(height: 20),
            const Text('Alert Title',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5)),
            const SizedBox(height: 8),
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                hintText: 'e.g. TCS Drive Announced!',
                prefixIcon: Icon(Icons.title),
              ),
            ),

            const SizedBox(height: 16),
            const Text('Message',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5)),
            const SizedBox(height: 8),
            TextField(
              controller: _messageCtrl,
              maxLines: 5,
              decoration: const InputDecoration(
                  hintText: 'Write your broadcast message...'),
            ),

            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.adminColor),
                onPressed: _isSending ? null : _send,
                icon: _isSending
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_rounded),
                label:
                    Text(_isSending ? 'Sending...' : 'Send to All Students'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _send() async {
    if (_titleCtrl.text.isEmpty || _messageCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all fields')));
      return;
    }
    setState(() => _isSending = true);

    final students = await widget.fs.getAllStudents();
    for (final student in students) {
      await widget.fs.createAlert(
        userId: student.uid,
        type: 'broadcast',
        title: _titleCtrl.text.trim(),
        message: _messageCtrl.text.trim(),
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            '✅ Broadcast sent to ${students.length} students!'),
        backgroundColor: AppColors.secondary,
      ));
      _titleCtrl.clear();
      _messageCtrl.clear();
    }
    setState(() => _isSending = false);
  }
}
