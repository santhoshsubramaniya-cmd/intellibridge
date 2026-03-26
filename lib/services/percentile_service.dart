import 'package:cloud_firestore/cloud_firestore.dart';

class PercentileService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  double calculateHireability({
    required double cgpa,
    required int skillCount,
    required int internships,
    required int attendance,
    required int projects,
    required int certs,
  }) {
    double score = 0;
    score += (cgpa / 10) * 25;
    score += (skillCount / 10).clamp(0.0, 1.0) * 20;
    score += (internships / 3).clamp(0.0, 1.0) * 20;
    score += (attendance / 100).clamp(0.0, 1.0) * 15;
    score += (projects / 5).clamp(0.0, 1.0) * 10;
    score += (certs / 5).clamp(0.0, 1.0) * 10;
    return score.clamp(0.0, 100.0);
  }

  Future<void> recalculateAllPercentiles() async {
    final studentsSnap = await _db.collection('students').get();
    if (studentsSnap.docs.isEmpty) return;

    final scores = <String, double>{};
    for (final doc in studentsSnap.docs) {
      final data = doc.data();
      scores[doc.id] = calculateHireability(
        cgpa: (data['cgpa'] ?? 0.0).toDouble(),
        skillCount: (data['skills'] as List?)?.length ?? 0,
        internships: (data['internships'] as List?)?.length ?? 0,
        attendance: data['attendance'] ?? 0,
        projects: data['projectCount'] ?? 0,
        certs: data['certCount'] ?? 0,
      );
    }

    final sortedScores = scores.values.toList()..sort();
    final total = sortedScores.length;

    final batch = _db.batch();
    for (final entry in scores.entries) {
      final rank = sortedScores.where((s) => s <= entry.value).length;
      final percentile = ((rank / total) * 100).round();
      batch.update(_db.collection('students').doc(entry.key), {
        'hireabilityScore': entry.value,
        'overallPercentile': percentile,
        'lastPercentileUpdate': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  Future<Map<String, dynamic>> getStudentPercentile(String userId) async {
    final studentDoc = await _db.collection('students').doc(userId).get();
    final student = studentDoc.data() ?? {};

    final myScore = calculateHireability(
      cgpa: (student['cgpa'] ?? 0.0).toDouble(),
      skillCount: (student['skills'] as List?)?.length ?? 0,
      internships: (student['internships'] as List?)?.length ?? 0,
      attendance: student['attendance'] ?? 0,
      projects: student['projectCount'] ?? 0,
      certs: student['certCount'] ?? 0,
    );

    final allSnap = await _db.collection('students').get();
    final allScores = allSnap.docs.map((d) => calculateHireability(
          cgpa: (d.data()['cgpa'] ?? 0.0).toDouble(),
          skillCount: (d.data()['skills'] as List?)?.length ?? 0,
          internships: (d.data()['internships'] as List?)?.length ?? 0,
          attendance: d.data()['attendance'] ?? 0,
          projects: d.data()['projectCount'] ?? 0,
          certs: d.data()['certCount'] ?? 0,
        )).toList();

    final rank = allScores.where((s) => s <= myScore).length;
    final percentile = allScores.isEmpty ? 0 : ((rank / allScores.length) * 100).round();

    return {
      'hireabilityScore': myScore,
      'overallPercentile': percentile,
      'totalStudents': allScores.length,
      'rank': allScores.length - rank + 1,
    };
  }

  Future<Map<String, dynamic>> checkDriveEligibility({
    required String userId,
    required String driveId,
  }) async {
    final studentDoc = await _db.collection('students').doc(userId).get();
    final driveDoc = await _db.collection('placement_drives').doc(driveId).get();

    if (!studentDoc.exists || !driveDoc.exists) {
      return {'eligible': false, 'reason': 'Data not found'};
    }

    final student = studentDoc.data()!;
    final drive = driveDoc.data()!;

    final cgpa = (student['cgpa'] ?? 0.0).toDouble();
    final minCgpa = (drive['minCgpa'] ?? 0.0).toDouble();
    final percentile = (student['overallPercentile'] ?? 0).toDouble();
    final requiredPercentile = (drive['percentileCutoff'] ?? 0).toDouble();
    final visitDate = (drive['visitDate'] as Timestamp).toDate();
    final daysLeft = visitDate.difference(DateTime.now()).inDays;

    return {
      'eligible': cgpa >= minCgpa && percentile >= requiredPercentile,
      'cgpaOk': cgpa >= minCgpa,
      'percentileOk': percentile >= requiredPercentile,
      'studentCgpa': cgpa,
      'requiredCgpa': minCgpa,
      'studentPercentile': percentile,
      'requiredPercentile': requiredPercentile,
      'percentileGap': (requiredPercentile - percentile).clamp(0, 100),
      'daysLeft': daysLeft,
    };
  }
}
