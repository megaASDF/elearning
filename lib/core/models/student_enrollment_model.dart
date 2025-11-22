class StudentEnrollmentModel {
  final String id;
  final String studentId;
  final String studentName;
  final String studentEmail;
  final String courseId;
  final String groupId;
  final String groupName;
  final DateTime enrolledAt;

  StudentEnrollmentModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
    required this.courseId,
    required this.groupId,
    required this.groupName,
    required this.enrolledAt,
  });

  factory StudentEnrollmentModel.fromJson(Map<String, dynamic> json) {
    return StudentEnrollmentModel(
      id: json['id'] ?? '',
      studentId: json['studentId'] ?? '',
      studentName: json['studentName'] ?? '',
      studentEmail: json['studentEmail'] ?? '',
      courseId: json['courseId'] ?? '',
      groupId: json['groupId'] ?? '',
      groupName: json['groupName'] ?? '',
      enrolledAt: json['enrolledAt'] != null
          ? DateTime.parse(json['enrolledAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentId': studentId,
      'studentName': studentName,
      'studentEmail': studentEmail,
      'courseId': courseId,
      'groupId': groupId,
      'groupName': groupName,
      'enrolledAt': enrolledAt.toIso8601String(),
    };
  }
}