import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OfflineDatabaseService {
  // Existing boxes
  static const String _coursesBox = 'courses_cache';
  static const String _assignmentsBox = 'assignments_cache';
  static const String _submissionsBox = 'submissions_cache';
  static const String _quizzesBox = 'quizzes_cache';
  static const String _materialsBox = 'materials_cache';
  static const String _announcementsBox = 'announcements_cache';
  static const String _userBox = 'user_cache';
  
  // ✅ PENDING ACTIONS BOX (Required for SyncService)
  static const String _pendingActionsBox = 'pending_actions';

  // ✅ NEW BOXES for offline features
  static const String _semestersBox = 'semesters_cache';
  static const String _groupsBox = 'groups_cache';
  static const String _studentsBox = 'students_cache';
  static const String _courseDetailsBox = 'course_details_cache';
  static const String _enrolledCoursesBox = 'enrolled_courses_cache';
  static const String _quizAttemptsBox = 'quiz_attempts_cache';
  static const String _forumTopicsBox = 'forum_topics_cache';
  static const String _forumRepliesBox = 'forum_replies_cache';

  // Initialize Hive
  static Future<void> initialize() async {
    await Hive.initFlutter();
    
    // Open all boxes
    await Hive.openBox(_coursesBox);
    await Hive.openBox(_assignmentsBox);
    await Hive.openBox(_submissionsBox);
    await Hive.openBox(_quizzesBox);
    await Hive.openBox(_materialsBox);
    await Hive.openBox(_announcementsBox);
    await Hive.openBox(_userBox);
    await Hive.openBox(_pendingActionsBox); // ✅ Open pending actions
    
    // Open new boxes
    await Hive.openBox(_semestersBox);
    await Hive.openBox(_groupsBox);
    await Hive.openBox(_studentsBox);
    await Hive.openBox(_courseDetailsBox);
    await Hive.openBox(_enrolledCoursesBox);
    await Hive.openBox(_quizAttemptsBox);
    await Hive.openBox(_forumTopicsBox);
    await Hive.openBox(_forumRepliesBox);
    
    debugPrint('✅ Offline database initialized');
  }

  // ✅ HELPER: Converts Timestamps to Strings before saving
  static dynamic _sanitizeData(dynamic data) {
    if (data is Timestamp) {
      return data.toDate().toIso8601String();
    } else if (data is Map) {
      final Map<String, dynamic> newMap = {};
      data.forEach((key, value) {
        newMap[key.toString()] = _sanitizeData(value);
      });
      return newMap;
    } else if (data is List) {
      return data.map((item) => _sanitizeData(item)).toList();
    }
    return data;
  }

  // --- PENDING ACTIONS (Restored for SyncService) ---
  
  static Future<void> savePendingAction(Map<String, dynamic> action) async {
    try {
      final box = Hive.box(_pendingActionsBox);
      // We use a simple list stored under a single key, or add directly to box
      // Here we append to a list stored under 'actions' to keep order
      final List<dynamic> currentActions = box.get('actions', defaultValue: []) ?? [];
      currentActions.add(_sanitizeData(action));
      await box.put('actions', currentActions);
      debugPrint('⏳ Pending action saved: ${action['type']}');
    } catch (e) {
      debugPrint('❌ Error saving pending action: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getPendingActions() async {
    try {
      final box = Hive.box(_pendingActionsBox);
      final List<dynamic> actions = box.get('actions', defaultValue: []) ?? [];
      return actions.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      debugPrint('❌ Error getting pending actions: $e');
      return [];
    }
  }

  static Future<void> clearPendingActions() async {
    try {
      final box = Hive.box(_pendingActionsBox);
      await box.delete('actions');
      debugPrint('✅ Pending actions cleared');
    } catch (e) {
      debugPrint('❌ Error clearing pending actions: $e');
    }
  }

  // --- SEMESTERS ---
  static Future<void> saveSemesters(List<dynamic> semesters) async {
    try {
      final box = Hive.box(_semestersBox);
      await box.put('all_semesters', _sanitizeData(semesters));
    } catch (e) {
      debugPrint('❌ Error saving semesters: $e');
    }
  }

  static List<dynamic>? getSemesters() {
    try {
      final box = Hive.box(_semestersBox);
      final data = box.get('all_semesters');
      return data != null ? List<dynamic>.from(data) : null;
    } catch (e) {
      return null;
    }
  }

  // --- COURSES (General & Enrolled) ---
  static Future<void> saveCourses(String semesterId, List<dynamic> courses) async {
    try {
      final box = Hive.box(_coursesBox);
      await box.put(semesterId, _sanitizeData(courses));
    } catch (e) { debugPrint('❌ Error saving courses: $e'); }
  }

  static List<dynamic>? getCourses(String semesterId) {
    try {
      final box = Hive.box(_coursesBox);
      final data = box.get(semesterId);
      return data != null ? List<dynamic>.from(data) : null;
    } catch (e) { return null; }
  }

  static Future<void> saveEnrolledCourses(String key, List<dynamic> courses) async {
    try {
      final box = Hive.box(_enrolledCoursesBox);
      await box.put(key, _sanitizeData(courses));
    } catch (e) { debugPrint('❌ Error saving enrolled courses: $e'); }
  }

  static List<dynamic>? getEnrolledCourses(String key) {
    try {
      final box = Hive.box(_enrolledCoursesBox);
      final data = box.get(key);
      return data != null ? List<dynamic>.from(data) : null;
    } catch (e) { return null; }
  }

  static Future<void> saveCourseDetails(String courseId, Map<String, dynamic> data) async {
    try {
      final box = Hive.box(_courseDetailsBox);
      await box.put(courseId, _sanitizeData(data));
    } catch (e) { debugPrint('❌ Error saving course details: $e'); }
  }

  static Map<String, dynamic>? getCourseDetails(String courseId) {
    try {
      final box = Hive.box(_courseDetailsBox);
      final data = box.get(courseId);
      return data != null ? Map<String, dynamic>.from(data) : null;
    } catch (e) { return null; }
  }

  // --- GROUPS & STUDENTS ---
  static Future<void> saveGroups(String courseId, List<dynamic> groups) async {
    try {
      final box = Hive.box(_groupsBox);
      await box.put(courseId, _sanitizeData(groups));
    } catch (e) { debugPrint('❌ Error saving groups: $e'); }
  }

  static List<dynamic>? getGroups(String courseId) {
    try {
      final box = Hive.box(_groupsBox);
      final data = box.get(courseId);
      return data != null ? List<dynamic>.from(data) : null;
    } catch (e) { return null; }
  }

  static Future<void> saveStudents(String key, List<dynamic> students) async {
    try {
      final box = Hive.box(_studentsBox);
      await box.put(key, _sanitizeData(students));
    } catch (e) { debugPrint('❌ Error saving students: $e'); }
  }

  static List<dynamic>? getStudents(String key) {
    try {
      final box = Hive.box(_studentsBox);
      final data = box.get(key);
      return data != null ? List<dynamic>.from(data) : null;
    } catch (e) { return null; }
  }

  // --- ASSIGNMENTS & SUBMISSIONS ---
  static Future<void> saveAssignments(String courseId, List<dynamic> assignments) async {
    try {
      final box = Hive.box(_assignmentsBox);
      await box.put(courseId, _sanitizeData(assignments));
    } catch (e) { debugPrint('❌ Error saving assignments: $e'); }
  }

  static List<dynamic>? getAssignments(String courseId) {
    try {
      final box = Hive.box(_assignmentsBox);
      final data = box.get(courseId);
      return data != null ? List<dynamic>.from(data) : null;
    } catch (e) { return null; }
  }

  static Future<void> saveSubmissions(String key, List<dynamic> submissions) async {
    try {
      final box = Hive.box(_submissionsBox);
      await box.put(key, _sanitizeData(submissions));
    } catch (e) { debugPrint('❌ Error saving submissions: $e'); }
  }

  static List<dynamic>? getSubmissions(String key) {
    try {
      final box = Hive.box(_submissionsBox);
      final data = box.get(key);
      return data != null ? List<dynamic>.from(data) : null;
    } catch (e) { return null; }
  }

  // --- QUIZZES & ATTEMPTS ---
  static Future<void> saveQuizzes(String courseId, List<dynamic> quizzes) async {
    try {
      final box = Hive.box(_quizzesBox);
      await box.put(courseId, _sanitizeData(quizzes));
    } catch (e) { debugPrint('❌ Error saving quizzes: $e'); }
  }

  static List<dynamic>? getQuizzes(String courseId) {
    try {
      final box = Hive.box(_quizzesBox);
      final data = box.get(courseId);
      return data != null ? List<dynamic>.from(data) : null;
    } catch (e) { return null; }
  }

  static Future<void> saveQuizAttempts(String quizId, List<dynamic> attempts) async {
    try {
      final box = Hive.box(_quizAttemptsBox);
      await box.put(quizId, _sanitizeData(attempts));
    } catch (e) { debugPrint('❌ Error saving quiz attempts: $e'); }
  }

  static List<dynamic>? getQuizAttempts(String quizId) {
    try {
      final box = Hive.box(_quizAttemptsBox);
      final data = box.get(quizId);
      return data != null ? List<dynamic>.from(data) : null;
    } catch (e) { return null; }
  }

  // --- MATERIALS & ANNOUNCEMENTS ---
  static Future<void> saveMaterials(String courseId, List<dynamic> materials) async {
    try {
      final box = Hive.box(_materialsBox);
      await box.put(courseId, _sanitizeData(materials));
    } catch (e) { debugPrint('❌ Error saving materials: $e'); }
  }

  static List<dynamic>? getMaterials(String courseId) {
    try {
      final box = Hive.box(_materialsBox);
      final data = box.get(courseId);
      return data != null ? List<dynamic>.from(data) : null;
    } catch (e) { return null; }
  }

  static Future<void> saveAnnouncements(String courseId, List<dynamic> announcements) async {
    try {
      final box = Hive.box(_announcementsBox);
      await box.put(courseId, _sanitizeData(announcements));
    } catch (e) { debugPrint('❌ Error saving announcements: $e'); }
  }

  static List<dynamic>? getAnnouncements(String courseId) {
    try {
      final box = Hive.box(_announcementsBox);
      final data = box.get(courseId);
      return data != null ? List<dynamic>.from(data) : null;
    } catch (e) { return null; }
  }

  // --- FORUM ---
  static Future<void> saveForumTopics(String courseId, List<dynamic> topics) async {
    try {
      final box = Hive.box(_forumTopicsBox);
      await box.put(courseId, _sanitizeData(topics));
    } catch (e) { debugPrint('❌ Error saving forum topics: $e'); }
  }

  static List<dynamic>? getForumTopics(String courseId) {
    try {
      final box = Hive.box(_forumTopicsBox);
      final data = box.get(courseId);
      return data != null ? List<dynamic>.from(data) : null;
    } catch (e) { return null; }
  }

  static Future<void> clearCourseData(String courseId) async {
    try {
      await Hive.box(_assignmentsBox).delete(courseId);
      await Hive.box(_quizzesBox).delete(courseId);
      await Hive.box(_materialsBox).delete(courseId);
      await Hive.box(_announcementsBox).delete(courseId);
      await Hive.box(_groupsBox).delete(courseId);
      await Hive.box(_courseDetailsBox).delete(courseId);
      await Hive.box(_forumTopicsBox).delete(courseId);
    } catch (e) {
      debugPrint('❌ Error clearing course data: $e');
    }
  }

  static Future<void> clearAllCache() async {
    try {
      await Hive.box(_coursesBox).clear();
      await Hive.box(_assignmentsBox).clear();
      await Hive.box(_submissionsBox).clear();
      await Hive.box(_quizzesBox).clear();
      await Hive.box(_materialsBox).clear();
      await Hive.box(_announcementsBox).clear();
      await Hive.box(_pendingActionsBox).clear(); // ✅ Clear pending actions too
      await Hive.box(_semestersBox).clear();
      await Hive.box(_groupsBox).clear();
      await Hive.box(_studentsBox).clear();
      await Hive.box(_courseDetailsBox).clear();
      await Hive.box(_enrolledCoursesBox).clear();
      await Hive.box(_quizAttemptsBox).clear();
      await Hive.box(_forumTopicsBox).clear();
      await Hive.box(_forumRepliesBox).clear();
      debugPrint('🗑️ Cleared all offline cache');
    } catch (e) {
      debugPrint('❌ Error clearing cache: $e');
    }
  }
}