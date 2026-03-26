// placement_drive_model.dart
class PlacementDrive {
  final String id;
  final String company;
  final DateTime visitDate;
  final String package;
  final double cgpaCutoff;
  final int percentileCutoff;
  final List<String> requiredSkills;
  final String description;
  final String role;
  final DateTime createdAt;

  PlacementDrive({
    required this.id,
    required this.company,
    required this.visitDate,
    required this.package,
    required this.cgpaCutoff,
    required this.percentileCutoff,
    required this.requiredSkills,
    required this.description,
    required this.role,
    required this.createdAt,
  });

  factory PlacementDrive.fromMap(Map<String, dynamic> map, String id) {
    return PlacementDrive(
      id: id,
      company: map['company'] ?? '',
      visitDate: map['visitDate']?.toDate() ?? DateTime.now(),
      package: map['package'] ?? '',
      cgpaCutoff: (map['cgpaCutoff'] ?? 6.0).toDouble(),
      percentileCutoff: map['percentileCutoff'] ?? 50,
      requiredSkills: List<String>.from(map['requiredSkills'] ?? []),
      description: map['description'] ?? '',
      role: map['role'] ?? '',
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'company': company,
        'visitDate': visitDate,
        'package': package,
        'cgpaCutoff': cgpaCutoff,
        'percentileCutoff': percentileCutoff,
        'requiredSkills': requiredSkills,
        'description': description,
        'role': role,
        'createdAt': createdAt,
      };

  int get daysLeft {
    return visitDate.difference(DateTime.now()).inDays;
  }

  bool isEligible(double cgpa, int percentile) {
    return cgpa >= cgpaCutoff && percentile >= percentileCutoff;
  }
}

// alert_model.dart
class AlertModel {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  AlertModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory AlertModel.fromMap(Map<String, dynamic> map, String id) {
    return AlertModel(
      id: id,
      userId: map['userId'] ?? '',
      type: map['type'] ?? 'info',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      isRead: map['isRead'] ?? false,
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
    );
  }
}
