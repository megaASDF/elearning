import 'package:cloud_firestore/cloud_firestore.dart';

class ForumTopicModel {
  final String id;
  final String courseId;
  final String title;
  final String content;
  final String authorId;
  final String authorName;
  final List<String> groupIds;
  final String createdAt;
  final String updatedAt;
  final int replyCount;
  final int viewCount;

  ForumTopicModel({
    required this.id,
    required this.courseId,
    required this.title,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.groupIds,
    required this.createdAt,
    required this.updatedAt,
    required this.replyCount,
    required this.viewCount,
  });

  factory ForumTopicModel.fromJson(Map<String, dynamic> json) {
    return ForumTopicModel(
      id: json['id'] ??  '',
      courseId: json['courseId'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ??  '',
      authorId: json['authorId'] ?? '',
      authorName: json['authorName'] ??  '',
      groupIds: (json['groupIds'] as List?)?.cast<String>() ?? [],
      createdAt: _convertToIsoString(json['createdAt']),
      updatedAt: _convertToIsoString(json['updatedAt']),
      replyCount: json['replyCount'] ?? 0,
      viewCount: json['viewCount'] ??  0,
    );
  }

  // Helper method to convert Timestamp to ISO String
  static String _convertToIsoString(dynamic value) {
    if (value == null) {
      return DateTime.now().toIso8601String();
    } else if (value is Timestamp) {
      return value.toDate().toIso8601String();
    } else if (value is String) {
      return value;
    } else {
      return DateTime.now().toIso8601String();
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courseId': courseId,
      'title': title,
      'content': content,
      'authorId': authorId,
      'authorName': authorName,
      'groupIds': groupIds,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'replyCount': replyCount,
      'viewCount': viewCount,
    };
  }
}