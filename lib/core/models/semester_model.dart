class SemesterModel {
  final String id;
  final String code;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final bool isCurrent;

  SemesterModel({
    required this.id,
    required this.code,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.isCurrent = false,
  });

  factory SemesterModel.fromJson(Map<String, dynamic> json) {
    return SemesterModel(
      id: json['id'] ?? '',
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'])
          : DateTime.now(),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'])
          : DateTime.now(),
      isCurrent: json['isCurrent'] ?? false,
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
    };
  }
}