import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../config/constants.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  UserModel? _userModel;
  UserModel? get userModel => _userModel;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── Fetch profile ──────────────────────────────────────────────────────────
  Future<UserModel?> fetchUserProfile(String uid) async {
    try {
      final doc = await _db
          .collection(AppConstants.colUsers)
          .doc(uid)
          .get();
      if (doc.exists && doc.data() != null) {
        _userModel = UserModel.fromMap(doc.data()!, uid);
        notifyListeners();
        return _userModel;
      }
    } on FirebaseException catch (e) {
      debugPrint('fetchUserProfile error [${e.code}]: ${e.message}');
    } catch (e) {
      debugPrint('fetchUserProfile unknown error: $e');
    }
    return null;
  }

  // ── Register ───────────────────────────────────────────────────────────────
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    required String role,
    required String department,
    required String phone,
    String? course,
    int? semester,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Step 1 — Create Firebase Auth user
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = credential.user!.uid;

      // Step 2 — Build the user model
      final user = UserModel(
        uid: uid,
        name: name,
        email: email,
        role: role,
        department: department,
        phone: phone,
        approved: role == AppConstants.roleAdmin,
        createdAt: DateTime.now(),
        course: course,
        semester: semester,
      );

      // Step 3 — Write to 'users' collection
      // toMap() does NOT include uid by default, so we add it manually.
      // This makes it easier to query the doc without relying on doc.id.
      final userMap = {
        ...user.toMap(),
        'uid': uid, // explicit uid field inside the document
      };

      await _db
          .collection(AppConstants.colUsers)
          .doc(uid)
          .set(userMap);

      // Step 4 — For students, also create their placement profile
      if (role == AppConstants.roleStudent) {
        await _db
            .collection(AppConstants.colStudents)
            .doc(uid)
            .set({
          'uid': uid,
          'cgpa': 0.0,
          'attendance': 0,
          'skills': <String>[],
          'internships': <Map<String, dynamic>>[],
          'projectCount': 0,
          'certCount': 0,
          'hireabilityScore': 0.0,
          'overallPercentile': 0,
          'deptPercentile': 0,
          'weakAreas': <String>[],
          'suitableRoles': <String>[],
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }

      _userModel = user;
      _isLoading = false;
      notifyListeners();
      return AuthResult.success;

    } on FirebaseAuthException catch (e) {
      // Auth-level errors: wrong password, email in use, etc.
      debugPrint('register FirebaseAuthException [${e.code}]: ${e.message}');
      _isLoading = false;
      notifyListeners();
      return _mapAuthError(e.code);

    } on FirebaseException catch (e) {
      // Firestore write errors (permission denied, database not found, etc.)
      // These were previously swallowed because only FirebaseAuthException was caught.
      debugPrint('register FirebaseException (Firestore) [${e.code}]: ${e.message}');
      // Auth account was created but profile write failed — delete the orphan Auth user
      try {
        await _auth.currentUser?.delete();
      } catch (_) {}
      _isLoading = false;
      notifyListeners();
      return AuthResult.firestoreError;

    } catch (e) {
      debugPrint('register unknown error: $e');
      try {
        await _auth.currentUser?.delete();
      } catch (_) {}
      _isLoading = false;
      notifyListeners();
      return AuthResult.unknown;
    }
  }

  // ── Login ──────────────────────────────────────────────────────────────────
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final profile = await fetchUserProfile(credential.user!.uid);

      if (profile == null) {
        await _auth.signOut();
        _isLoading = false;
        notifyListeners();
        return AuthResult.userNotFound;
      }

      if (!profile.approved && profile.role != AppConstants.roleAdmin) {
        await _auth.signOut();
        _isLoading = false;
        notifyListeners();
        return AuthResult.notApproved;
      }

      _isLoading = false;
      notifyListeners();
      return AuthResult.success;

    } on FirebaseAuthException catch (e) {
      debugPrint('login FirebaseAuthException [${e.code}]: ${e.message}');
      _isLoading = false;
      notifyListeners();
      return _mapAuthError(e.code);

    } on FirebaseException catch (e) {
      debugPrint('login FirebaseException [${e.code}]: ${e.message}');
      _isLoading = false;
      notifyListeners();
      return AuthResult.firestoreError;

    } catch (e) {
      debugPrint('login unknown error: $e');
      _isLoading = false;
      notifyListeners();
      return AuthResult.unknown;
    }
  }

  // ── Logout ─────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    await _auth.signOut();
    _userModel = null;
    notifyListeners();
  }

  // ── Password reset ─────────────────────────────────────────────────────────
  Future<AuthResult> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return AuthResult.success;
    } on FirebaseAuthException catch (e) {
      return _mapAuthError(e.code);
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  AuthResult _mapAuthError(String code) {
    switch (code) {
      case 'user-not-found':
      case 'invalid-credential':
        return AuthResult.userNotFound;
      case 'wrong-password':
        return AuthResult.wrongPassword;
      case 'email-already-in-use':
        return AuthResult.emailInUse;
      case 'weak-password':
        return AuthResult.weakPassword;
      case 'invalid-email':
        return AuthResult.invalidEmail;
      case 'too-many-requests':
        return AuthResult.tooManyRequests;
      default:
        return AuthResult.unknown;
    }
  }
}

// ── Auth result enum ───────────────────────────────────────────────────────
enum AuthResult {
  success,
  userNotFound,
  wrongPassword,
  emailInUse,
  weakPassword,
  invalidEmail,
  notApproved,
  firestoreError,
  tooManyRequests,
  unknown,
}

extension AuthResultMessage on AuthResult {
  String get message {
    switch (this) {
      case AuthResult.success:
        return 'Success';
      case AuthResult.userNotFound:
        return 'No account found with this email';
      case AuthResult.wrongPassword:
        return 'Incorrect password';
      case AuthResult.emailInUse:
        return 'This email is already registered';
      case AuthResult.weakPassword:
        return 'Password must be at least 6 characters';
      case AuthResult.invalidEmail:
        return 'Invalid email address';
      case AuthResult.notApproved:
        return 'Your account is pending admin approval';
      case AuthResult.firestoreError:
        return 'Could not save your profile. Check your internet connection.';
      case AuthResult.tooManyRequests:
        return 'Too many attempts. Please try again later.';
      case AuthResult.unknown:
        return 'Something went wrong. Please try again.';
    }
  }
}
