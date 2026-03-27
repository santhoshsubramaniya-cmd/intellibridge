import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../config/themes.dart';
import '../../../services/auth_service.dart';
import '../../../services/chat_service.dart';

class MentorChatScreen extends StatefulWidget {
  final String mentorId;
  final String mentorName;
  final String studentId;

  const MentorChatScreen({
    super.key,
    required this.mentorId,
    required this.mentorName,
    required this.studentId,
  });

  @override
  State<MentorChatScreen> createState() => _MentorChatScreenState();
}

class _MentorChatScreenState extends State<MentorChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _chatService = ChatService();
  String? _chatRoomId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initRoom();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _initRoom() async {
    final roomId = await _chatService.getOrCreateChatRoom(
        widget.studentId, widget.mentorId);
    setState(() {
      _chatRoomId = roomId;
      _isLoading = false;
    });
    // Mark messages as read
  _chatService.markAsRead(roomId, widget.studentId);
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _chatRoomId == null) return;
    _msgCtrl.clear();

    final user = context.read<AuthService>().userModel;
    await _chatService.sendMessage(
      chatRoomId: _chatRoomId!,
      senderId: widget.studentId,
      senderName: user?.name ?? 'Student',
      text: text,
      type: 'human',
    );
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
    final initial = widget.mentorName.isNotEmpty
        ? widget.mentorName[0].toUpperCase()
        : 'M';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.facultyColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(initial,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.facultyColor)),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.mentorName,
                    style: const TextStyle(fontSize: 15)),
                const Text('Placement Mentor',
                    style: TextStyle(
                        fontSize: 11,
                        color: AppColors.facultyColor)),
              ],
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Messages
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream:
                        _chatService.getMessages(_chatRoomId!),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData ||
                          snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              const Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 48,
                                  color: AppColors.lightMuted),
                              const SizedBox(height: 12),
                              Text(
                                'Start a conversation with ${widget.mentorName}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: AppColors.lightMuted,
                                    fontSize: 13),
                              ),
                            ],
                          ),
                        );
                      }

                      final docs = snapshot.data!.docs;
                      WidgetsBinding.instance.addPostFrameCallback(
                          (_) => _scrollToBottom());

                      return ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.all(16),
                        itemCount: docs.length,
                        itemBuilder: (context, i) {
                          final data = docs[i].data()
                              as Map<String, dynamic>;
                          final isMe =
                              data['senderId'] == widget.studentId;
                          return _Bubble(
                            text: data['text'] ?? '',
                            isMe: isMe,
                            senderName:
                                data['senderName'] ?? '',
                            time: data['timestamp']?.toDate(),
                          );
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
                        color: Theme.of(context).brightness ==
                                Brightness.dark
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
                            hintText:
                                'Message ${widget.mentorName}...',
                            hintStyle:
                                const TextStyle(fontSize: 13),
                            contentPadding:
                                const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Theme.of(context)
                                        .brightness ==
                                    Brightness.dark
                                ? AppColors.darkBorder
                                    .withOpacity(0.5)
                                : AppColors.lightBorder
                                    .withOpacity(0.5),
                          ),
                          onSubmitted: (_) => _send(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _send,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
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
            ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final String senderName;
  final DateTime? time;
  const _Bubble(
      {required this.text,
      required this.isMe,
      required this.senderName,
      this.time});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment:
          isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe
              ? AppColors.primary
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          border: isMe
              ? null
              : Border.all(color: AppColors.lightBorder),
        ),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Text(senderName,
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.facultyColor)),
            const SizedBox(height: 2),
            Text(text,
                style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: isMe ? Colors.white : null)),
            if (time != null)
              Text(
                '${time!.hour}:${time!.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                    fontSize: 10,
                    color: isMe
                        ? Colors.white60
                        : AppColors.lightMuted),
              ),
          ],
        ),
      ),
    );
  }
}
