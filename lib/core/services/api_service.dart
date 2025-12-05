import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'offline_database_service.dart';
import 'sync_service.dart';

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

  Future<bool> _isOnline() async {
    return await SyncService().isOnline();
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

  // --- Questions (for Quiz) ---
  Future<Map<String, dynamic>> createQuestion(String courseId, Map<String, dynamic> questionData) async {
    try {
      final docRef = await _firestore.collection('questions').add({
        'courseId': courseId,
        'question': questionData['question'],
        'choices': questionData['choices'],
        'correctAnswer': questionData['correctAnswer'],
        'difficulty': questionData['difficulty'],
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      final doc = await docRef.get();
      debugPrint('✅ Question created: ${doc.id}');
      return {'id': doc.id, ...doc.data() ?? {}};
    } catch (e) {
      debugPrint('❌ Error creating question: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> getQuestions(String courseId, {String? difficulty}) async {
    try {
      Query query = _firestore
          .collection('questions')
          .where('courseId', isEqualTo: courseId);
      
      if (difficulty != null) {
        query = query.where('difficulty', isEqualTo: difficulty);
      }
      
      final snapshot = await query.get();
      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>}).toList();
    } catch (e) {
      debugPrint('❌ Error getting questions: $e');
      return [];
    }
  }

  Future<void> deleteQuestion(String questionId) async {
    try {
      await _firestore.collection('questions').doc(questionId).delete();
      debugPrint('🗑️ Question deleted: $questionId');
    } catch (e) {
      debugPrint('❌ Error deleting question: $e');
      rethrow;
    }
  }

  // --- Semesters ---
  Future<List<dynamic>> getSemesters() async {
    try {
      if (await _isOnline()) {
        final snapshot = await _firestore.collection('semesters').get();
        final semesters = snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
        
        // Save to offline cache
        await OfflineDatabaseService.saveSemesters(semesters);
        return semesters;
      } else {
        debugPrint('📡 Offline - loading semesters from cache');
        return OfflineDatabaseService.getSemesters() ?? [];
      }
    } catch (e) {
      debugPrint('❌ Error getting semesters: $e');
      return OfflineDatabaseService.getSemesters() ?? [];
    }
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
    try {
      if (await _isOnline()) {
        final snapshot = await _firestore
            .collection('courses')
            .where('semesterId', isEqualTo: semesterId)
            .get();
        
        final courses = snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
        
        // Save to offline cache
        await OfflineDatabaseService.saveCourses(semesterId, courses);
        
        return courses;
      } else {
        // Return offline data
        debugPrint('📡 Offline - loading courses from cache');
        final cachedData = OfflineDatabaseService.getCourses(semesterId);
        return cachedData ?? [];
      }
    } catch (e) {
      debugPrint('❌ Error getting courses: $e');
      final cachedData = OfflineDatabaseService.getCourses(semesterId);
      return cachedData ?? [];
    }
  }

  Future<List<dynamic>> getCoursesBySemester(String semesterId) async {
    return await getCourses(semesterId);
  }

  Future<Map<String, dynamic>> getCourseDetails(String courseId) async {
    try {
      if (await _isOnline()) {
        final doc = await _firestore.collection('courses').doc(courseId).get();
        if (doc.exists) {
          final data = doc.data() ?? {};
          final courseData = {
            'id': doc.id,
            ...data,
            'createdAt': _convertToIsoString(data['createdAt']),
          };
          
          await OfflineDatabaseService.saveCourseDetails(courseId, courseData);
          return courseData;
        }
        return {};
      } else {
        debugPrint('📡 Offline - loading course details from cache');
        return OfflineDatabaseService.getCourseDetails(courseId) ?? {};
      }
    } catch (e) {
      debugPrint('Error getting course details: $e');
      return OfflineDatabaseService.getCourseDetails(courseId) ?? {};
    }
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
    await OfflineDatabaseService.clearCourseData(id);
  }

  // --- Groups ---
  Future<List<dynamic>> getGroups(String courseId) async {
    try {
      if (await _isOnline()) {
        final snapshot = await _firestore
            .collection('groups')
            .where('courseId', isEqualTo: courseId)
            .get();
        
        debugPrint('📦 Found ${snapshot.docs.length} groups for courseId: $courseId');
        
        final groups = snapshot.docs.map((doc) {
          final data = doc.data(); // Standard map access
          return {
            'id': doc.id,
            'courseId': data['courseId'] ?? courseId,
            'name': data['name'] ?? '',
            'description': data['description'],
            'maxStudents': data['maxStudents'],
            'studentCount': data['studentCount'] ?? 0,
            'createdAt': _convertToIsoString(data['createdAt']),
          };
        }).toList();

        await OfflineDatabaseService.saveGroups(courseId, groups);
        return groups;
      } else {
        debugPrint('📡 Offline - loading groups from cache');
        return OfflineDatabaseService.getGroups(courseId) ?? [];
      }
    } catch (e) {
      debugPrint('❌ Error getting groups: $e');
      return OfflineDatabaseService.getGroups(courseId) ?? [];
    }
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
    final cacheKey = groupId != null ? '${courseId}_$groupId' : courseId;
    try {
      if (await _isOnline()) {
        Query query = _firestore.collection('enrollments').where('courseId', isEqualTo: courseId);
        
        if (groupId != null) {
          query = query.where('groupId', isEqualTo: groupId);
        }
        
        final enrollments = await query.get();
        final studentIds = enrollments.docs
            // ✅ FIX: Cast to Map<String, dynamic> to avoid null error
            .map((doc) => (doc.data() as Map<String, dynamic>)['studentId'] as String)
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
        
        await OfflineDatabaseService.saveStudents(cacheKey, students);
        return students;
      } else {
        debugPrint('📡 Offline - loading students from cache');
        return OfflineDatabaseService.getStudents(cacheKey) ?? [];
      }
    } catch (e) {
      debugPrint('❌ Error getting students: $e');
      return OfflineDatabaseService.getStudents(cacheKey) ?? [];
    }
  }

  Future<List<dynamic>> getAllStudents() async {
    final snapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'student')
        .get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  // Inside ApiService class
  Future<void> createStudent(Map<String, dynamic> data) async {
    final firestore = FirebaseFirestore.instance;
    final auth = FirebaseAuth.instance;

    // 1. Force a default password for the demo
    final String password = '123456'; 

    try {
      // Check if user exists
      final existing = await firestore
          .collection('users')
          .where('email', isEqualTo: data['email'])
          .get();

      if (existing.docs.isNotEmpty) return; // Skip if exists

      // Create Auth User
      final userCredential = await auth.createUserWithEmailAndPassword(
        email: data['email'],
        password: password, // <--- USE FIXED PASSWORD HERE
      );

      // Create Firestore Doc
      await firestore.collection('users').doc(userCredential.user!.uid).set({
        'username': data['username'],
        'displayName': data['displayName'],
        'email': data['email'],
        'studentId': data['studentId'],
        'department': data['department'],
        'role': 'student',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Important: Sign out the new student immediately so Admin stays logged in
      // (This is a simplified hack for the demo. In real apps, you'd use Admin SDK)
      await auth.signOut();
      
    } catch (e) {
      debugPrint('Error creating student ${data['username']}: $e');
      // Don't rethrow, just log so import continues
    }
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
    try {
      if (await _isOnline()) {
        final snapshot = await _firestore
            .collection('assignments')
            .where('courseId', isEqualTo: courseId)
            .get();
        
        final assignments = snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
        
        // Save to offline cache
        await OfflineDatabaseService.saveAssignments(courseId, assignments);
        
        return assignments;
      } else {
        // Return offline data
        debugPrint('📡 Offline - loading assignments from cache');
        final cachedData = OfflineDatabaseService.getAssignments(courseId);
        return cachedData ?? [];
      }
    } catch (e) {
      debugPrint('❌ Error getting assignments: $e');
      final cachedData = OfflineDatabaseService.getAssignments(courseId);
      return cachedData ?? [];
    }
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
    try {
      if (await _isOnline()) {
        final snapshot = await _firestore
            .collection('submissions')
            .where('assignmentId', isEqualTo: assignmentId)
            .get();
        
        final submissions = snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
        
        // Save to offline cache
        await OfflineDatabaseService.saveSubmissions(assignmentId, submissions);
        
        return submissions;
      } else {
        // Return offline data
        debugPrint('📡 Offline - loading submissions from cache');
        final cachedData = OfflineDatabaseService.getSubmissions(assignmentId);
        return cachedData ?? [];
      }
    } catch (e) {
      debugPrint('❌ Error getting submissions: $e');
      final cachedData = OfflineDatabaseService.getSubmissions(assignmentId);
      return cachedData ?? [];
    }
  }

  Future<List<dynamic>> getMySubmissions(String assignmentId, String studentId) async {
    final cacheKey = '${assignmentId}_$studentId';
    try {
      if (await _isOnline()) {
        final snapshot = await _firestore
            .collection('submissions')
            .where('assignmentId', isEqualTo: assignmentId)
            .where('studentId', isEqualTo: studentId)
            .get();
        
        final submissions = snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
        
        await OfflineDatabaseService.saveSubmissions(cacheKey, submissions);
        return submissions;
      } else {
        return OfflineDatabaseService.getSubmissions(cacheKey) ?? [];
      }
    } catch (e) {
      return OfflineDatabaseService.getSubmissions(cacheKey) ?? [];
    }
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
    try {
      if (await _isOnline()) {
        final snapshot = await _firestore
            .collection('quizzes')
            .where('courseId', isEqualTo: courseId)
            .get();
        
        final quizzes = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            ...data,
            'openTime': _convertToIsoString(data['openTime']),
            'closeTime': _convertToIsoString(data['closeTime']),
            'createdAt': _convertToIsoString(data['createdAt']),
            'updatedAt': _convertToIsoString(data['updatedAt']),
          };
        }).toList();
        
        // Save to offline cache
        await OfflineDatabaseService.saveQuizzes(courseId, quizzes);
        
        return quizzes;
      } else {
        // Return offline data
        debugPrint('📡 Offline - loading quizzes from cache');
        final cachedData = OfflineDatabaseService.getQuizzes(courseId);
        return cachedData ?? [];
      }
    } catch (e) {
      debugPrint('❌ Error getting quizzes: $e');
      final cachedData = OfflineDatabaseService.getQuizzes(courseId);
      return cachedData ?? [];
    }
  }

  String _convertToIsoString(dynamic value) {
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

  Future<Map<String, dynamic>?> getQuizById(String quizId) async {
    try {
      final doc = await _firestore.collection('quizzes').doc(quizId).get();
      if (doc.exists) {
        final data = doc.data() ?? {};
        return {
          'id': doc.id,
          ...data,
          'openTime': _convertToIsoString(data['openTime']),
          'closeTime': _convertToIsoString(data['closeTime']),
          'createdAt': _convertToIsoString(data['createdAt']),
          'updatedAt': _convertToIsoString(data['updatedAt']),
        };
      }
      return null;
    } catch (e) {
      debugPrint('Error getting quiz by ID: $e');
      return null;
    }
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
    try {
      if (await _isOnline()) {
        final snapshot = await _firestore
            .collection('quizAttempts')
            .where('quizId', isEqualTo: quizId)
            .orderBy('startedAt', descending: true)
            .get();

        final attempts = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            ...data,
            'startedAt': _convertToIsoString(data['startedAt']),
            'submittedAt': _convertToIsoString(data['submittedAt']),
          };
        }).toList();
        
        await OfflineDatabaseService.saveQuizAttempts(quizId, attempts);
        return attempts;
      } else {
        return OfflineDatabaseService.getQuizAttempts(quizId) ?? [];
      }
    } catch (e) {
      debugPrint('❌ Error getting quiz attempts: $e');
      return OfflineDatabaseService.getQuizAttempts(quizId) ?? [];
    }
  }

  Future<Map<String, dynamic>> startQuizAttempt(
    String quizId,
    String studentId,
    String studentName,
  ) async {
    try {
      final docRef = await _firestore.collection('quizAttempts').add({
        'quizId': quizId,
        'studentId': studentId,
        'studentName': studentName,
        'attemptNumber': 1, // Calculate properly in production
        'answers': {},
        'score': 0.0,
        'startedAt': FieldValue.serverTimestamp(),
        'submittedAt': null,
      });

      final doc = await docRef.get();
      final data = doc.data() ?? {};
      
      return {
        'id': doc.id,
        ...data,
        'startedAt': _convertToIsoString(data['startedAt']),
        'submittedAt': null,
      };
    } catch (e) {
      debugPrint('❌ Error starting quiz attempt: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getForumTopicById(String topicId) async {
    try {
      final doc = await _firestore.collection('forumTopics').doc(topicId).get();
      if (doc.exists) {
        final data = doc.data() ?? {};
        return {
          'id': doc.id,
          ...data,
          'createdAt': _convertToIsoString(data['createdAt']),
          'updatedAt': _convertToIsoString(data['updatedAt']),
        };
      }
      return null;
    } catch (e) {
      debugPrint('Error getting forum topic: $e');
      return null;
    }
  }

  Future<void> incrementForumTopicView(String topicId) async {
    try {
      await _firestore.collection('forumTopics').doc(topicId).update({
        'viewCount': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('Error incrementing view count: $e');
    }
  }

  Future<void> submitQuizAttempt(
    String attemptId,
    Map<String, int> answers,
  ) async {
    try {
      await _firestore.collection('quizAttempts').doc(attemptId).update({
        'answers': answers,
        'submittedAt': FieldValue.serverTimestamp(),
      });
      
      debugPrint('✅ Quiz attempt submitted');
    } catch (e) {
      debugPrint('❌ Error submitting quiz attempt: $e');
      rethrow;
    }
  }

  // --- Materials ---
  Future<List<dynamic>> getMaterials(String courseId) async {
    try {
      if (await _isOnline()) {
        final snapshot = await _firestore
            .collection('materials')
            .where('courseId', isEqualTo: courseId)
            .get();
        
        final materials = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'courseId': data['courseId'] ?? courseId,
            'title': data['title'] ?? '',
            'description': data['description'] ?? '',
            'type': data['type'] ?? 'document',
            'fileUrl': data['fileUrl'] ?? '',
            'fileUrls': data['fileUrls'] ?? [],
            'links': data['links'] ?? [],
            'groupIds': data['groupIds'] ?? [],
            'authorName': data['authorName'] ?? 'Unknown',
            'viewCount': data['viewCount'] ?? 0,
            'downloadCount': data['downloadCount'] ?? 0,
            'createdAt': _convertToIsoString(data['createdAt']),
            'updatedAt': _convertToIsoString(data['updatedAt']),
          };
        }).toList();
        
        // Save to offline cache
        await OfflineDatabaseService.saveMaterials(courseId, materials);
        
        return materials;
      } else {
        // Return offline data
        debugPrint('📡 Offline - loading materials from cache');
        final cachedData = OfflineDatabaseService.getMaterials(courseId);
        return cachedData ?? [];
      }
    } catch (e) {
      debugPrint('❌ Error getting materials: $e');
      final cachedData = OfflineDatabaseService.getMaterials(courseId);
      return cachedData ?? [];
    }
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
    try {
      if (await _isOnline()) {
        final snapshot = await _firestore
            .collection('announcements')
            .where('courseId', isEqualTo: courseId)
            .orderBy('createdAt', descending: true)
            .get();

        final announcements = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            ...data,
            'createdAt': _convertToIsoString(data['createdAt']),
          };
        }).toList();

        // Save to offline cache
        await OfflineDatabaseService.saveAnnouncements(courseId, announcements);
        
        return announcements;
      } else {
        // Return offline data
        debugPrint('📡 Offline - loading announcements from cache');
        final cachedData = OfflineDatabaseService.getAnnouncements(courseId);
        return cachedData ?? [];
      }
    } catch (e) {
      debugPrint('❌ Error getting announcements: $e');
      final cachedData = OfflineDatabaseService.getAnnouncements(courseId);
      return cachedData ?? [];
    }
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
    try {
      if (await _isOnline()) {
        final snapshot = await _firestore
            .collection('forumTopics')
            .where('courseId', isEqualTo: courseId)
            .orderBy('createdAt', descending: true)
            .get();
        
        final topics = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            ...data,
            'createdAt': _convertToIsoString(data['createdAt']),
            'updatedAt': _convertToIsoString(data['updatedAt']),
          };
        }).toList();

        await OfflineDatabaseService.saveForumTopics(courseId, topics);
        return topics;
      } else {
        return OfflineDatabaseService.getForumTopics(courseId) ?? [];
      }
    } catch (e) {
      debugPrint('Error getting forum topics: $e');
      return OfflineDatabaseService.getForumTopics(courseId) ?? [];
    }
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

  Future<List<Map<String, dynamic>>> getForumReplies(String topicId) async {
    try {
      final snapshot = await _firestore
          .collection('forumReplies')
          .where('topicId', isEqualTo: topicId)
          .orderBy('createdAt')
          .get();
      
      final replies = snapshot.docs.map((doc) {
        final data = doc.data();
        debugPrint('📬 Reply from: ${data['authorName']}');
        return {
          'id': doc.id,
          ...data,
          'createdAt': _convertToIsoString(data['createdAt']),
        };
      }).toList();
      
      debugPrint('✅ Loaded ${replies.length} replies');
      return replies;
    } catch (e) {
      debugPrint('❌ Error getting forum replies: $e');
      return [];
    }
  }

  Future<void> createForumReply(Map<String, dynamic> data) async {
    try {
      debugPrint('📝 Creating forum reply with author: ${data['authorName']}');
      
      await _firestore.collection('forumReplies').add({
        'topicId': data['topicId'],
        'content': data['content'],
        'authorId': data['authorId'],
        'authorName': data['authorName'],
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      // Increment reply count
      await _firestore
          .collection('forumTopics')
          .doc(data['topicId'])
          .update({'replyCount': FieldValue.increment(1)});
          
      debugPrint('✅ Forum reply created by: ${data['authorName']}');
    } catch (e) {
      debugPrint('❌ Error creating forum reply: $e');
      rethrow;
    }
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
    try {
      final snapshot = await _firestore
          .collection('messages')
          .where('participantIds', arrayContains: userId)
          .orderBy('createdAt', descending: true)
          .get();
      
      Map<String, Map<String, dynamic>> conversations = {};
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final senderId = data['senderId'];
        final receiverId = data['receiverId'];
        final otherUserId = senderId == userId ? receiverId : senderId;
        
        if (!conversations.containsKey(otherUserId)) {
          final otherUserDoc = await _firestore.collection('users').doc(otherUserId).get();
          final otherUserName = otherUserDoc.data()?['displayName'] ?? 'Unknown';
          
          conversations[otherUserId] = {
            'id': otherUserId,
            'otherUserId': otherUserId,
            'otherUserName': otherUserName,
            'lastMessage': data['content'] ?? '',
            'lastMessageTime': _convertToIsoString(data['createdAt']),
            'isRead': data['isRead'] ?? false,
            'unreadCount': 0,
          };
        }
      }
      
      return conversations.values.toList();
    } catch (e) {
      debugPrint('❌ Error getting conversations: $e');
      return [];
    }
  }

  Future<List<dynamic>> getMessages(String userId, String otherUserId) async {
    try {
      final snapshot = await _firestore
          .collection('messages')
          .where('participantIds', arrayContains: userId)
          .orderBy('createdAt', descending: false)
          .get();
      
      final messages = snapshot.docs
          .map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'senderId': data['senderId'] ?? '',
              'receiverId': data['receiverId'] ?? '',
              'content': data['content'] ?? '',
              'participantIds': data['participantIds'] ?? [],
              'isRead': data['isRead'] ?? false,
              'createdAt': _convertToIsoString(data['createdAt']),
            };
          })
          .where((msg) =>
              (msg['senderId'] == userId && msg['receiverId'] == otherUserId) ||
              (msg['senderId'] == otherUserId && msg['receiverId'] == userId))
          .toList();
      
      return messages;
    } catch (e) {
      debugPrint('❌ Error getting messages: $e');
      return [];
    }
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
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data() ?? {};
        return {
          'id': doc.id,
          'username': data['username'] ?? '',
          'displayName': data['displayName'] ?? '',
          'email': data['email'] ?? '',
          'role': data['role'] ?? 'student',
          'avatarUrl': data['avatarUrl'],
          'phoneNumber': data['phoneNumber'],
          'studentId': data['studentId'],
          'department': data['department'],
          'bio': data['bio'],
          'createdAt': _convertToIsoString(data['createdAt']),
        };
      }
      return {
        'id': userId,
        'username': 'unknown',
        'displayName': 'Unknown',
        'email': '',
        'role': 'student',
        'createdAt': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('❌ Error getting user profile: $e');
      return {
        'id': userId,
        'username': 'unknown',
        'displayName': 'Unknown',
        'email': '',
        'role': 'student',
        'createdAt': DateTime.now().toIso8601String(),
      };
    }
  }

  Future<Map<String, dynamic>> updateUserProfile(String userId, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(userId).update(data);
    final doc = await _firestore.collection('users').doc(userId).get();
    return {'id': doc.id, ...doc.data() ?? {}};
  }

  Future<String> uploadAvatar(String userId, String path) async {
    final ref = _storage.ref().child('avatars/$userId/${DateTime.now().millisecondsSinceEpoch}');
    final file = File(path);
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<void> changePassword(String userId, String oldPassword, String newPass) async {
    // Firebase Auth password change would go here
  }

  Future uploadStudentCsv(File file) async {
    final ref = _storage.ref().child('csv/${DateTime.now().millisecondsSinceEpoch}_students.csv');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  // --- ENROLLED COURSES (for manual enrollment) ---
  Future<List<dynamic>> getEnrolledCourses(String semesterId, String studentId) async {
    final cacheKey = '${semesterId}_$studentId';
    try {
      if (await _isOnline()) {
        // Get student's enrollments
        final enrollmentsSnapshot = await _firestore
            .collection('enrollments')
            .where('studentId', isEqualTo: studentId)
            .get();

        // Get course IDs from enrollments
        final courseIds = enrollmentsSnapshot.docs
            // ✅ FIX: Cast to Map<String, dynamic>
            .map((doc) => (doc.data() as Map<String, dynamic>)['courseId'] as String)
            .toSet()
            .toList();

        if (courseIds.isEmpty) {
          return [];
        }

        // Get courses - handle chunks of 10 (Firestore limit)
        List<Map<String, dynamic>> allCourses = [];
        
        for (int i = 0; i < courseIds.length; i += 10) {
          final chunk = courseIds.skip(i).take(10).toList();
          
          final coursesSnapshot = await _firestore
              .collection('courses')
              .where('semesterId', isEqualTo: semesterId)
              .where(FieldPath.documentId, whereIn: chunk)
              .get();

          final courses = coursesSnapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              ...data,
              'createdAt': _convertToIsoString(data['createdAt']),
            };
          }).toList();
          
          allCourses.addAll(courses);
        }

        await OfflineDatabaseService.saveEnrolledCourses(cacheKey, allCourses);
        return allCourses;
      } else {
        return OfflineDatabaseService.getEnrolledCourses(cacheKey) ?? [];
      }
    } catch (e) {
      debugPrint('Error getting enrolled courses: $e');
      return OfflineDatabaseService.getEnrolledCourses(cacheKey) ?? [];
    }
  }

  // --- PASSWORD MANAGEMENT ---
  Future<bool> verifyPassword(String username, String password) async {
    try {
      debugPrint('🔐 Verifying password for: $username');
      
      final snapshot = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        debugPrint('❌ User not found');
        return false;
      }

      final userData = snapshot.docs.first.data();
      final email = userData['email'];
      
      // Try to sign in with Firebase Auth to verify password
      try {
        final userCred = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        return userCred.user != null;
      } catch (e) {
        debugPrint('❌ Password verification failed');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error verifying password: $e');
      return false;
    }
  }

  Future<void> updatePassword(String userId, String newPassword) async {
    try {
      debugPrint('🔐 Updating password for user: $userId');
      
      // Update in Firebase Auth
      final currentUser = _auth.currentUser;
      if (currentUser != null && currentUser.uid == userId) {
        await currentUser.updatePassword(newPassword);
      }
      
      debugPrint('✅ Password updated successfully');
    } catch (e) {
      debugPrint('❌ Error updating password: $e');
      rethrow;
    }
  }

  // --- MATERIAL HELPERS ---
  Future<void> incrementViewCount(String materialId) async {
    try {
      await _firestore.collection('materials').doc(materialId).update({
        'viewCount': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('Error incrementing view count: $e');
    }
  }

  Future<void> incrementDownloadCount(String materialId) async {
    try {
      await _firestore.collection('materials').doc(materialId).update({
        'downloadCount': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('Error incrementing download count: $e');
    }
  }

  Future<void> deleteMaterial(String id, String courseId) async {
    try {
      await _firestore.collection('materials').doc(id).delete();
    } catch (e) {
      debugPrint('Error deleting material: $e');
      rethrow;
    }
  }
}