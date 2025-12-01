import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

// This Service acts as a Mock Backend for the application
class ApiService {
  static const String baseUrl = 'http://localhost:3000/api'; // Change to your backend URL
  // For Android emulator use: http://10.0.2.2:3000/api
  // For real device use your computer's IP: http://192.168.1.x:3000/api
  
  String?  _token;
  
  // --- In-Memory Database (Mock) - Static to persist across instances ---
  static final List<Map<String, dynamic>> _users = [];
  static final List<Map<String, dynamic>> _semesters = [];
  static final List<Map<String, dynamic>> _courses = [];
  static final List<Map<String, dynamic>> _groups = [];
  static final List<Map<String, dynamic>> _enrollments = []; // Links students to groups
  static final List<Map<String, dynamic>> _assignments = [];
  static final List<Map<String, dynamic>> _submissions = [];
  static final List<Map<String, dynamic>> _quizzes = [];
  static final List<Map<String, dynamic>> _quizAttempts = [];
  static final List<Map<String, dynamic>> _materials = [];
  static final List<Map<String, dynamic>> _announcements = [];
  static final List<Map<String, dynamic>> _forumTopics = [];
  static final List<Map<String, dynamic>> _forumReplies = [];
  static final List<Map<String, dynamic>> _notifications = [];
  static final List<Map<String, dynamic>> _conversations = [];
  static final List<Map<String, dynamic>> _messages = [];
  static bool _isInitialized = false;

  ApiService() {
    _initializeMockData();
  }

  void _initializeMockData() {
    if (_isInitialized) return;
    _isInitialized = true;
    
    // Admin
    _users.add({
      'id': '1',
      'username': 'admin',
      'displayName': 'Administrator',
      'email': 'admin@fit.edu',
      'role': 'instructor',
      'createdAt': DateTime.now().toIso8601String(),
    });

    // Default Semester
    _semesters.add({
      'id': '1',
      'code': 'HK1-2024',
      'name': 'Semester 1, 2024-2025',
      'startDate': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
      'endDate': DateTime.now().add(const Duration(days: 90)).toIso8601String(),
      'isCurrent': true,
    });
  }

  // --- Auth ---
  void setToken(String? token) => _token = token;

  Future<Map<String, dynamic>> login(String username, String password) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Instructor Login
    if (username == 'admin' && password == 'admin') {
      return {'token': 'admin_token', 'user': _users.first};
    }

    // Student Login (Auto-create if not exists for demo)
    var student = _users.firstWhere(
      (u) => u['username'] == username && u['role'] == 'student',
      orElse: () => {},
    );

