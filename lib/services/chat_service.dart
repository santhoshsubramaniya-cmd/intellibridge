import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/constants.dart';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── Chat room helpers ────────────────────────────────
  String getChatRoomId(String userId, String mentorId) {
    final ids = [userId, mentorId]..sort();
    return ids.join('_');
  }

  Future<String> getOrCreateChatRoom(
      String studentId, String mentorId) async {
    final roomId = getChatRoomId(studentId, mentorId);
    final doc = await _db
        .collection(AppConstants.colMessages)
        .doc(roomId)
        .get();
    if (!doc.exists) {
      await _db
          .collection(AppConstants.colMessages)
          .doc(roomId)
          .set({
        'participants': [studentId, mentorId],
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'lastMessageAt': FieldValue.serverTimestamp(),
      });
    }
    return roomId;
  }

  // ─── Human-to-human messages ──────────────────────────
  Future<void> sendMessage({
    required String chatRoomId,
    required String senderId,
    required String senderName,
    required String text,
    required String type,
  }) async {
    await _db
        .collection(AppConstants.colMessages)
        .doc(chatRoomId)
        .collection('messages')
        .add({
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'type': type,
      'timestamp': FieldValue.serverTimestamp(),
    });
    await _db
        .collection(AppConstants.colMessages)
        .doc(chatRoomId)
        .set({
      'lastMessage': text,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'participants': chatRoomId.split('_'),
    }, SetOptions(merge: true));
  }

  Stream<QuerySnapshot> getMessages(String chatRoomId) {
    return _db
        .collection(AppConstants.colMessages)
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  Future<void> markAsRead(String chatRoomId, String userId) async {
    // Mark all messages in this room as read for this user
    await _db
        .collection(AppConstants.colMessages)
        .doc(chatRoomId)
        .set({'lastReadBy_$userId': FieldValue.serverTimestamp()},
            SetOptions(merge: true));
  }

  // ─── AI Chat messages ─────────────────────────────────
  /// Save a message to the AI chat history (used by AIMentorScreen)
  Future<void> saveAIChatMessage({
    required String userId,
    required String role, // 'user' or 'ai'
    required String text,
  }) async {
    await _db
        .collection('ai_chats')
        .doc(userId)
        .collection('messages')
        .add({
      'role': role,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Stream of AI chat messages for real-time updates
  Stream<QuerySnapshot> getAIChatStream(String userId) {
    return _db
        .collection('ai_chats')
        .doc(userId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  /// Fetch last N messages of AI chat as a plain list for context window
  Future<List<Map<String, dynamic>>> getAIChatHistory(
      String userId) async {
    final snap = await _db
        .collection('ai_chats')
        .doc(userId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(10)
        .get();
    return snap.docs
        .map((d) => d.data())
        .toList()
        .reversed
        .toList();
  }

  // ─── Legacy aliases (kept for backwards compat) ───────
  Future<void> saveAiMessage({
    required String userId,
    required String role,
    required String text,
  }) =>
      saveAIChatMessage(userId: userId, role: role, text: text);

  Future<List<Map<String, dynamic>>> getAiChatHistory(
          String userId) =>
      getAIChatHistory(userId);

  // ─── Mentor discovery ─────────────────────────────────
  /// Returns all approved faculty members as potential mentors
  Future<List<Map<String, dynamic>>> getMentors() async {
    final snap = await _db
        .collection(AppConstants.colUsers)
        .where('role', isEqualTo: 'faculty')
        .where('approved', isEqualTo: true)
        .get();
    return snap.docs
        .map((d) => {...d.data(), 'uid': d.id})
        .toList();
  }

  Future<Map<String, dynamic>?> getMentorForStudent(
      String studentId) async {
    final snap = await _db
        .collection('mentor_assignments')
        .where('studentId', isEqualTo: studentId)
        .limit(1)
        .get();
    if (snap.docs.isNotEmpty) return snap.docs.first.data();
    return null;
  }

  Future<void> assignMentor({
    required String studentId,
    required String mentorId,
    required String mentorName,
  }) async {
    await _db.collection('mentor_assignments').add({
      'studentId': studentId,
      'mentorId': mentorId,
      'mentorName': mentorName,
      'assignedAt': FieldValue.serverTimestamp(),
    });
  }
}
