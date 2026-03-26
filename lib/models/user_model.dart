class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role; // student / faculty / admin / recruiter
  final String department;
  final String phone;
  final String? photoUrl;
  final bool approved;
  final DateTime createdAt;

  // Student-specific
  final String? course;
  final int? semester;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.department,
    required this.phone,
    this.photoUrl,
    required this.approved,
    required this.createdAt,
    this.course,
    this.semester,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'student',
      department: map['department'] ?? '',
      phone: map['phone'] ?? '',
      photoUrl: map['photoUrl'],
      approved: map['approved'] ?? false,
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
      course: map['course'],
      semester: map['semester'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'department': department,
      'phone': phone,
      'photoUrl': photoUrl,
      'approved': approved,
      'createdAt': createdAt,
      'course': course,
      'semester': semester,
    };
  }

  // Helper getters
  bool get isStudent => role == 'student';
  bool get isFaculty => role == 'faculty';
  bool get isAdmin => role == 'admin';
  bool get isRecruiter => role == 'recruiter';
}
