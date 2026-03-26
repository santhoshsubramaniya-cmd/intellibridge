// Add these methods to firestore_service.dart
// This is a separate extension file for placement drives

import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/constants.dart';
import '../models/placement_drive_model.dart';

class PlacementDriveService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── Admin: Add placement drive ──────────────────────
  Future<String> addDrive(PlacementDrive drive) async {
    final doc = await _db
        .collection(AppConstants.colDrives)
        .add(drive.toMap());
    return doc.id;
  }

  // ─── Get all drives ───────────────────────────────────
  Stream<List<PlacementDrive>> getDrivesStream() {
    return _db
        .collection(AppConstants.colDrives)
        .orderBy('visitDate')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => PlacementDrive.fromMap(d.data(), d.id))
            .toList());
  }

  Future<List<PlacementDrive>> getUpcomingDrives() async {
    final snap = await _db
        .collection(AppConstants.colDrives)
        .where('visitDate', isGreaterThan: DateTime.now())
        .orderBy('visitDate')
        .get();
    return snap.docs
        .map((d) => PlacementDrive.fromMap(d.data(), d.id))
        .toList();
  }

  Future<void> deleteDrive(String driveId) async {
    await _db.collection(AppConstants.colDrives).doc(driveId).delete();
  }

  // ─── Training Plans ───────────────────────────────────
  Future<void> saveTrainingPlan({
    required String userId,
    required String driveId,
    required Map<String, dynamic> plan,
  }) async {
    await _db.collection(AppConstants.colTrainingPlans).add({
      'userId': userId,
      'driveId': driveId,
      'plan': plan,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<Map<String, dynamic>?> getTrainingPlan(
      String userId, String driveId) async {
    final snap = await _db
        .collection(AppConstants.colTrainingPlans)
        .where('userId', isEqualTo: userId)
        .where('driveId', isEqualTo: driveId)
        .limit(1)
        .get();
    if (snap.docs.isNotEmpty) {
      return snap.docs.first.data()['plan'] as Map<String, dynamic>?;
    }
    return null;
  }

  // ─── Drive Eligibility ────────────────────────────────
  Future<void> saveEligibility({
    required String userId,
    required String driveId,
    required bool isEligible,
    required int currentPercentile,
    required int gapToTarget,
  }) async {
    await _db.collection('drive_eligibility').doc('${userId}_$driveId').set({
      'userId': userId,
      'driveId': driveId,
      'isEligible': isEligible,
      'currentPercentile': currentPercentile,
      'gapToTarget': gapToTarget,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
