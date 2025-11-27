class ForumReplyModel {
  final String id;
  final String topicId;
  final String content;
  final String authorId;
  final String authorName;
  final List<String> attachments;
  final DateTime createdAt;
  final String? parentReplyId; // For threaded replies

  ForumReplyModel({
    required this.id,
    required this.topicId,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.attachments,
    required this.createdAt,
    this.parentReplyId,
  });

  factory ForumReplyModel.fromJson(Map<String, dynamic> json) {
    return ForumReplyModel(
      id: json['id'] ?? json['_id'] ?? '',
      topicId: json['topicId'] ?? '',
      content: json['content'] ?? '',
      authorId: json['authorId'] ?? '',
      authorName: json['authorName'] ?? '',
      attachments: List<String>.from(json['attachments'] ?? []),
      createdAt: DateTime.parse(json['createdAt']),
      parentReplyId: json['parentReplyId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'topicId': topicId,
      'content': content,
      'authorId': authorId,
      'authorName': authorName,
      'attachments': attachments,
      'createdAt': createdAt.toIso8601String(),
      'parentReplyId': parentReplyId,
    };
  }
}