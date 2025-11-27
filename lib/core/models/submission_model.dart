class SubmissionModel {
  final String id;
  final String assignmentId;
  final String studentId;
  final String studentName;
  final String studentEmail;
  final List<String> files;
  final String? comment;
  final DateTime submittedAt;
  final int attemptNumber;
  final bool isLate;
  final double? grade;
  final String? feedback;
  final DateTime? gradedAt;

  SubmissionModel({
    required this.id,
    required this.assignmentId,
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
    required this.files,
    this.comment,
    required this.submittedAt,
    required this.attemptNumber,
    required this.isLate,
    this.grade,
    this.feedback,
    this.gradedAt,
  });

  factory SubmissionModel.fromJson(Map<String, dynamic> json) {
    return SubmissionModel(
      id: json['id'] ?? json['_id'] ?? '',
      assignmentId: json['assignmentId'] ?? '',
      studentId: json['studentId'] ?? '',
      studentName: json['studentName'] ?? '',
      studentEmail: json['studentEmail'] ?? '',
      files: List<String>.from(json['files'] ?? []),
      comment: json['comment'],
      submittedAt: DateTime.parse(json['submittedAt']),
      attemptNumber: json['attemptNumber'] ?? 1,
      isLate: json['isLate'] ?? false,
      grade: json['grade']?.toDouble(),
      feedback: json['feedback'],
      gradedAt: json['gradedAt'] != null ? DateTime.parse(json['gradedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'assignmentId': assignmentId,
      'studentId': studentId,
      'studentName': studentName,
      'studentEmail': studentEmail,
      'files': files,
      'comment': comment,
      'submittedAt': submittedAt.toIso8601String(),
      'attemptNumber': attemptNumber,
      'isLate': isLate,
      'grade': grade,
      'feedback': feedback,
      'gradedAt': gradedAt?.toIso8601String(),
    };
  }

  bool get isGraded => grade != null;
}