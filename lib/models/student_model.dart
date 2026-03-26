class StudentProfile {
  final String uid;
  final double cgpa;
  final int attendance;
  final List<String> skills;
  final List<Map<String, dynamic>> internships;
  final int projectCount;
  final int certCount;
  final double hireabilityScore;
  final int overallPercentile;
  final int deptPercentile;
  final String? strongestDomain;
  final List<String> weakAreas;
  final List<String> suitableRoles;
  final DateTime lastUpdated;

  StudentProfile({
    required this.uid,
    required this.cgpa,
    required this.attendance,
    required this.skills,
    required this.internships,
    required this.projectCount,
    required this.certCount,
    required this.hireabilityScore,
    required this.overallPercentile,
    required this.deptPercentile,
    this.strongestDomain,
    required this.weakAreas,
    required this.suitableRoles,
    required this.lastUpdated,
  });

  factory StudentProfile.empty(String uid) {
    return StudentProfile(
      uid: uid,
      cgpa: 0.0,
      attendance: 0,
      skills: [],
      internships: [],
      projectCount: 0,
      certCount: 0,
      hireabilityScore: 0.0,
      overallPercentile: 0,
      deptPercentile: 0,
      weakAreas: [],
      suitableRoles: [],
      lastUpdated: DateTime.now(),
    );
  }

  factory StudentProfile.fromMap(Map<String, dynamic> map) {
    return StudentProfile(
      uid: map['uid'] ?? '',
      cgpa: (map['cgpa'] ?? 0.0).toDouble(),
      attendance: map['attendance'] ?? 0,
      skills: List<String>.from(map['skills'] ?? []),
      internships: List<Map<String, dynamic>>.from(map['internships'] ?? []),
      projectCount: map['projectCount'] ?? 0,
      certCount: map['certCount'] ?? 0,
      hireabilityScore: (map['hireabilityScore'] ?? 0.0).toDouble(),
      overallPercentile: map['overallPercentile'] ?? 0,
      deptPercentile: map['deptPercentile'] ?? 0,
      strongestDomain: map['strongestDomain'],
      weakAreas: List<String>.from(map['weakAreas'] ?? []),
      suitableRoles: List<String>.from(map['suitableRoles'] ?? []),
      lastUpdated: map['lastUpdated']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'cgpa': cgpa,
      'attendance': attendance,
      'skills': skills,
      'internships': internships,
      'projectCount': projectCount,
      'certCount': certCount,
      'hireabilityScore': hireabilityScore,
      'overallPercentile': overallPercentile,
      'deptPercentile': deptPercentile,
      'strongestDomain': strongestDomain,
      'weakAreas': weakAreas,
      'suitableRoles': suitableRoles,
      'lastUpdated': lastUpdated,
    };
  }
}
