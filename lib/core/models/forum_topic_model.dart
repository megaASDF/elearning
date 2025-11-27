class ForumTopicModel {
  final String id;
  final String courseId;
  final String title;
  final String content;
  final String authorId;
  final String authorName;
  final List<String> attachments;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int replyCount;
  final int viewCount;

  ForumTopicModel({
    required this.id,
    required this.courseId,
    required this.title,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.attachments,
    required this.createdAt,
    required this.updatedAt,
    required this.replyCount,
    required this.viewCount,
  });

  factory ForumTopicModel.fromJson(Map<String, dynamic> json) {
    return ForumTopicModel(
      id: json['id'] ?? json['_id'] ?? '',
      courseId: json['courseId'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      authorId: json['authorId'] ?? '',
      authorName: json['authorName'] ?? '',
      attachments: List<String>.from(json['attachments'] ?? []),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      replyCount: json['replyCount'] ?? 0,
      viewCount: json['viewCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courseId': courseId,
      'title': title,
      'content': content,
      'authorId': authorId,
      'authorName': authorName,
      'attachments': attachments,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'replyCount': replyCount,
      'viewCount': viewCount,
    };
  }
}