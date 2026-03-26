import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../config/themes.dart';
import '../../../services/auth_service.dart';
import '../../../services/chat_service.dart';
import '../../../services/gemini_service.dart';
import '../../../services/firestore_service.dart';

class AIMentorScreen extends StatefulWidget {
  const AIMentorScreen({super.key});

  @override
  State<AIMentorScreen> createState() => _AIMentorScreenState();
}

class _AIMentorScreenState extends State<AIMentorScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _chatService = ChatService();
  final _gemini = GeminiService();
  final _fs = FirestoreService();
  bool _isTyping = false;

  final List<String> _quickPrompts = [
    'Am I ready for placement?',
    'What should I learn this week?',
    'Which companies suit my profile?',
    'How to improve my CGPA impact?',
    'What are my weakest areas?',
  ];

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;

    final user = context.read<AuthService>().userModel;
    if (user == null) return;

    _msgCtrl.clear();
    setState(() => _isTyping = true);

    // Save user message
    await _chatService.saveAIChatMessage(
      userId: user.uid,
      role: 'user',
      text: text,
    );

    _scrollToBottom();

    // Get student profile for context
    final profile = await _fs.getStudentProfile(user.uid);
    final studentData = profile?.toMap() ?? {};

    // Get chat history
    final history = await _chatService.getAIChatHistory(user.uid);

    // Get AI reply
    final reply = await _gemini.mentorReply(
      userId: user.uid,
      message: text,
      studentData: studentData,
      chatHistory: history,
    );

    // Save AI reply
    await _chatService.saveAIChatMessage(
      userId: user.uid,
      role: 'ai',
      text: reply,
    );

    setState(() => _isTyping = false);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().userModel;

    return Column(
      children: [
        // AI mentor header
        Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withOpacity(0.1),
                AppColors.secondary.withOpacity(0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: AppColors.primary.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.psychology_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('SmartPlace AI Mentor',
                        style: TextStyle(
                            fontFamily: 'Syne',
                            fontWeight: FontWeight.w700,
                            fontSize: 14)),
                    const Text(
                        'Knows your profile · Available 24/7',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppColors.lightMuted)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('Online',
                    style: TextStyle(
                        fontSize: 10,
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),

        // Quick prompts
        SizedBox(
          height: 36,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _quickPrompts.length,
            itemBuilder: (context, i) => GestureDetector(
              onTap: () {
                _msgCtrl.text = _quickPrompts[i];
                _sendMessage();
              },
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Text(_quickPrompts[i],
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.primary)),
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Messages
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _chatService.getAIChatStream(user?.uid ?? ''),
            builder: (context, snapshot) {
              if (!snapshot.hasData ||
                  snapshot.data!.docs.isEmpty) {
                return _EmptyChat();
              }

              final docs = snapshot.data!.docs;
              WidgetsBinding.instance.addPostFrameCallback(
                  (_) => _scrollToBottom());

              return ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount:
                    docs.length + (_isTyping ? 1 : 0),
                itemBuilder: (context, i) {
                  if (_isTyping && i == docs.length) {
                    return _TypingIndicator();
                  }
                  final data =
                      docs[i].data() as Map<String, dynamic>;
                  final isUser = data['role'] == 'user';
                  return _MessageBubble(
                    text: data['text'] ?? '',
                    isUser: isUser,
                    time: data['timestamp']?.toDate(),
                  )
                      .animate()
                      .fadeIn(duration: 300.ms)
                      .slideY(begin: 0.2);
                },
              );
            },
          ),
        ),

        // Input
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkBorder
                    : AppColors.lightBorder,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _msgCtrl,
                  maxLines: 3,
                  minLines: 1,
                  decoration: InputDecoration(
                    hintText: 'Ask your AI mentor anything...',
                    hintStyle: const TextStyle(fontSize: 13),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor:
                        Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkBorder.withOpacity(0.5)
                            : AppColors.lightBorder.withOpacity(0.5),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _isTyping ? null : _sendMessage,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _isTyping
                        ? AppColors.lightMuted
                        : AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.send_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final DateTime? time;
  const _MessageBubble(
      {required this.text, required this.isUser, this.time});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment:
          isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser
              ? AppColors.primary
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: isUser
              ? null
              : Border.all(
                  color: Theme.of(context).brightness ==
                          Brightness.dark
                      ? AppColors.darkBorder
                      : AppColors.lightBorder,
                ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (!isUser)
              const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text('AI Mentor',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary)),
              ),
            Text(
              text,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: isUser ? Colors.white : null,
              ),
            ),
            if (time != null) ...[
              const SizedBox(height: 4),
              Text(
                '${time!.hour}:${time!.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 10,
                  color: isUser
                      ? Colors.white60
                      : AppColors.lightMuted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
          ),
          border: Border.all(color: AppColors.lightBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('AI is thinking',
                style: TextStyle(
                    fontSize: 12, color: AppColors.lightMuted)),
            const SizedBox(width: 8),
            SizedBox(
              width: 30,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  3,
                  (i) => _Dot(delay: Duration(milliseconds: i * 200)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final Duration delay;
  const _Dot({required this.delay});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .fadeIn(delay: delay, duration: 400.ms)
        .then()
        .fadeOut(duration: 400.ms);
  }
}

class _EmptyChat extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.psychology_rounded,
                color: Colors.white, size: 36),
          ),
          const SizedBox(height: 16),
          const Text('Your AI Mentor',
              style: TextStyle(
                  fontFamily: 'Syne',
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text(
              'I know your profile, results, and placement status.\nAsk me anything!',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.lightMuted,
                  fontSize: 13,
                  height: 1.6)),
        ],
      ),
    );
  }
}
