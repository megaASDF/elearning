class GroupModel {
  final String id;
  final String courseId;
  final String name;
  final int studentCount;
  final DateTime createdAt;

  GroupModel({
    required this.id,
    required this.courseId,
    required this.name,
    required this.studentCount,
    required this.createdAt,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: json['id'] ?? '',
      courseId: json['courseId'] ?? '',
      name: json['name'] ?? '',
      studentCount: json['studentCount'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courseId': courseId,
      'name': name,
      'studentCount': studentCount,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}