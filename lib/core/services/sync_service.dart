import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'offline_database_service.dart';
import 'api_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  bool _isSyncing = false;
  DateTime? _lastSyncTime;

  bool get isSyncing => _isSyncing;
  DateTime?  get lastSyncTime => _lastSyncTime;

  // Check if online
  Future<bool> isOnline() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  // Sync all data for a course
  Future<void> syncCourse(String courseId) async {
    if (_isSyncing) {
      debugPrint('⏳ Sync already in progress');
      return;
    }

    if (!await isOnline()) {
      debugPrint('📡 Offline - cannot sync');
      return;
    }

    _isSyncing = true;
    debugPrint('🔄 Starting sync for course $courseId');

    try {
      final apiService = ApiService();

      // Sync announcements
      try {
        final announcements = await apiService.getAnnouncements(courseId);
        await OfflineDatabaseService.saveAnnouncements(
          courseId, 
          List<Map<String, dynamic>>. from(announcements)
        );
      } catch (e) {
        debugPrint('Error syncing announcements: $e');
      }

      // Sync materials
      try {
        final materials = await apiService.getMaterials(courseId);
        await OfflineDatabaseService.saveMaterials(
          courseId, 
          List<Map<String, dynamic>>.from(materials)
        );
      } catch (e) {
        debugPrint('Error syncing materials: $e');
      }

      // Sync assignments
      try {
        final assignments = await apiService. getAssignments(courseId);
        await OfflineDatabaseService.saveAssignments(
          courseId, 
          List<Map<String, dynamic>>. from(assignments)
        );
        
        // Sync submissions for each assignment
        for (var assignment in assignments) {
          try {
            final submissions = await apiService.getSubmissions(assignment['id']);
            await OfflineDatabaseService.saveSubmissions(
              assignment['id'], 
              List<Map<String, dynamic>>.from(submissions)
            );
          } catch (e) {
            debugPrint('Error syncing submissions for assignment ${assignment['id']}: $e');
          }
        }
      } catch (e) {
        debugPrint('Error syncing assignments: $e');
      }

      // Sync quizzes
      try {
        final quizzes = await apiService.getQuizzes(courseId);
        await OfflineDatabaseService.saveQuizzes(
          courseId, 
          List<Map<String, dynamic>>.from(quizzes)
        );
        
        // Sync attempts for each quiz
        for (var quiz in quizzes) {
          try {
            final attempts = await apiService.getQuizAttempts(quiz['id']);
            await OfflineDatabaseService.saveQuizAttempts(
              quiz['id'], 
              List<Map<String, dynamic>>.from(attempts)
            );
          } catch (e) {
            debugPrint('Error syncing attempts for quiz ${quiz['id']}: $e');
          }
        }
      } catch (e) {
        debugPrint('Error syncing quizzes: $e');
      }

      _lastSyncTime = DateTime.now();
      debugPrint('✅ Sync completed for course $courseId');
    } catch (e) {
      debugPrint('❌ Sync failed: $e');
    } finally {
      _isSyncing = false;
    }
  }

  // Sync courses for a semester
  Future<void> syncSemester(String semesterId) async {
    if (_isSyncing) {
      debugPrint('⏳ Sync already in progress');
      return;
    }

    if (!await isOnline()) {
      debugPrint('📡 Offline - cannot sync');
      return;
    }

    _isSyncing = true;
    debugPrint('🔄 Starting sync for semester $semesterId');

    try {
      final apiService = ApiService();
      
      // Sync courses
      final coursesData = await apiService.getCoursesBySemester(semesterId);
      await OfflineDatabaseService.saveCourses(
        semesterId, 
        List<Map<String, dynamic>>.from(coursesData)
      );

      _lastSyncTime = DateTime.now();
      debugPrint('✅ Sync completed for semester $semesterId');
    } catch (e) {
      debugPrint('❌ Sync failed: $e');
    } finally {
      _isSyncing = false;
    }
  }

  // Background sync (call periodically)
  Future<void> backgroundSync(String courseId) async {
    if (! await isOnline()) return;
    
    final lastSync = OfflineDatabaseService.getLastSync('course_$courseId');
    if (lastSync != null) {
      final lastSyncTime = DateTime.parse(lastSync);
      final now = DateTime.now();
      
      // Only sync if last sync was more than 15 minutes ago
      if (now.difference(lastSyncTime). inMinutes < 15) {
        debugPrint('⏭️ Skipping sync - synced recently');
        return;
      }
    }

    await syncCourse(courseId);
  }
}