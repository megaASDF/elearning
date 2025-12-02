import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';

class OfflineDatabaseService {
  static const String _coursesBox = 'courses_cache';
  static const String _assignmentsBox = 'assignments_cache';
  static const String _submissionsBox = 'submissions_cache';
  static const String _quizzesBox = 'quizzes_cache';
  static const String _materialsBox = 'materials_cache';
  static const String _announcementsBox = 'announcements_cache';
  static const String _userBox = 'user_cache';
  static const String _pendingActionsBox = 'pending_actions';

  // Initialize Hive
  static Future<void> initialize() async {
    await Hive.initFlutter();
    
    // Open all boxes
    await Hive.openBox(_coursesBox);
    await Hive.openBox(_assignmentsBox);
    await Hive. openBox(_submissionsBox);
    await Hive.openBox(_quizzesBox);
    await Hive.openBox(_materialsBox);
    await Hive.openBox(_announcementsBox);
    await Hive.openBox(_userBox);
    await Hive.openBox(_pendingActionsBox);
    
    debugPrint('✅ Offline database initialized');
  }

  // --- COURSES ---
  static Future<void> saveCourses(String semesterId, List<dynamic> courses) async {
    try {
      final box = Hive.box(_coursesBox);
      await box.put(semesterId, courses);
      debugPrint('💾 Saved ${courses.length} courses to offline cache');
    } catch (e) {
      debugPrint('❌ Error saving courses offline: $e');
    }
  }

