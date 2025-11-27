class UserProfileModel {
  final String id;
  final String username;
  final String displayName;
  final String email;
  final String role;
  final String?  avatarUrl;
  final String? phoneNumber;
  final String? bio;
  final String? department;
  final String? studentId;
  final DateTime createdAt;
  final DateTime?  updatedAt;

  UserProfileModel({
    required this.id,
    required this.username,
    required this. displayName,
    required this. email,
    required this.role,
    this.avatarUrl,
    this.phoneNumber,
    this.bio,
    this.department,
    this. studentId,
    required this. createdAt,
    this. updatedAt,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'] ??  json['_id'] ?? '',
      username: json['username'] ?? '',
      displayName: json['displayName'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'student',
      avatarUrl: json['avatarUrl'],
      phoneNumber: json['phoneNumber'],
      bio: json['bio'],
      department: json['department'],
      studentId: json['studentId'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null ?  DateTime.parse(json['updatedAt']) : null,
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
      'phoneNumber': phoneNumber,
      'bio': bio,
      'department': department,
      'studentId': studentId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?. toIso8601String(),
    };
  }

  UserProfileModel copyWith({
    String? displayName,
    String? email,
    String? avatarUrl,
    String? phoneNumber,
    String? bio,
    String? department,
  }) {
    return UserProfileModel(
      id: id,
      username: username,
      displayName: displayName ?? this.displayName,
      email: email ??  this.email,
      role: role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      bio: bio ?? this.bio,
      department: department ?? this.department,
      studentId: studentId,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  bool get isInstructor => role == 'instructor';
  bool get isStudent => role == 'student';
}