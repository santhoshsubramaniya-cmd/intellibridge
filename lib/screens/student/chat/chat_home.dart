import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../config/themes.dart';
import '../../../services/auth_service.dart';
import '../../../services/chat_service.dart';
import 'ai_mentor_screen.dart';
import 'mentor_chat_screen.dart';

class ChatHome extends StatefulWidget {
  const ChatHome({super.key});

  @override
  State<ChatHome> createState() => _ChatHomeState();
}

class _ChatHomeState extends State<ChatHome>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _chatService = ChatService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.lightMuted,
          tabs: const [
            Tab(icon: Icon(Icons.psychology_rounded), text: 'AI Mentor'),
            Tab(
                icon: Icon(Icons.people_rounded),
                text: 'Placement Mentor'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          AIMentorScreen(),
          _MentorListScreen(),
        ],
      ),
    );
  }
}

class _MentorListScreen extends StatelessWidget {
  const _MentorListScreen();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().userModel;
    final chatService = ChatService();

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: chatService.getMentors(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final mentors = snapshot.data ?? [];

        if (mentors.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline,
                    size: 64,
                    color: AppColors.lightMuted.withOpacity(0.5)),
                const SizedBox(height: 16),
                const Text('No mentors available yet',
                    style: TextStyle(
                        fontFamily: 'Syne',
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                const Text(
                    'Faculty members will appear here as placement mentors',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: AppColors.lightMuted, fontSize: 13)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: mentors.length,
          itemBuilder: (context, i) {
            final mentor = mentors[i];
            return _MentorCard(
              mentor: mentor,
              studentId: user?.uid ?? '',
            )
                .animate()
                .fadeIn(delay: Duration(milliseconds: i * 80))
                .slideX(begin: 0.1);
          },
        );
      },
    );
  }
}

class _MentorCard extends StatelessWidget {
  final Map<String, dynamic> mentor;
  final String studentId;
  const _MentorCard({required this.mentor, required this.studentId});

  @override
  Widget build(BuildContext context) {
    final name = mentor['name'] ?? 'Faculty';
    final dept = mentor['department'] ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'M';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MentorChatScreen(
            mentorId: mentor['uid'],
            mentorName: name,
            studentId: studentId,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkBorder
                : AppColors.lightBorder,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.facultyColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(initial,
                    style: const TextStyle(
                        fontFamily: 'Syne',
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        color: AppColors.facultyColor)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontFamily: 'Syne',
                          fontWeight: FontWeight.w700,
                          fontSize: 15)),
                  Text(dept,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.lightMuted)),
                  const Text('Placement Mentor',
                      style: TextStyle(
                          fontSize: 11,
                          color: AppColors.facultyColor,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.chat_bubble_outline_rounded,
                  color: AppColors.primary, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
