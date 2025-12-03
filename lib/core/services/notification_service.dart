import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create notification for new announcement
  Future<void> notifyNewAnnouncement({
    required String courseId,
    required String announcementId,
    required String announcementTitle,
    required List<String> groupIds,
  }) async {
    try {
      final students = await _getStudentsInGroups(courseId, groupIds);
      
      for (var student in students) {
        await _firestore. collection('notifications').add({
          'userId': student['id'],
          'type': 'announcement',
          'title': 'New Announcement',
          'message': announcementTitle,
          'relatedId': announcementId,
          'relatedType': 'announcement',
          'isRead': false,
          'createdAt': DateTime.now().toIso8601String(),
        });
      }

      debugPrint('✅ Created ${students.length} announcement notifications');
    } catch (e) {
      debugPrint('❌ Error creating notifications: $e');
    }
  }

  // Create notification for new assignment
  Future<void> notifyNewAssignment({
    required String courseId,
    required String assignmentId,
    required String assignmentTitle,
    required DateTime deadline,
    required List<String> groupIds,
  }) async {
    try {
      final students = await _getStudentsInGroups(courseId, groupIds);
      final deadlineStr = '${deadline.day}/${deadline.month}/${deadline.year}';

      for (var student in students) {
        await _firestore. collection('notifications').add({
          'userId': student['id'],
          'type': 'assignment',
          'title': 'New Assignment',
          'message': '$assignmentTitle - Due: $deadlineStr',
          'relatedId': assignmentId,
          'relatedType': 'assignment',
          'isRead': false,
          'createdAt': DateTime.now(). toIso8601String(),
        });
      }

      debugPrint('✅ Created ${students.length} assignment notifications');
    } catch (e) {
      debugPrint('❌ Error creating notifications: $e');
    }
  }

  // Notify when assignment is graded
  Future<void> notifyGraded({
    required String studentId,
    required String assignmentTitle,
    required double grade,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': studentId,
        'type': 'grade',
        'title': 'Assignment Graded',
        'message': '$assignmentTitle - Grade: $grade',
        'relatedId': '',
        'relatedType': 'grade',
        'isRead': false,
        'createdAt': DateTime.now().toIso8601String(),
      });

      debugPrint('✅ Sent grade notification');
    } catch (e) {
      debugPrint('❌ Error sending notification: $e');
    }
  }

  // Confirm submission received
  Future<void> notifySubmissionReceived({
    required String studentId,
    required String assignmentTitle,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': studentId,
        'type': 'assignment',
        'title': 'Submission Received',
        'message': 'Your submission for "$assignmentTitle" has been received.',
        'relatedId': '',
        'relatedType': 'submission',
        'isRead': false,
        'createdAt': DateTime.now().toIso8601String(),
      });

      debugPrint('✅ Sent submission notification');
    } catch (e) {
      debugPrint('❌ Error sending notification: $e');
    }
  }

  // Get students in specific groups (or all if groupIds is empty)
  Future<List<Map<String, dynamic>>> _getStudentsInGroups(
    String courseId,
    List<String> groupIds,
  ) async {
    try {
      Query query = _firestore
          . collection('enrollments')
          .where('courseId', isEqualTo: courseId);

      if (groupIds.isNotEmpty) {
        query = query.where('groupId', whereIn: groupIds);
      }

      final enrollments = await query.get();
      final studentIds = enrollments.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .map((data) => data['studentId'] as String)
          .toSet()
          .toList();

      if (studentIds.isEmpty) return [];

      final students = <Map<String, dynamic>>[];
      for (var studentId in studentIds) {
        final studentDoc = await _firestore.collection('users').doc(studentId).get();
        if (studentDoc.exists) {
          students.add({'id': studentDoc.id, ... studentDoc.data()! });
        }
      }

      return students;
    } catch (e) {
      debugPrint('❌ Error getting students: $e');
      return [];
    }
  }
}