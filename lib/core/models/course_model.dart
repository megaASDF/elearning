class CourseModel {
  final String id;
  final String semesterId;
  final String code;
  final String name;
  final String description;
  final String instructorName;
  final int numberOfSessions;
  final int groupCount;
  final int studentCount;
  final String createdAt;

  CourseModel({
    required this.id,
    required this.semesterId,
    required this.code,
    required this.name,
    required this.description,
    required this.instructorName,
    this.numberOfSessions = 15, // Default value
    this.groupCount = 0,
    this.studentCount = 0,
    required this.createdAt,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    return CourseModel(
      id: json['id'] ?? '',
      semesterId: json['semesterId'] ?? '',
      code: json['code'] ?? '',
      name: json['name'] ??  '',
      description: json['description'] ?? '',
      instructorName: json['instructorName'] ??  '',
      numberOfSessions: json['numberOfSessions'] ?? 15,
      groupCount: json['groupCount'] ?? 0,
      studentCount: json['studentCount'] ?? 0,
      createdAt: json['createdAt'] ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'semesterId': semesterId,
      'code': code,
      'name': name,
      'description': description,
      'instructorName': instructorName,
      'numberOfSessions': numberOfSessions,
      'groupCount': groupCount,
      'studentCount': studentCount,
      'createdAt': createdAt,
    };
  }
}