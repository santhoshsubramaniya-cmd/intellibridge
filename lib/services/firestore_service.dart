import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import '../config/constants.dart';
import '../models/user_model.dart';
import '../models/student_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ─── USERS ────────────────────────────────────────────

  /// Real-time stream — Approvals tab uses this so the list
  /// auto-refreshes the moment you approve or reject someone.
  Stream<List<UserModel>> pendingUsersStream() {
    return _db
        .collection(AppConstants.colUsers)
        .where('approved', isEqualTo: false)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => UserModel.fromMap(d.data(), d.id)).toList());
  }

  /// One-shot fetch — kept for backwards compat.
  Future<List<UserModel>> getPendingUsers() async {
    final snap = await _db
        .collection(AppConstants.colUsers)
        .where('approved', isEqualTo: false)
        .get();
    return snap.docs
        .map((d) => UserModel.fromMap(d.data(), d.id))
        .toList();
  }

  Future<void> approveUser(String uid) async {
    await _db
        .collection(AppConstants.colUsers)
        .doc(uid)
        .update({'approved': true});
  }

  Future<void> rejectUser(String uid) async {
    // Delete from Auth is not possible client-side without re-auth,
    // so we delete the Firestore doc and also delete the students doc if present.
    await _db.collection(AppConstants.colUsers).doc(uid).delete();
    try {
      await _db.collection(AppConstants.colStudents).doc(uid).delete();
    } catch (_) {}
  }

  Future<List<UserModel>> getAllStudents() async {
    final snap = await _db
        .collection(AppConstants.colUsers)
        .where('role', isEqualTo: 'student')
        .where('approved', isEqualTo: true)
        .get();
    return snap.docs
        .map((d) => UserModel.fromMap(d.data(), d.id))
        .toList();
  }

  Future<List<UserModel>> getAllFaculty() async {
    final snap = await _db
        .collection(AppConstants.colUsers)
        .where('role', isEqualTo: 'faculty')
        .where('approved', isEqualTo: true)
        .get();
    return snap.docs
        .map((d) => UserModel.fromMap(d.data(), d.id))
        .toList();
  }

  // ─── STUDENT PROFILE ──────────────────────────────────

  Future<StudentProfile?> getStudentProfile(String uid) async {
    final doc =
        await _db.collection(AppConstants.colStudents).doc(uid).get();
    if (doc.exists) return StudentProfile.fromMap(doc.data()!);
    return null;
  }

  Stream<StudentProfile?> studentProfileStream(String uid) {
    return _db
        .collection(AppConstants.colStudents)
        .doc(uid)
        .snapshots()
        .map((d) => d.exists ? StudentProfile.fromMap(d.data()!) : null);
  }

  // ─── NOTES ────────────────────────────────────────────

  Future<void> uploadNote({
    required String title,
    required String department,
    required int semester,
    required String uploadedBy,
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    final ref = _storage
        .ref()
        .child('notes/${DateTime.now().millisecondsSinceEpoch}_$fileName');
    await ref.putData(fileBytes);
    final fileUrl = await ref.getDownloadURL();

    await _db.collection(AppConstants.colNotes).add({
      'title': title,
      'department': department.toLowerCase(),
      'semester': semester,
      'uploadedBy': uploadedBy,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'uploadedAt': FieldValue.serverTimestamp(),
      'skillTags': [],
      'aiSummary': '',
    });
  }

  Stream<QuerySnapshot> getNotesForStudent(String course, int semester) {
    return _db
        .collection(AppConstants.colNotes)
        .where('department', isEqualTo: course.toLowerCase())
        .where('semester', isEqualTo: semester)
        .orderBy('uploadedAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getAllNotes() {
    return _db
        .collection(AppConstants.colNotes)
        .orderBy('uploadedAt', descending: true)
        .snapshots();
  }

  Future<void> deleteNote(String noteId, String fileUrl) async {
    await _db.collection(AppConstants.colNotes).doc(noteId).delete();
    try {
      await _storage.refFromURL(fileUrl).delete();
    } catch (_) {}
  }

  // ─── RESULTS ──────────────────────────────────────────

  Future<void> postResult({
    required String studentEmail,
    required String subject,
    required int marks,
    required int semester,
    required String uploadedBy,
  }) async {
    await _db.collection(AppConstants.colResults).add({
      'studentEmail': studentEmail.toLowerCase(),
      'subject': subject,
      'marks': marks,
      'semester': semester,
      'uploadedBy': uploadedBy,
      'uploadedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getResultsForStudent(String email) {
    return _db
        .collection(AppConstants.colResults)
        .where('studentEmail', isEqualTo: email.toLowerCase())
        .orderBy('semester')
        .snapshots();
  }

  Stream<QuerySnapshot> getAllResults() {
    return _db
        .collection(AppConstants.colResults)
        .orderBy('uploadedAt', descending: true)
        .snapshots();
  }

  Future<void> deleteResult(String resultId) async {
    await _db.collection(AppConstants.colResults).doc(resultId).delete();
  }

  // ─── ANNOUNCEMENTS ────────────────────────────────────

  Future<void> postAnnouncement({
    required String title,
    required String message,
    required String postedBy,
    String target = 'all',
  }) async {
    await _db.collection(AppConstants.colAnnouncements).add({
      'title': title,
      'message': message,
      'postedBy': postedBy,
      'target': target,
      'postedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getAnnouncements() {
    return _db
        .collection(AppConstants.colAnnouncements)
        .orderBy('postedAt', descending: true)
        .snapshots();
  }

  Future<void> deleteAnnouncement(String id) async {
    await _db.collection(AppConstants.colAnnouncements).doc(id).delete();
  }

  // ─── ALERTS ───────────────────────────────────────────

  Future<void> createAlert({
    required String userId,
    required String type,
    required String title,
    required String message,
  }) async {
    await _db.collection(AppConstants.colAlerts).add({
      'userId': userId,
      'type': type,
      'title': title,
      'message': message,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getAlertsForUser(String userId) {
    return _db
        .collection(AppConstants.colAlerts)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> markAlertRead(String alertId) async {
    await _db
        .collection(AppConstants.colAlerts)
        .doc(alertId)
        .update({'isRead': true});
  }

  Future<int> getUnreadAlertCount(String userId) async {
    final snap = await _db
        .collection(AppConstants.colAlerts)
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .count()
        .get();
    return snap.count ?? 0;
  }

  // ─── ANALYTICS (Admin) ────────────────────────────────

  Future<Map<String, dynamic>> getCollegeAnalytics() async {
    final studentsSnap = await _db
        .collection(AppConstants.colUsers)
        .where('role', isEqualTo: 'student')
        .where('approved', isEqualTo: true)
        .count()
        .get();

    final pendingSnap = await _db
        .collection(AppConstants.colUsers)
        .where('approved', isEqualTo: false)
        .count()
        .get();

    final notesSnap =
        await _db.collection(AppConstants.colNotes).count().get();

    return {
      'totalStudents': studentsSnap.count ?? 0,
      'pendingApprovals': pendingSnap.count ?? 0,
      'totalNotes': notesSnap.count ?? 0,
    };
  }
}
