import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/constants.dart';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String getChatRoomId(String userId, String mentorId) {
    final ids = [userId, mentorId]..sort();
    return ids.join('_');
  }

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

  Future<void> saveAiMessage({
    required String userId,
    required String role,
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

  Future<List<Map<String, dynamic>>> getAiChatHistory(String userId) async {
    final snap = await _db
        .collection('ai_chats')
        .doc(userId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(10)
        .get();
    return snap.docs.map((d) => d.data()).toList().reversed.toList();
  }

  Future<Map<String, dynamic>?> getMentorForStudent(String studentId) async {
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
