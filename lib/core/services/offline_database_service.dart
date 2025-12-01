import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/course_model.dart';
import '../models/announcement_model.dart';
import '../models/material_model.dart';
import '../models/assignment_model.dart';
import '../models/submission_model.dart';
import '../models/quiz_model.dart';
import '../models/quiz_attempt_model.dart';

class OfflineDatabaseService {
  static const String _coursesBox = 'courses';
  static const String _announcementsBox = 'announcements';
  static const String _materialsBox = 'materials';
  static const String _assignmentsBox = 'assignments';
  static const String _submissionsBox = 'submissions';
  static const String _quizzesBox = 'quizzes';
  static const String _quizAttemptsBox = 'quiz_attempts';
  static const String _metadataBox = 'metadata';

  // Initialize Hive
  static Future<void> initialize() async {
    await Hive.initFlutter();
    
    // Open boxes
    await Hive. openBox(_coursesBox);
    await Hive.openBox(_announcementsBox);
    await Hive.openBox(_materialsBox);
    await Hive.openBox(_assignmentsBox);
    await Hive.openBox(_submissionsBox);
    await Hive.openBox(_quizzesBox);
    await Hive.openBox(_quizAttemptsBox);
    await Hive.openBox(_metadataBox);

    debugPrint('✅ Offline database initialized');
  }

  // ==================== COURSES ====================
  
  static Future<void> saveCourses(String semesterId, List<Map<String, dynamic>> courses) async {
    final box = Hive.box(_coursesBox);
    await box.put(semesterId, courses);
    await _updateLastSync('courses_$semesterId');
    debugPrint('💾 Saved ${courses.length} courses offline for semester $semesterId');
  }

  static List<Map<String, dynamic>>? getCourses(String semesterId) {
    final box = Hive.box(_coursesBox);
    final data = box.get(semesterId);
    if (data != null) {
      return List<Map<String, dynamic>>. from(data);
    }
    return null;
  }

  // ==================== ANNOUNCEMENTS ====================
  
  static Future<void> saveAnnouncements(String courseId, List<Map<String, dynamic>> announcements) async {
    final box = Hive. box(_announcementsBox);
    await box.put(courseId, announcements);
    await _updateLastSync('announcements_$courseId');
    debugPrint('💾 Saved ${announcements.length} announcements offline for course $courseId');
  }

  static List<Map<String, dynamic>>? getAnnouncements(String courseId) {
    final box = Hive.box(_announcementsBox);
    final data = box. get(courseId);
    if (data != null) {
      return List<Map<String, dynamic>>.from(data);
    }
    return null;
  }

  // ==================== MATERIALS ====================
  
  static Future<void> saveMaterials(String courseId, List<Map<String, dynamic>> materials) async {
    final box = Hive.box(_materialsBox);
    await box. put(courseId, materials);
    await _updateLastSync('materials_$courseId');
    debugPrint('💾 Saved ${materials.length} materials offline for course $courseId');
  }

  static List<Map<String, dynamic>>? getMaterials(String courseId) {
    final box = Hive.box(_materialsBox);
    final data = box.get(courseId);
    if (data != null) {
      return List<Map<String, dynamic>>.from(data);
    }
    return null;
  }

  // ==================== ASSIGNMENTS ====================
  
  static Future<void> saveAssignments(String courseId, List<Map<String, dynamic>> assignments) async {
    final box = Hive.box(_assignmentsBox);
    await box.put(courseId, assignments);
    await _updateLastSync('assignments_$courseId');
    debugPrint('💾 Saved ${assignments.length} assignments offline for course $courseId');
  }

  static List<Map<String, dynamic>>? getAssignments(String courseId) {
    final box = Hive. box(_assignmentsBox);
    final data = box.get(courseId);
    if (data != null) {
      return List<Map<String, dynamic>>. from(data);
    }
    return null;
  }

  // ==================== SUBMISSIONS ====================
  
  static Future<void> saveSubmissions(String assignmentId, List<Map<String, dynamic>> submissions) async {
    final box = Hive. box(_submissionsBox);
    await box.put(assignmentId, submissions);
    await _updateLastSync('submissions_$assignmentId');
    debugPrint('💾 Saved ${submissions.length} submissions offline for assignment $assignmentId');
  }

  static List<Map<String, dynamic>>? getSubmissions(String assignmentId) {
    final box = Hive.box(_submissionsBox);
    final data = box.get(assignmentId);
    if (data != null) {
      return List<Map<String, dynamic>>.from(data);
    }
    return null;
  }

  // ==================== QUIZZES ====================
  
  static Future<void> saveQuizzes(String courseId, List<Map<String, dynamic>> quizzes) async {
    final box = Hive.box(_quizzesBox);
    await box.put(courseId, quizzes);
    await _updateLastSync('quizzes_$courseId');
    debugPrint('💾 Saved ${quizzes.length} quizzes offline for course $courseId');
  }

  static List<Map<String, dynamic>>? getQuizzes(String courseId) {
    final box = Hive.box(_quizzesBox);
    final data = box.get(courseId);
    if (data != null) {
      return List<Map<String, dynamic>>.from(data);
    }
    return null;
  }

  // ==================== QUIZ ATTEMPTS ====================
  
  static Future<void> saveQuizAttempts(String quizId, List<Map<String, dynamic>> attempts) async {
    final box = Hive.box(_quizAttemptsBox);
    await box.put(quizId, attempts);
    await _updateLastSync('quiz_attempts_$quizId');
    debugPrint('💾 Saved ${attempts.length} quiz attempts offline for quiz $quizId');
  }

  static List<Map<String, dynamic>>? getQuizAttempts(String quizId) {
    final box = Hive.box(_quizAttemptsBox);
    final data = box.get(quizId);
    if (data != null) {
      return List<Map<String, dynamic>>.from(data);
    }
    return null;
  }

  // ==================== METADATA ====================
  
  static Future<void> _updateLastSync(String key) async {
    final box = Hive.box(_metadataBox);
    await box.put('last_sync_$key', DateTime.now().toIso8601String());
  }

  static String? getLastSync(String key) {
    final box = Hive. box(_metadataBox);
    return box.get('last_sync_$key');
  }

  // ==================== CLEAR DATA ====================
  
  static Future<void> clearAllData() async {
    await Hive.box(_coursesBox).clear();
    await Hive.box(_announcementsBox).clear();
    await Hive.box(_materialsBox).clear();
    await Hive.box(_assignmentsBox).clear();
    await Hive.box(_submissionsBox).clear();
    await Hive.box(_quizzesBox).clear();
    await Hive.box(_quizAttemptsBox).clear();
    await Hive. box(_metadataBox).clear();
    debugPrint('🗑️ Cleared all offline data');
  }

  static Future<void> clearCourseData(String courseId) async {
    await Hive.box(_announcementsBox).delete(courseId);
    await Hive.box(_materialsBox).delete(courseId);
    await Hive.box(_assignmentsBox).delete(courseId);
    await Hive. box(_quizzesBox).delete(courseId);
    debugPrint('🗑️ Cleared offline data for course $courseId');
  }
}