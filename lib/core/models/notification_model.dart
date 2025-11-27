import 'package:flutter/material.dart';
class NotificationModel {
  final String id;
  final String userId;
  final String type; // 'announcement', 'assignment', 'quiz', 'grade', 'message', 'deadline'
  final String title;
  final String message;
  final String? relatedId; // ID of related assignment/quiz/etc
  final String? relatedType; // 'assignment', 'quiz', 'announcement', etc
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.relatedId,
    this.relatedType,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? json['_id'] ?? '',
      userId: json['userId'] ?? '',
      type: json['type'] ?? 'message',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      relatedId: json['relatedId'],
      relatedType: json['relatedType'],
      isRead: json['isRead'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'title': title,
      'message': message,
      'relatedId': relatedId,
      'relatedType': relatedType,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  IconData get icon {
    switch (type) {
      case 'announcement':
        return Icons.campaign;
      case 'assignment':
        return Icons.assignment;
      case 'quiz':
        return Icons.quiz;
      case 'grade':
        return Icons.grade;
      case 'message':
        return Icons.message;
      case 'deadline':
        return Icons.alarm;
      default:
        return Icons.notifications;
    }
  }

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}