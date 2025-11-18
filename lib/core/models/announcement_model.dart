class AnnouncementModel {
  final String id;
  final String courseId;
  final String title;
  final String content;
  final List<String> attachmentUrls;
  final List<String> groupIds; // Scope: which groups can see this
  final DateTime createdAt;
  final String authorName;
  final int commentCount;
  final int viewCount;

  AnnouncementModel({
    required this.id,
    required this.courseId,
    required this.title,
    required this.content,
    this.attachmentUrls = const [],
    this.groupIds = const [],
    required this.createdAt,
    required this.authorName,
    this.commentCount = 0,
    this.viewCount = 0,
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      id: json['id'] ?? '',
      courseId: json['courseId'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      attachmentUrls: json['attachmentUrls'] != null
          ? List<String>.from(json['attachmentUrls'])
          : [],
      groupIds: json['groupIds'] != null
          ? List<String>.from(json['groupIds'])
          : [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      authorName: json['authorName'] ?? '',
      commentCount: json['commentCount'] ?? 0,
      viewCount: json['viewCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courseId': courseId,
      'title': title,
      'content': content,
      'attachmentUrls': attachmentUrls,
      'groupIds': groupIds,
      'createdAt': createdAt.toIso8601String(),
      'authorName': authorName,
      'commentCount': commentCount,
      'viewCount': viewCount,
    };
  }

  String get timeAgo {
    final difference = DateTime.now().difference(createdAt);
    if (difference.inDays > 7) {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}