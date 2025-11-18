class UserModel {
  final String id;
  final String username;
  final String displayName;
  final String email;
  final String role; // 'instructor' or 'student'
  final String? avatarUrl;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.username,
    required this.displayName,
    required this.email,
    required this.role,
    this.avatarUrl,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      displayName: json['displayName'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'student',
      avatarUrl: json['avatarUrl'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'displayName': displayName,
      'email': email,
      'role': role,
      'avatarUrl': avatarUrl,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  bool get isInstructor => role == 'instructor';
  bool get isStudent => role == 'student';
}