  static List<dynamic>? getCourses(String semesterId) {
    try {
      final box = Hive. box(_coursesBox);
      final data = box.get(semesterId);
      if (data != null) {
        debugPrint('📂 Loaded ${(data as List).length} courses from offline cache');
        return List<dynamic>.from(data);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting courses offline: $e');
      return null;
    }
  }

  static Future<void> clearCourseData(String courseId) async {
    try {
      // Clear all data related to a specific course
      final coursesBox = Hive.box(_coursesBox);
      final assignmentsBox = Hive. box(_assignmentsBox);
      final quizzesBox = Hive. box(_quizzesBox);
      final materialsBox = Hive.box(_materialsBox);
      
      await assignmentsBox.delete(courseId);
      await quizzesBox.delete(courseId);
      await materialsBox. delete(courseId);
      
      debugPrint('🗑️ Cleared offline data for course: $courseId');
    } catch (e) {
      debugPrint('❌ Error clearing course data: $e');
    }
  }

  // --- ASSIGNMENTS ---
  static Future<void> saveAssignments(String courseId, List<dynamic> assignments) async {
    try {
      final box = Hive.box(_assignmentsBox);
      await box.put(courseId, assignments);
      debugPrint('💾 Saved ${assignments.length} assignments to offline cache');
    } catch (e) {
      debugPrint('❌ Error saving assignments offline: $e');
    }
  }

  static List<dynamic>? getAssignments(String courseId) {
    try {
      final box = Hive.box(_assignmentsBox);
      final data = box.get(courseId);
      if (data != null) {
        debugPrint('📂 Loaded ${(data as List). length} assignments from offline cache');
        return List<dynamic>.from(data);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting assignments offline: $e');
      return null;
    }
  }

  // --- SUBMISSIONS ---
  static Future<void> saveSubmissions(String assignmentId, List<dynamic> submissions) async {
    try {
      final box = Hive. box(_submissionsBox);
      await box.put(assignmentId, submissions);
      debugPrint('💾 Saved ${submissions.length} submissions to offline cache');
    } catch (e) {
      debugPrint('❌ Error saving submissions offline: $e');
    }
  }

  static List<dynamic>?  getSubmissions(String assignmentId) {
    try {
      final box = Hive.box(_submissionsBox);
      final data = box.get(assignmentId);
      if (data != null) {
        debugPrint('📂 Loaded ${(data as List).length} submissions from offline cache');
        return List<dynamic>.from(data);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting submissions offline: $e');
      return null;
    }
  }

  // --- QUIZZES ---
  static Future<void> saveQuizzes(String courseId, List<dynamic> quizzes) async {
    try {
      final box = Hive.box(_quizzesBox);
      await box.put(courseId, quizzes);
      debugPrint('💾 Saved ${quizzes. length} quizzes to offline cache');
    } catch (e) {
      debugPrint('❌ Error saving quizzes offline: $e');
    }
  }

  static List<dynamic>? getQuizzes(String courseId) {
    try {
      final box = Hive.box(_quizzesBox);
      final data = box.get(courseId);
      if (data != null) {
        debugPrint('📂 Loaded ${(data as List).length} quizzes from offline cache');
        return List<dynamic>.from(data);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting quizzes offline: $e');
      return null;
    }
  }

  // --- MATERIALS ---
  static Future<void> saveMaterials(String courseId, List<dynamic> materials) async {
    try {
      final box = Hive.box(_materialsBox);
      await box.put(courseId, materials);
      debugPrint('💾 Saved ${materials.length} materials to offline cache');
    } catch (e) {
      debugPrint('❌ Error saving materials offline: $e');
    }
  }

  static List<dynamic>? getMaterials(String courseId) {
    try {
      final box = Hive. box(_materialsBox);
      final data = box.get(courseId);
      if (data != null) {
        debugPrint('📂 Loaded ${(data as List).length} materials from offline cache');
        return List<dynamic>.from(data);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting materials offline: $e');
      return null;
    }
  }

  // --- ANNOUNCEMENTS ---
  static Future<void> saveAnnouncements(String courseId, List<dynamic> announcements) async {
    try {
      final box = Hive.box(_announcementsBox);
      await box.put(courseId, announcements);
      debugPrint('💾 Saved ${announcements.length} announcements to offline cache');
    } catch (e) {
      debugPrint('❌ Error saving announcements offline: $e');
    }
  }

  static List<dynamic>? getAnnouncements(String courseId) {
    try {
      final box = Hive.box(_announcementsBox);
      final data = box.get(courseId);
      if (data != null) {
        debugPrint('📂 Loaded ${(data as List).length} announcements from offline cache');
        return List<dynamic>.from(data);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting announcements offline: $e');
      return null;
    }
  }

  // --- PENDING ACTIONS (for sync when back online) ---
  static Future<void> savePendingAction(Map<String, dynamic> action) async {
    try {
      final box = Hive.box(_pendingActionsBox);
      final actions = box.get('actions', defaultValue: <dynamic>[]) as List;
      actions.add(action);
      await box.put('actions', actions);
      debugPrint('⏳ Saved pending action: ${action['type']}');
    } catch (e) {
      debugPrint('❌ Error saving pending action: $e');
    }
  }

  static List<dynamic> getPendingActions() {
    try {
      final box = Hive.box(_pendingActionsBox);
      final actions = box.get('actions', defaultValue: <dynamic>[]);
      return List<dynamic>.from(actions);
    } catch (e) {
      debugPrint('❌ Error getting pending actions: $e');
      return [];
    }
  }

  static Future<void> clearPendingActions() async {
    try {
      final box = Hive.box(_pendingActionsBox);
      await box.delete('actions');
      debugPrint('✅ Cleared all pending actions');
    } catch (e) {
      debugPrint('❌ Error clearing pending actions: $e');
    }
  }

  // --- CLEAR ALL CACHE ---
  static Future<void> clearAllCache() async {
    try {
      await Hive.box(_coursesBox).clear();
      await Hive.box(_assignmentsBox).clear();
      await Hive.box(_submissionsBox).clear();
      await Hive.box(_quizzesBox).clear();
      await Hive.box(_materialsBox).clear();
      await Hive.box(_announcementsBox).clear();
      debugPrint('🗑️ Cleared all offline cache');
    } catch (e) {
      debugPrint('❌ Error clearing cache: $e');
    }
  }
}