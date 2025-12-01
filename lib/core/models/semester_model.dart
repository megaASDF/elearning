class SemesterModel {
  final String id;
  final String code;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final bool isCurrent;
  final String createdAt;

  SemesterModel({
    required this. id,
    required this.code,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.isCurrent,
    String? createdAt, // Make it optional with default
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  factory SemesterModel.fromJson(Map<String, dynamic> json) {
    return SemesterModel(
      id: json['id'] ?? '',
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      startDate: json['startDate'] is String 
          ? DateTime.parse(json['startDate'])
          : json['startDate'] as DateTime,
      endDate: json['endDate'] is String 
          ? DateTime.parse(json['endDate'])
          : json['endDate'] as DateTime,
      isCurrent: json['isCurrent'] ?? false,
      createdAt: json['createdAt'] ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isCurrent': isCurrent,
      'createdAt': createdAt,
    };
  }
}