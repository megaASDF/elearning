import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'database_service.dart';

class OfflineSyncService {
  static final OfflineSyncService instance = OfflineSyncService._internal();
  OfflineSyncService._internal();

  // Sync courses to offline database
  Future<void> syncCourses(List<Map<String, dynamic>> courses) async {
    final db = await DatabaseService.instance.database;
    
    await db.delete('courses'); // Clear old data
    
    for (var course in courses) {
      await db.insert(
        'courses',
        {
          'id': course['id'],
          'name': course['name'],
          'code': course['code'],
          'description': course['description'],
          'instructorName': course['instructorName'],
          'data': course. toString(), // Store full JSON as string
          'lastSync': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  // Sync assignments to offline database
  Future<void> syncAssignments(String courseId, List<Map<String, dynamic>> assignments) async {
    final db = await DatabaseService. instance.database;
    
    await db.delete('assignments', where: 'courseId = ? ', whereArgs: [courseId]);
    
    for (var assignment in assignments) {
      await db.insert(
        'assignments',
        {
          'id': assignment['id'],
          'courseId': courseId,
          'title': assignment['title'],
          'description': assignment['description'],
          'deadline': assignment['deadline'],
          'data': assignment.toString(),
          'lastSync': DateTime. now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  // Sync announcements
  Future<void> syncAnnouncements(String courseId, List<Map<String, dynamic>> announcements) async {
    final db = await DatabaseService.instance.database;
    
    await db.delete('announcements', where: 'courseId = ?', whereArgs: [courseId]);
    
    for (var announcement in announcements) {
      await db.insert(
        'announcements',
        {
          'id': announcement['id'],
          'courseId': courseId,
          'title': announcement['title'],
          'content': announcement['content'],
          'data': announcement.toString(),
          'lastSync': DateTime.now(). toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  // Get offline courses
  Future<List<Map<String, dynamic>>> getOfflineCourses() async {
    final db = await DatabaseService.instance.database;
    return await db.query('courses', orderBy: 'lastSync DESC');
  }

  // Get offline assignments
  Future<List<Map<String, dynamic>>> getOfflineAssignments(String courseId) async {
    final db = await DatabaseService.instance.database;
    return await db.query(
      'assignments',
      where: 'courseId = ?',
      whereArgs: [courseId],
      orderBy: 'deadline ASC',
    );
  }

  // Get offline announcements
  Future<List<Map<String, dynamic>>> getOfflineAnnouncements(String courseId) async {
    final db = await DatabaseService.instance.database;
    return await db.query(
      'announcements',
      where: 'courseId = ?',
      whereArgs: [courseId],
      orderBy: 'lastSync DESC',
    );
  }

  // Clear all offline data
  Future<void> clearOfflineData() async {
    final db = await DatabaseService.instance.database;
    await db. delete('courses');
    await db.delete('assignments');
    await db.delete('announcements');
  }
}