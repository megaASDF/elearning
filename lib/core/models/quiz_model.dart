class QuizModel {
  final String id;
  final String courseId;
  final List<String> groupIds;
  final String title;
  final String description;
  final DateTime openTime;
  final DateTime closeTime;
  final int durationMinutes;
  final int maxAttempts;
  final int easyQuestions;
  final int mediumQuestions;
  final int hardQuestions;
  final List<String> questionIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  QuizModel({
    required this.id,
    required this.courseId,
    required this.groupIds,
    required this.title,
    required this.description,
    required this.openTime,
    required this.closeTime,
    required this.durationMinutes,
    required this.maxAttempts,
    required this.easyQuestions,
    required this.mediumQuestions,
    required this.hardQuestions,
    required this.questionIds,
    required this.createdAt,
    required this.updatedAt,
  });

  factory QuizModel.fromJson(Map<String, dynamic> json) {
    return QuizModel(
      id: json['id'] ?? json['_id'] ?? '',
      courseId: json['courseId'] ?? '',
      groupIds: List<String>.from(json['groupIds'] ?? []),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      openTime: DateTime.parse(json['openTime']),
      closeTime: DateTime.parse(json['closeTime']),
      durationMinutes: json['durationMinutes'] ?? 60,
      maxAttempts: json['maxAttempts'] ?? 1,
      easyQuestions: json['easyQuestions'] ?? 0,
      mediumQuestions: json['mediumQuestions'] ?? 0,
      hardQuestions: json['hardQuestions'] ?? 0,
      questionIds: List<String>.from(json['questionIds'] ?? []),
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
      'openTime': openTime.toIso8601String(),
      'closeTime': closeTime.toIso8601String(),
      'durationMinutes': durationMinutes,
      'maxAttempts': maxAttempts,
      'easyQuestions': easyQuestions,
      'mediumQuestions': mediumQuestions,
      'hardQuestions': hardQuestions,
      'questionIds': questionIds,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  bool get isOpen {
    final now = DateTime.now();
    return now.isAfter(openTime) && now.isBefore(closeTime);
  }

  bool get isClosed => DateTime.now().isAfter(closeTime);
  bool get isUpcoming => DateTime.now().isBefore(openTime);
  
  int get totalQuestions => easyQuestions + mediumQuestions + hardQuestions;
}