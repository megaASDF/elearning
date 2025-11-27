class AssignmentModel {
  final String id;
  final String courseId;
  final List<String> groupIds;
  final String title;
  final String description;
  final List<String> attachments;
  final DateTime startDate;
  final DateTime deadline;
  final DateTime? lateDeadline;
  final bool allowLateSubmission;
  final int maxAttempts;
  final List<String> allowedFileFormats;
  final double maxFileSizeMB;
  final DateTime createdAt;
  final DateTime updatedAt;

  AssignmentModel({
    required this.id,
    required this.courseId,
    required this.groupIds,
    required this.title,
    required this.description,
    required this.attachments,
    required this.startDate,
    required this.deadline,
    this.lateDeadline,
    required this.allowLateSubmission,
    required this.maxAttempts,
    required this.allowedFileFormats,
    required this.maxFileSizeMB,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AssignmentModel.fromJson(Map<String, dynamic> json) {
    return AssignmentModel(
      id: json['id'] ?? json['_id'] ?? '',
      courseId: json['courseId'] ?? '',
      groupIds: List<String>.from(json['groupIds'] ?? []),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      attachments: List<String>.from(json['attachments'] ?? []),
      startDate: DateTime.parse(json['startDate']),
      deadline: DateTime.parse(json['deadline']),
      lateDeadline: json['lateDeadline'] != null 
          ? DateTime.parse(json['lateDeadline']) 
          : null,
      allowLateSubmission: json['allowLateSubmission'] ?? false,
      maxAttempts: json['maxAttempts'] ?? 1,
      allowedFileFormats: List<String>.from(json['allowedFileFormats'] ?? []),
      maxFileSizeMB: (json['maxFileSizeMB'] ?? 10).toDouble(),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courseId': courseId,
      'groupIds': groupIds,
      'title': title,
      'description': description,
      'attachments': attachments,
      'startDate': startDate.toIso8601String(),
      'deadline': deadline.toIso8601String(),
      'lateDeadline': lateDeadline?.toIso8601String(),
      'allowLateSubmission': allowLateSubmission,
      'maxAttempts': maxAttempts,
      'allowedFileFormats': allowedFileFormats,
      'maxFileSizeMB': maxFileSizeMB,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(deadline);
  }

  bool get isPastDeadline {
    return DateTime.now().isAfter(deadline);
  }

  bool get canSubmitLate {
    if (!allowLateSubmission || lateDeadline == null) return false;
    return DateTime.now().isBefore(lateDeadline!);
  }
}