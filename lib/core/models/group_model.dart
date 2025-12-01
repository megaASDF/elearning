class GroupModel {
  final String id;
  final String courseId;
  final String name;
  final String?  description;
  final int?  maxStudents;
  final int studentCount;
  final String createdAt;

  GroupModel({
    required this.id,
    required this. courseId,
    required this. name,
    this.description,
    this.maxStudents,
    this.studentCount = 0,
    required this.createdAt,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: json['id'] ?? '',
      courseId: json['courseId'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      maxStudents: json['maxStudents'],
      studentCount: json['studentCount'] ?? 0,
      createdAt: json['createdAt'] ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courseId': courseId,
      'name': name,
      'description': description,
      'maxStudents': maxStudents,
      'studentCount': studentCount,
      'createdAt': createdAt,
    };
  }
}