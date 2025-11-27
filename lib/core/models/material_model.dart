class MaterialModel {
  final String id;
  final String courseId;
  final String title;
  final String description;
  final List<String> fileUrls;
  final List<String> links;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String authorName;
  final int viewCount;
  final int downloadCount;

  MaterialModel({
    required this.id,
    required this.courseId,
    required this.title,
    required this.description,
    required this.fileUrls,
    required this.links,
    required this.createdAt,
    required this.updatedAt,
    required this.authorName,
    required this.viewCount,
    required this.downloadCount,
  });

  factory MaterialModel.fromJson(Map<String, dynamic> json) {
    return MaterialModel(
      id: json['id'] ?? json['_id'] ?? '',
      courseId: json['courseId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      fileUrls: List<String>.from(json['fileUrls'] ?? []),
      links: List<String>.from(json['links'] ?? []),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      authorName: json['authorName'] ?? '',
      viewCount: json['viewCount'] ?? 0,
      downloadCount: json['downloadCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courseId': courseId,
      'title': title,
      'description': description,
      'fileUrls': fileUrls,
      'links': links,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'authorName': authorName,
      'viewCount': viewCount,
      'downloadCount': downloadCount,
    };
  }
}