    if (student.isEmpty) {
      // For demo: create student account on fly if simple login
      student = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'username': username,
        'displayName': username,
        'email': '$username@student.fit.edu',
        'role': 'student',
        'createdAt': DateTime.now().toIso8601String(),
      };
      _users.add(student);
    }

    return {'token': 'student_token_${student['id']}', 'user': student};
  }

  // --- Semesters ---
  Future<List<dynamic>> getSemesters() async {
    return List.from(_semesters);
  }

  Future<Map<String, dynamic>> createSemester(Map<String, dynamic> data) async {
    final newSemester = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      ...data,
      'isCurrent': _semesters.isEmpty, // First one is current
    };
    _semesters.add(newSemester);
    return newSemester;
  }

  Future<void> deleteSemester(String id) async {
    _semesters.removeWhere((s) => s['id'] == id);
  }
  
  Future<Map<String, dynamic>> updateSemester(String id, Map<String, dynamic> data) async {
    final index = _semesters.indexWhere((s) => s['id'] == id);
    if (index != -1) {
      _semesters[index] = {..._semesters[index], ...data};
      return _semesters[index];
    }
    throw Exception('Semester not found');
  }

  // --- Courses ---
  Future<List<dynamic>> getCourses(String semesterId) async {
    return _courses.where((c) => c['semesterId'] == semesterId).toList();
  }

  Future<Map<String, dynamic>> getCourseDetails(String courseId) async {
    return _courses.firstWhere((c) => c['id'] == courseId, orElse: () => {});
  }

  Future<Map<String, dynamic>> createCourse(Map<String, dynamic> data) async {
    final newCourse = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      ...data,
      'instructorName': 'Administrator',
      'createdAt': DateTime.now().toIso8601String(),
      'groupCount': 0,
      'studentCount': 0,
    };
    _courses.add(newCourse);
    return newCourse;
  }

  Future<void> deleteCourse(String id) async {
    _courses.removeWhere((c) => c['id'] == id);
  }

  // --- Groups ---
  Future<List<dynamic>> getGroups(String courseId) async {
    return _groups.where((g) => g['courseId'] == courseId).toList();
  }

  Future<Map<String, dynamic>> createGroup(Map<String, dynamic> data) async {
    final group = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      ...data,
      'studentCount': 0,
      'createdAt': DateTime.now().toIso8601String(),
    };
    _groups.add(group);
    
    // Update course group count
    final courseIndex = _courses.indexWhere((c) => c['id'] == data['courseId']);
    if (courseIndex != -1) {
      _courses[courseIndex]['groupCount'] = (_courses[courseIndex]['groupCount'] ?? 0) + 1;
    }
    
    return group;
  }

  // --- Students & Enrollments ---
  Future<List<dynamic>> getStudents(String courseId, {String? groupId}) async {
    // Return students enrolled in this course/group
    final enrolledStudentIds = _enrollments
        .where((e) => e['courseId'] == courseId && (groupId == null || e['groupId'] == groupId))
        .map((e) => e['studentId'])
        .toSet();
    
    return _users.where((u) => enrolledStudentIds.contains(u['id'])).toList();
  }

  Future<List<dynamic>> getAllStudents() async {
    return _users.where((u) => u['role'] == 'student').toList();
  }

  // Mock: Just create a user with student role
  Future<Map<String, dynamic>> createStudent(Map<String, dynamic> data) async {
    final student = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      ...data,
      'role': 'student',
      'createdAt': DateTime.now().toIso8601String(),
    };
    _users.add(student);
    return student;
  }

  Future<void> enrollStudent(String studentId, String courseId, String groupId) async {
    _enrollments.add({
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'studentId': studentId,
      'courseId': courseId,
      'groupId': groupId,
      'enrolledAt': DateTime.now().toIso8601String(),
    });
    
    // Update counts
    final groupIndex = _groups.indexWhere((g) => g['id'] == groupId);
    if (groupIndex != -1) {
      _groups[groupIndex]['studentCount'] = (_groups[groupIndex]['studentCount'] ?? 0) + 1;
    }
    
    final courseIndex = _courses.indexWhere((c) => c['id'] == courseId);
    if (courseIndex != -1) {
      _courses[courseIndex]['studentCount'] = (_courses[courseIndex]['studentCount'] ?? 0) + 1;
    }
  }

  Future<void> deleteStudent(String id) async {
    _users.removeWhere((u) => u['id'] == id);
    _enrollments.removeWhere((e) => e['studentId'] == id);
  }

  // --- Assignments ---
  Future<List<dynamic>> getAssignments(String courseId) async {
    return _assignments.where((a) => a['courseId'] == courseId).toList();
  }

  Future<Map<String, dynamic>> getAssignmentById(String id) async {
    return _assignments.firstWhere((a) => a['id'] == id, orElse: () => {});
  }

  Future<Map<String, dynamic>> createAssignment(Map<String, dynamic> data) async {
    final assignment = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      ...data,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
    _assignments.add(assignment);
    return assignment;
  }

  Future<Map<String, dynamic>> updateAssignment(String id, Map<String, dynamic> data) async {
    final index = _assignments.indexWhere((a) => a['id'] == id);
    if (index != -1) {
      _assignments[index] = {..._assignments[index], ...data};
      return _assignments[index];
    }
    return {};
  }

  Future<void> deleteAssignment(String id) async {
    _assignments.removeWhere((a) => a['id'] == id);
  }

  // --- Submissions ---
  Future<List<dynamic>> getSubmissions(String assignmentId) async {
    return _submissions.where((s) => s['assignmentId'] == assignmentId).toList();
  }

  Future<List<dynamic>> getMySubmissions(String assignmentId, String studentId) async {
    return _submissions.where((s) => s['assignmentId'] == assignmentId && s['studentId'] == studentId).toList();
  }

  Future<Map<String, dynamic>> submitAssignment(String assignmentId, Map<String, dynamic> data) async {
    // Check for existing submission to increment attempt
    final existing = _submissions.where((s) => s['assignmentId'] == assignmentId && s['studentId'] == data['studentId']);
    final attemptNumber = existing.length + 1;

    final submission = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'assignmentId': assignmentId,
      ...data,
      'attemptNumber': attemptNumber,
      'submittedAt': DateTime.now().toIso8601String(),
      'grade': null,
      'feedback': null,
    };
    _submissions.add(submission);
    return submission;
  }

  Future<Map<String, dynamic>> gradeSubmission(String submissionId, double grade, String? feedback) async {
    final index = _submissions.indexWhere((s) => s['id'] == submissionId);
    if (index != -1) {
      _submissions[index]['grade'] = grade;
      _submissions[index]['feedback'] = feedback;
      _submissions[index]['gradedAt'] = DateTime.now().toIso8601String();
      return _submissions[index];
    }
    throw Exception('Submission not found');
  }

  // --- Quizzes ---
  Future<List<dynamic>> getQuizzes(String courseId) async {
    return _quizzes.where((q) => q['courseId'] == courseId).toList();
  }

  Future<Map<String, dynamic>> createQuiz(Map<String, dynamic> data) async {
    final quiz = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      ...data,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
    _quizzes.add(quiz);
    return quiz;
  }

  Future<void> updateQuiz(String id, Map<String, dynamic> data) async {
    final index = _quizzes.indexWhere((q) => q['id'] == id);
    if (index != -1) _quizzes[index] = {..._quizzes[index], ...data};
  }

  Future<void> deleteQuiz(String id) async {
    _quizzes.removeWhere((q) => q['id'] == id);
  }

  // --- Quiz Attempts ---
  Future<List<dynamic>> getQuizAttempts(String quizId) async {
    return _quizAttempts.where((qa) => qa['quizId'] == quizId).toList();
  }

  Future<Map<String, dynamic>> startQuizAttempt(String quizId, String studentId, String studentName) async {
    final attempt = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'quizId': quizId,
      'studentId': studentId,
      'studentName': studentName,
      'startedAt': DateTime.now().toIso8601String(),
      'attemptNumber': 1,
      'answers': {},
      'score': 0.0,
    };
    _quizAttempts.add(attempt);
    return attempt;
  }

  Future<Map<String, dynamic>> submitQuizAttempt(String attemptId, Map<String, int> answers) async {
    final index = _quizAttempts.indexWhere((qa) => qa['id'] == attemptId);
    if (index != -1) {
      // Simple Mock Scoring: 10 points per answer
      final score = (answers.length * 10.0); 
      _quizAttempts[index]['answers'] = answers;
      _quizAttempts[index]['submittedAt'] = DateTime.now().toIso8601String();
      _quizAttempts[index]['score'] = score;
      return _quizAttempts[index];
    }
    throw Exception('Attempt not found');
  }

  // --- Materials ---
  Future<List<dynamic>> getMaterials(String courseId) async {
    return _materials.where((m) => m['courseId'] == courseId).toList();
  }

  Future<Map<String, dynamic>> createMaterial(Map<String, dynamic> data) async {
    final material = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      ...data,
      'createdAt': DateTime.now().toIso8601String(),
      'viewCount': 0,
      'downloadCount': 0,
    };
    _materials.add(material);
    return material;
  }

  Future<void> updateMaterial(String id, Map<String, dynamic> data) async {
    final index = _materials.indexWhere((m) => m['id'] == id);
    if (index != -1) _materials[index] = {..._materials[index], ...data};
  }

  // --- Announcements ---
  Future<List<dynamic>> getAnnouncements(String courseId) async {
    return _announcements.where((a) => a['courseId'] == courseId).toList();
  }

  Future<Map<String, dynamic>> createAnnouncement(Map<String, dynamic> data) async {
    final ann = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      ...data,
      'createdAt': DateTime.now().toIso8601String(),
      'viewCount': 0,
      'commentCount': 0,
    };
    _announcements.add(ann);
    return ann;
  }

  // --- Forum ---
  Future<List<dynamic>> getForumTopics(String courseId) async {
    return _forumTopics.where((t) => t['courseId'] == courseId).toList();
  }

  Future<Map<String, dynamic>> createForumTopic(Map<String, dynamic> data) async {
    final topic = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      ...data,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
      'replyCount': 0,
      'viewCount': 0,
    };
    _forumTopics.add(topic);
    return topic;
  }

  Future<List<dynamic>> getForumReplies(String topicId) async {
    return _forumReplies.where((r) => r['topicId'] == topicId).toList();
  }

  Future<Map<String, dynamic>> createForumReply(String topicId, Map<String, dynamic> data) async {
    final reply = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'topicId': topicId,
      ...data,
      'createdAt': DateTime.now().toIso8601String(),
    };
    _forumReplies.add(reply);
    
    // Update topic reply count
    final topicIndex = _forumTopics.indexWhere((t) => t['id'] == topicId);
    if (topicIndex != -1) {
      _forumTopics[topicIndex]['replyCount'] = (_forumTopics[topicIndex]['replyCount'] ?? 0) + 1;
    }
    
    return reply;
  }

  // --- Notifications ---
  Future<List<dynamic>> getNotifications(String userId) async {
    return _notifications.where((n) => n['userId'] == userId).toList();
  }

  Future<void> markNotificationAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n['id'] == id);
    if (index != -1) _notifications[index]['isRead'] = true;
  }
  
  Future<void> markAllNotificationsAsRead(String userId) async {
    for (var n in _notifications.where((n) => n['userId'] == userId)) {
      n['isRead'] = true;
    }
  }

  Future<void> deleteNotification(String id) async {
    _notifications.removeWhere((n) => n['id'] == id);
  }

  // --- Messaging ---
  Future<List<dynamic>> getConversations(String userId) async {
    // In a real app this groups messages. Mocking simple list.
    return _conversations; 
  }

  Future<List<dynamic>> getMessages(String userId, String otherUserId) async {
    return _messages.where((m) => 
      (m['senderId'] == userId && m['receiverId'] == otherUserId) || 
      (m['senderId'] == otherUserId && m['receiverId'] == userId)
    ).toList();
  }

  Future<Map<String, dynamic>> sendMessage(Map<String, dynamic> data) async {
    final msg = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      ...data,
      'isRead': false,
      'createdAt': DateTime.now().toIso8601String(),
    };
    _messages.add(msg);
    return msg;
  }

  // --- User Profile ---
  Future<Map<String, dynamic>> getUserProfile(String userId) async {
    return _users.firstWhere((u) => u['id'] == userId, orElse: () => {
      'id': userId, 'username': 'unknown', 'displayName': 'Unknown', 'email': '', 'role': 'student', 'createdAt': DateTime.now().toIso8601String()
    });
  }

  Future<Map<String, dynamic>> updateUserProfile(String userId, Map<String, dynamic> data) async {
    final index = _users.indexWhere((u) => u['id'] == userId);
    if (index != -1) {
      _users[index] = {..._users[index], ...data};
      return _users[index];
    }
    return {};
  }

  Future<String> uploadAvatar(String userId, String path) async {
    return path; // Mock: return local path
  }

  Future<void> changePassword(String userId, String old, String newPass) async {
    // Mock success
  }

  Future uploadStudentCsv(File file) async {}
}