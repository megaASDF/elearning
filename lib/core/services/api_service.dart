import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

// This Service connects to Firebase Firestore
class ApiService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  String? _token;

  ApiService() {
    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: 41943040, // 40 MB cache size limit
    );
  }

  // --- Auth ---
  void setToken(String? token) => _token = token;

  Future<Map<String, dynamic>> login(String username, String password) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Check for instructor in Firestore
    final instructorQuery = await _firestore
        .collection('users')
        .where('username', isEqualTo: username)
        .where('role', isEqualTo: 'instructor')
        .limit(1)
        .get();
    
    if (instructorQuery.docs.isNotEmpty) {
      final doc = instructorQuery.docs.first;
      return {'token': 'instructor_token_${doc.id}', 'user': {'id': doc.id, ...doc.data()}};
    }
    
    // Check for student
    final studentQuery = await _firestore
        .collection('users')
        .where('username', isEqualTo: username)
        .where('role', isEqualTo: 'student')
        .limit(1)
        .get();
    
    if (studentQuery.docs.isNotEmpty) {
      final doc = studentQuery.docs.first;
      return {'token': 'student_token_${doc.id}', 'user': {'id': doc.id, ...doc.data()}};
    }
    
    // Create new user for demo (student by default, instructor if username is 'admin')
    final isAdmin = username == 'admin' && password == 'admin';
    final newUserRef = await _firestore.collection('users').add({
      'username': username,
      'displayName': isAdmin ? 'Administrator' : username,
      'email': isAdmin ? 'admin@fit.edu' : '$username@student.fit.edu',
      'role': isAdmin ? 'instructor' : 'student',
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    final newUserDoc = await newUserRef.get();
    return {
      'token': '${isAdmin ? 'instructor' : 'student'}_token_${newUserRef.id}',
      'user': {'id': newUserRef.id, ...newUserDoc.data() ?? {}}
    };
  }

  // --- Semesters ---
  Future<List<dynamic>> getSemesters() async {
    final snapshot = await _firestore.collection('semesters').get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  Future<Map<String, dynamic>> createSemester(Map<String, dynamic> data) async {
    final docRef = await _firestore.collection('semesters').add({
      'code': data['code'],
      'name': data['name'],
      'startDate': data['startDate'],
      'endDate': data['endDate'],
      'isCurrent': data['isCurrent'] ?? false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    final doc = await docRef.get();
    return {'id': doc.id, ...doc.data() ?? {}};
  }

  Future<void> deleteSemester(String id) async {
    await _firestore.collection('semesters').doc(id).delete();
  }
  
  Future<Map<String, dynamic>> updateSemester(String id, Map<String, dynamic> data) async {
    await _firestore.collection('semesters').doc(id).update(data);
    final doc = await _firestore.collection('semesters').doc(id).get();
    return {'id': doc.id, ...doc.data() ?? {}};
  }

  // --- Courses ---
  Future<List<dynamic>> getCourses(String semesterId) async {
    final snapshot = await _firestore
        .collection('courses')
        .where('semesterId', isEqualTo: semesterId)
        .get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  Future<Map<String, dynamic>> getCourseDetails(String courseId) async {
    final doc = await _firestore.collection('courses').doc(courseId).get();
    if (doc.exists) {
      return {'id': doc.id, ...doc.data() ?? {}};
    }
    return {};
  }

  Future<Map<String, dynamic>> createCourse(Map<String, dynamic> data) async {
    final docRef = await _firestore.collection('courses').add({
      'semesterId': data['semesterId'],
      'code': data['code'],
      'name': data['name'],
      'description': data['description'] ?? '',
      'instructorName': data['instructorName'] ?? 'Administrator',
      'groupCount': 0,
      'studentCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
    final doc = await docRef.get();
    return {'id': doc.id, ...doc.data() ?? {}};
  }

  Future<void> deleteCourse(String id) async {
    await _firestore.collection('courses').doc(id).delete();
  }

  // --- Groups ---
  Future<List<dynamic>> getGroups(String courseId) async {
    final snapshot = await _firestore
        .collection('groups')
        .where('courseId', isEqualTo: courseId)
        .get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  Future<Map<String, dynamic>> createGroup(Map<String, dynamic> data) async {
    final docRef = await _firestore.collection('groups').add({
      'courseId': data['courseId'],
      'name': data['name'],
      'studentCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    // Update course group count
    final courseId = data['courseId'];
    final courseDoc = await _firestore.collection('courses').doc(courseId).get();
    if (courseDoc.exists) {
      final currentCount = courseDoc.data()?['groupCount'] ?? 0;
      await _firestore.collection('courses').doc(courseId).update({
        'groupCount': currentCount + 1,
      });
    }
    
    final doc = await docRef.get();
    return {'id': doc.id, ...doc.data() ?? {}};
  }

  // --- Students & Enrollments ---
  Future<List<dynamic>> getStudents(String courseId, {String? groupId}) async {
    Query query = _firestore
        .collection('enrollments')
        .where('courseId', isEqualTo: courseId);
    
    if (groupId != null) {
      query = query.where('groupId', isEqualTo: groupId);
    }
    
    final enrollments = await query.get();
    final studentIds = enrollments.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .map((data) => data['studentId'] as String)
        .toSet();
    
    if (studentIds.isEmpty) return [];
    
    // Fetch student details
    final students = <Map<String, dynamic>>[];
    for (final studentId in studentIds) {
      final studentDoc = await _firestore.collection('users').doc(studentId).get();
      if (studentDoc.exists) {
        students.add({'id': studentDoc.id, ...studentDoc.data() ?? {}});
      }
    }
    
    return students;
  }

  Future<List<dynamic>> getAllStudents() async {
    final snapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'student')
        .get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  // Create a user with student role
  Future<Map<String, dynamic>> createStudent(Map<String, dynamic> data) async {
    final docRef = await _firestore.collection('users').add({
      ...data,
      'role': 'student',
      'createdAt': FieldValue.serverTimestamp(),
    });
    final doc = await docRef.get();
    return {'id': doc.id, ...doc.data() ?? {}};
  }

  Future<void> enrollStudent(String studentId, String courseId, String groupId) async {
    await _firestore.collection('enrollments').add({
      'studentId': studentId,
      'courseId': courseId,
      'groupId': groupId,
      'enrolledAt': FieldValue.serverTimestamp(),
    });
    
    // Update group student count
    final groupDoc = await _firestore.collection('groups').doc(groupId).get();
    if (groupDoc.exists) {
      final currentCount = groupDoc.data()?['studentCount'] ?? 0;
      await _firestore.collection('groups').doc(groupId).update({
        'studentCount': currentCount + 1,
      });
    }
    
    // Update course student count
    final courseDoc = await _firestore.collection('courses').doc(courseId).get();
    if (courseDoc.exists) {
      final currentCount = courseDoc.data()?['studentCount'] ?? 0;
      await _firestore.collection('courses').doc(courseId).update({
        'studentCount': currentCount + 1,
      });
    }
  }

  Future<void> deleteStudent(String id) async {
    await _firestore.collection('users').doc(id).delete();
    // Also delete enrollments for this student
    final enrollments = await _firestore
        .collection('enrollments')
        .where('studentId', isEqualTo: id)
        .get();
    for (final doc in enrollments.docs) {
      await doc.reference.delete();
    }
  }

  // --- Assignments ---
  Future<List<dynamic>> getAssignments(String courseId) async {
    final snapshot = await _firestore
        .collection('assignments')
        .where('courseId', isEqualTo: courseId)
        .get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  Future<Map<String, dynamic>> getAssignmentById(String id) async {
    final doc = await _firestore.collection('assignments').doc(id).get();
    if (doc.exists) {
      return {'id': doc.id, ...doc.data() ?? {}};
    }
    return {};
  }

  Future<Map<String, dynamic>> createAssignment(Map<String, dynamic> data) async {
    final docRef = await _firestore.collection('assignments').add({
      'courseId': data['courseId'],
      'groupIds': data['groupIds'] ?? [],
      'title': data['title'],
      'description': data['description'] ?? '',
      'attachments': data['attachments'] ?? [],
      'startDate': data['startDate'],
      'deadline': data['deadline'],
      'lateDeadline': data['lateDeadline'],
      'allowLateSubmission': data['allowLateSubmission'] ?? false,
      'maxAttempts': data['maxAttempts'] ?? 1,
      'allowedFileFormats': data['allowedFileFormats'] ?? ['pdf'],
      'maxFileSizeMB': data['maxFileSizeMB'] ?? 10,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    final doc = await docRef.get();
    return {'id': doc.id, ...doc.data() ?? {}};
  }

  Future<Map<String, dynamic>> updateAssignment(String id, Map<String, dynamic> data) async {
    await _firestore.collection('assignments').doc(id).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    final doc = await _firestore.collection('assignments').doc(id).get();
    return {'id': doc.id, ...doc.data() ?? {}};
  }

  Future<void> deleteAssignment(String id) async {
    await _firestore.collection('assignments').doc(id).delete();
  }

  // --- Submissions ---
  Future<List<dynamic>> getSubmissions(String assignmentId) async {
    final snapshot = await _firestore
        .collection('submissions')
        .where('assignmentId', isEqualTo: assignmentId)
        .get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  Future<List<dynamic>> getMySubmissions(String assignmentId, String studentId) async {
    final snapshot = await _firestore
        .collection('submissions')
        .where('assignmentId', isEqualTo: assignmentId)
        .where('studentId', isEqualTo: studentId)
        .get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  Future<Map<String, dynamic>> submitAssignment(String assignmentId, Map<String, dynamic> data) async {
    // Check for existing submission to increment attempt
    final existing = await _firestore
        .collection('submissions')
        .where('assignmentId', isEqualTo: assignmentId)
        .where('studentId', isEqualTo: data['studentId'])
        .get();
    final attemptNumber = existing.docs.length + 1;

    final docRef = await _firestore.collection('submissions').add({
      'assignmentId': assignmentId,
      'studentId': data['studentId'],
      'studentName': data['studentName'],
      'fileUrls': data['fileUrls'] ?? [],
      'attemptNumber': attemptNumber,
      'submittedAt': FieldValue.serverTimestamp(),
      'grade': null,
      'feedback': null,
      'status': 'submitted',
    });
    final doc = await docRef.get();
    return {'id': doc.id, ...doc.data() ?? {}};
  }

  Future<Map<String, dynamic>> gradeSubmission(String submissionId, double grade, String? feedback) async {
    await _firestore.collection('submissions').doc(submissionId).update({
      'grade': grade,
      'feedback': feedback,
      'gradedAt': FieldValue.serverTimestamp(),
      'status': 'graded',
    });
    final doc = await _firestore.collection('submissions').doc(submissionId).get();
    return {'id': doc.id, ...doc.data() ?? {}};
  }

  // --- Quizzes ---
  Future<List<dynamic>> getQuizzes(String courseId) async {
    final snapshot = await _firestore
        .collection('quizzes')
        .where('courseId', isEqualTo: courseId)
        .get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  Future<Map<String, dynamic>> createQuiz(Map<String, dynamic> data) async {
    final docRef = await _firestore.collection('quizzes').add({
      'courseId': data['courseId'],
      'title': data['title'],
      'description': data['description'] ?? '',
      'openTime': data['openTime'],
      'closeTime': data['closeTime'],
      'durationMinutes': data['durationMinutes'] ?? 60,
      'maxAttempts': data['maxAttempts'] ?? 1,
      'easyQuestions': data['easyQuestions'] ?? 0,
      'mediumQuestions': data['mediumQuestions'] ?? 0,
      'hardQuestions': data['hardQuestions'] ?? 0,
      'groupIds': data['groupIds'] ?? [],
      'questionIds': data['questionIds'] ?? [],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    final doc = await docRef.get();
    return {'id': doc.id, ...doc.data() ?? {}};
  }

  Future<void> updateQuiz(String id, Map<String, dynamic> data) async {
    await _firestore.collection('quizzes').doc(id).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteQuiz(String id) async {
    await _firestore.collection('quizzes').doc(id).delete();
  }

  // --- Quiz Attempts ---
  Future<List<dynamic>> getQuizAttempts(String quizId) async {
    final snapshot = await _firestore
        .collection('quizAttempts')
        .where('quizId', isEqualTo: quizId)
        .get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  Future<Map<String, dynamic>> startQuizAttempt(String quizId, String studentId, String studentName) async {
    final docRef = await _firestore.collection('quizAttempts').add({
      'quizId': quizId,
      'studentId': studentId,
      'studentName': studentName,
      'startedAt': FieldValue.serverTimestamp(),
      'attemptNumber': 1,
      'answers': {},
      'score': 0.0,
    });
    final doc = await docRef.get();
    return {'id': doc.id, ...doc.data() ?? {}};
  }

  Future<Map<String, dynamic>> submitQuizAttempt(String attemptId, Map<String, int> answers) async {
    // Simple Mock Scoring: 10 points per answer
    final score = (answers.length * 10.0);
    await _firestore.collection('quizAttempts').doc(attemptId).update({
      'answers': answers,
      'submittedAt': FieldValue.serverTimestamp(),
      'score': score,
    });
    final doc = await _firestore.collection('quizAttempts').doc(attemptId).get();
    return {'id': doc.id, ...doc.data() ?? {}};
  }

  // --- Materials ---
  Future<List<dynamic>> getMaterials(String courseId) async {
    final snapshot = await _firestore
        .collection('materials')
        .where('courseId', isEqualTo: courseId)
        .get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  Future<Map<String, dynamic>> createMaterial(Map<String, dynamic> data) async {
    final docRef = await _firestore.collection('materials').add({
      'courseId': data['courseId'],
      'title': data['title'],
      'description': data['description'] ?? '',
      'type': data['type'] ?? 'document',
      'fileUrl': data['fileUrl'] ?? '',
      'groupIds': data['groupIds'] ?? [],
      'createdAt': FieldValue.serverTimestamp(),
      'viewCount': 0,
      'downloadCount': 0,
    });
    final doc = await docRef.get();
    return {'id': doc.id, ...doc.data() ?? {}};
  }

  Future<void> updateMaterial(String id, Map<String, dynamic> data) async {
    await _firestore.collection('materials').doc(id).update(data);
  }

  // --- Announcements ---
  Future<List<dynamic>> getAnnouncements(String courseId) async {
    final snapshot = await _firestore
        .collection('announcements')
        .where('courseId', isEqualTo: courseId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  Future<Map<String, dynamic>> createAnnouncement(Map<String, dynamic> data) async {
    final docRef = await _firestore.collection('announcements').add({
      'courseId': data['courseId'],
      'title': data['title'],
      'content': data['content'],
      'attachmentUrls': data['attachmentUrls'] ?? [],
      'groupIds': data['groupIds'] ?? [],
      'authorName': data['authorName'] ?? 'Administrator',
      'createdAt': FieldValue.serverTimestamp(),
      'viewCount': 0,
      'commentCount': 0,
    });
    final doc = await docRef.get();
    return {'id': doc.id, ...doc.data() ?? {}};
  }

  // --- Forum ---
  Future<List<dynamic>> getForumTopics(String courseId) async {
    final snapshot = await _firestore
        .collection('forumTopics')
        .where('courseId', isEqualTo: courseId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  Future<Map<String, dynamic>> createForumTopic(Map<String, dynamic> data) async {
    final docRef = await _firestore.collection('forumTopics').add({
      'courseId': data['courseId'],
      'title': data['title'],
      'content': data['content'],
      'authorId': data['authorId'],
      'authorName': data['authorName'],
      'groupIds': data['groupIds'] ?? [],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'replyCount': 0,
      'viewCount': 0,
    });
    final doc = await docRef.get();
    return {'id': doc.id, ...doc.data() ?? {}};
  }

  Future<List<dynamic>> getForumReplies(String topicId) async {
    final snapshot = await _firestore
        .collection('forumReplies')
        .where('topicId', isEqualTo: topicId)
        .orderBy('createdAt')
        .get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  Future<Map<String, dynamic>> createForumReply(String topicId, Map<String, dynamic> data) async {
    final docRef = await _firestore.collection('forumReplies').add({
      'topicId': topicId,
      'content': data['content'],
      'authorId': data['authorId'],
      'authorName': data['authorName'],
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    // Update topic reply count
    final topicDoc = await _firestore.collection('forumTopics').doc(topicId).get();
    if (topicDoc.exists) {
      final currentCount = topicDoc.data()?['replyCount'] ?? 0;
      await _firestore.collection('forumTopics').doc(topicId).update({
        'replyCount': currentCount + 1,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    
    final doc = await docRef.get();
    return {'id': doc.id, ...doc.data() ?? {}};
  }

  // --- Notifications ---
  Future<List<dynamic>> getNotifications(String userId) async {
    final snapshot = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  Future<void> markNotificationAsRead(String id) async {
    await _firestore.collection('notifications').doc(id).update({
      'isRead': true,
    });
  }
  
  Future<void> markAllNotificationsAsRead(String userId) async {
    final snapshot = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();
    
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Future<void> deleteNotification(String id) async {
    await _firestore.collection('notifications').doc(id).delete();
  }

  // --- Messaging ---
  Future<List<dynamic>> getConversations(String userId) async {
    final snapshot = await _firestore
        .collection('conversations')
        .where('participantIds', arrayContains: userId)
        .get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  Future<List<dynamic>> getMessages(String userId, String otherUserId) async {
    // Get messages where user is sender or receiver
    final snapshot = await _firestore
        .collection('messages')
        .where('participantIds', arrayContainsAny: [userId])
        .orderBy('createdAt')
        .get();
    
    // Filter to only include messages between these two users
    return snapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data()})
        .where((msg) => 
            (msg['senderId'] == userId && msg['receiverId'] == otherUserId) ||
            (msg['senderId'] == otherUserId && msg['receiverId'] == userId))
        .toList();
  }

  Future<Map<String, dynamic>> sendMessage(Map<String, dynamic> data) async {
    final docRef = await _firestore.collection('messages').add({
      'senderId': data['senderId'],
      'receiverId': data['receiverId'],
      'content': data['content'],
      'participantIds': [data['senderId'], data['receiverId']],
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    final doc = await docRef.get();
    return {'id': doc.id, ...doc.data() ?? {}};
  }

  // --- User Profile ---
  Future<Map<String, dynamic>> getUserProfile(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (doc.exists) {
      return {'id': doc.id, ...doc.data() ?? {}};
    }
    // Return default user if not found
    return {
      'id': userId,
      'username': 'unknown',
      'displayName': 'Unknown',
      'email': '',
      'role': 'student',
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  Future<Map<String, dynamic>> updateUserProfile(String userId, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(userId).update(data);
    final doc = await _firestore.collection('users').doc(userId).get();
    return {'id': doc.id, ...doc.data() ?? {}};
  }

  Future<String> uploadAvatar(String userId, String path) async {
    // Upload to Firebase Storage
    final ref = _storage.ref().child('avatars/$userId/${DateTime.now().millisecondsSinceEpoch}');
    final file = File(path);
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<void> changePassword(String userId, String oldPassword, String newPass) async {
    // Firebase Auth password change would go here
    // For now, this is a no-op since we use demo login
  }

  Future uploadStudentCsv(File file) async {
    // Upload CSV to Firebase Storage
    final ref = _storage.ref().child('csv/${DateTime.now().millisecondsSinceEpoch}_students.csv');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }
}