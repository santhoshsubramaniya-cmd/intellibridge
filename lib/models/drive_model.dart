import 'package:cloud_firestore/cloud_firestore.dart';

class PlacementDrive {
  final String id;
  final String company;
  final DateTime visitDate;
  final String package;
  final double minCgpa;
  final double percentileCutoff;
  final List<String> requiredSkills;
  final String role;
  final String description;
  final DateTime createdAt;

  PlacementDrive({
    required this.id,
    required this.company,
    required this.visitDate,
    required this.package,
    required this.minCgpa,
    required this.percentileCutoff,
    required this.requiredSkills,
    required this.role,
    required this.description,
    required this.createdAt,
  });

  factory PlacementDrive.fromMap(Map<String, dynamic> map, String id) {
    return PlacementDrive(
      id: id,
      company: map['company'] ?? '',
      visitDate: (map['visitDate'] as Timestamp).toDate(),
      package: map['package'] ?? '',
      minCgpa: (map['minCgpa'] ?? 0.0).toDouble(),
      percentileCutoff: (map['percentileCutoff'] ?? 0.0).toDouble(),
      requiredSkills: List<String>.from(map['requiredSkills'] ?? []),
      role: map['role'] ?? '',
      description: map['description'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'company': company,
      'visitDate': Timestamp.fromDate(visitDate),
      'package': package,
      'minCgpa': minCgpa,
      'percentileCutoff': percentileCutoff,
      'requiredSkills': requiredSkills,
      'role': role,
      'description': description,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  int get daysLeft => visitDate.difference(DateTime.now()).inDays;
  bool get isUpcoming => visitDate.isAfter(DateTime.now());
  bool get isUrgent => daysLeft <= 7 && daysLeft >= 0;
}
