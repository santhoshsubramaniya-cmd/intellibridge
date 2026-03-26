import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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

  // ─── Listen to auth state changes ───
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ─── Fetch user profile from Firestore ───
  Future<UserModel?> fetchUserProfile(String uid) async {
    try {
      final doc = await _db
          .collection(AppConstants.colUsers)
          .doc(uid)
          .get();
      if (doc.exists) {
        _userModel = UserModel.fromMap(doc.data()!, uid);
        notifyListeners();
        return _userModel;
      }
    } catch (e) {
      debugPrint('fetchUserProfile error: $e');
    }
    return null;
  }

  // ─── REGISTER ───
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
      // Create Firebase Auth user
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user!.uid;

      // Build user document
      final user = UserModel(
        uid: uid,
        name: name,
        email: email,
        role: role,
        department: department,
        phone: phone,
        approved: role == AppConstants.roleAdmin, // admin auto-approved
        createdAt: DateTime.now(),
        course: course,
        semester: semester,
      );

      // Save to Firestore
      await _db
          .collection(AppConstants.colUsers)
          .doc(uid)
          .set(user.toMap());

      // If student, create empty profile
      if (role == AppConstants.roleStudent) {
        await _db
            .collection(AppConstants.colStudents)
            .doc(uid)
            .set({
          'uid': uid,
          'cgpa': 0.0,
          'attendance': 0,
          'skills': [],
          'internships': [],
          'projectCount': 0,
          'certCount': 0,
          'hireabilityScore': 0.0,
          'overallPercentile': 0,
          'deptPercentile': 0,
          'weakAreas': [],
          'suitableRoles': [],
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }

      _userModel = user;
      _isLoading = false;
      notifyListeners();
      return AuthResult.success;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      return _mapFirebaseError(e.code);
    }
  }

  // ─── LOGIN ───
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

      final uid = credential.user!.uid;
      final profile = await fetchUserProfile(uid);

      if (profile == null) {
        await _auth.signOut();
        _isLoading = false;
        notifyListeners();
        return AuthResult.userNotFound;
      }

      // Check admin approval (skip for admin role)
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
      _isLoading = false;
      notifyListeners();
      return _mapFirebaseError(e.code);
    }
  }

  // ─── LOGOUT ───
  Future<void> logout() async {
    await _auth.signOut();
    _userModel = null;
    notifyListeners();
  }

  // ─── RESET PASSWORD ───
  Future<AuthResult> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return AuthResult.success;
    } on FirebaseAuthException catch (e) {
      return _mapFirebaseError(e.code);
    }
  }

  // ─── Map Firebase errors to readable results ───
  AuthResult _mapFirebaseError(String code) {
    switch (code) {
      case 'user-not-found':
        return AuthResult.userNotFound;
      case 'wrong-password':
        return AuthResult.wrongPassword;
      case 'email-already-in-use':
        return AuthResult.emailInUse;
      case 'weak-password':
        return AuthResult.weakPassword;
      case 'invalid-email':
        return AuthResult.invalidEmail;
      default:
        return AuthResult.unknown;
    }
  }
}

enum AuthResult {
  success,
  userNotFound,
  wrongPassword,
  emailInUse,
  weakPassword,
  invalidEmail,
  notApproved,
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
        return 'Email already registered';
      case AuthResult.weakPassword:
        return 'Password must be at least 6 characters';
      case AuthResult.invalidEmail:
        return 'Invalid email address';
      case AuthResult.notApproved:
        return 'Your account is pending admin approval';
      case AuthResult.unknown:
        return 'Something went wrong. Please try again';
    }
  }
}