class CourseModel {
  final String id;
  final String semesterId;
  final String code;
  final String name;
  final String? description;
  final String? coverImageUrl;
  final String instructorName;
  final int numberOfSessions;
  final DateTime createdAt;
  
  // Cached data
  int? groupCount;
  int? studentCount;

  CourseModel({
    required this.id,
    required this.semesterId,
    required this.code,
    required this.name,
    this.description,
    this.coverImageUrl,
    required this.instructorName,
    required this.numberOfSessions,
    required this.createdAt,
    this.groupCount,
    this.studentCount,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    return CourseModel(
      id: json['id'] ?? '',
      semesterId: json['semesterId'] ?? '',
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      coverImageUrl: json['coverImageUrl'],
      instructorName: json['instructorName'] ?? 'Instructor',
      numberOfSessions: json['numberOfSessions'] ?? 15,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      groupCount: json['groupCount'],
      studentCount: json['studentCount'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'semesterId': semesterId,
      'code': code,
      'name': name,
      'description': description,
      'coverImageUrl': coverImageUrl,
      'instructorName': instructorName,
      'numberOfSessions': numberOfSessions,
      'createdAt': createdAt.toIso8601String(),
      'groupCount': groupCount,
      'studentCount': studentCount,
    };
  }
}