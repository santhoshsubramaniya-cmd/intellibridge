// note_model.dart
class NoteModel {
  final String id;
  final String title;
  final String department;
  final int semester;
  final String uploadedBy;
  final String fileUrl;
  final String fileName;
  final DateTime uploadedAt;
  final List<String> skillTags;
  final String aiSummary;

  NoteModel({
    required this.id,
    required this.title,
    required this.department,
    required this.semester,
    required this.uploadedBy,
    required this.fileUrl,
    required this.fileName,
    required this.uploadedAt,
    required this.skillTags,
    required this.aiSummary,
  });

  factory NoteModel.fromMap(Map<String, dynamic> map, String id) {
    return NoteModel(
      id: id,
      title: map['title'] ?? '',
      department: map['department'] ?? '',
      semester: map['semester'] ?? 1,
      uploadedBy: map['uploadedBy'] ?? '',
      fileUrl: map['fileUrl'] ?? '',
      fileName: map['fileName'] ?? '',
      uploadedAt: map['uploadedAt']?.toDate() ?? DateTime.now(),
      skillTags: List<String>.from(map['skillTags'] ?? []),
      aiSummary: map['aiSummary'] ?? '',
    );
  }
}

// result_model.dart
class ResultModel {
  final String id;
  final String studentEmail;
  final String subject;
  final int marks;
  final int semester;
  final String uploadedBy;
  final DateTime uploadedAt;

  ResultModel({
    required this.id,
    required this.studentEmail,
    required this.subject,
    required this.marks,
    required this.semester,
    required this.uploadedBy,
    required this.uploadedAt,
  });

  factory ResultModel.fromMap(Map<String, dynamic> map, String id) {
    return ResultModel(
      id: id,
      studentEmail: map['studentEmail'] ?? '',
      subject: map['subject'] ?? '',
      marks: map['marks'] ?? 0,
      semester: map['semester'] ?? 1,
      uploadedBy: map['uploadedBy'] ?? '',
      uploadedAt: map['uploadedAt']?.toDate() ?? DateTime.now(),
    );
  }

  String get grade {
    if (marks >= 90) return 'A+';
    if (marks >= 80) return 'A';
    if (marks >= 70) return 'B+';
    if (marks >= 60) return 'B';
    if (marks >= 50) return 'C';
    return 'F';
  }

  bool get isPassing => marks >= 40;
}
