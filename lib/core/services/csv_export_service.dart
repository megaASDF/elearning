import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;
import '../models/submission_model.dart';
import '../models/quiz_attempt_model.dart';

class CsvExportService {
  static Future<String> exportSubmissions({
    required List<SubmissionModel> submissions,
    required String assignmentTitle,
  }) async {
    List<List<dynamic>> rows = [
      ['Student Name', 'Email', 'Submitted At', 'Attempt', 'Late', 'Grade', 'Feedback'],
    ];

    for (var submission in submissions) {
      rows.add([
        submission. studentName,
        submission.studentEmail,
        DateFormat('dd/MM/yyyy HH:mm').format(submission.submittedAt),
        submission.attemptNumber,
        submission.isLate ? 'Yes' : 'No',
        submission.grade?.toStringAsFixed(1) ?? 'Not graded',
        submission.feedback ?? '',
      ]);
    }

    return await _saveCsvFile(rows, 'submissions_${_sanitizeFilename(assignmentTitle)}');
  }

  static Future<String> exportQuizAttempts({
    required List<QuizAttemptModel> attempts,
    required String quizTitle,
  }) async {
    List<List<dynamic>> rows = [
      ['Student Name', 'Attempt Number', 'Started At', 'Submitted At', 'Score', 'Status'],
    ];

    for (var attempt in attempts) {
      rows. add([
        attempt.studentName,
        attempt.attemptNumber,
        DateFormat('dd/MM/yyyy HH:mm'). format(attempt.startedAt),
        attempt.submittedAt != null ? DateFormat('dd/MM/yyyy HH:mm'). format(attempt.submittedAt!) : 'In Progress',
        '${attempt.score.toStringAsFixed(1)}%',
        attempt.isCompleted ?  'Completed' : 'In Progress',
      ]);
    }

    return await _saveCsvFile(rows, 'quiz_attempts_${_sanitizeFilename(quizTitle)}');
  }

  static Future<String> exportCourseReport({
    required String courseCode,
    required String courseName,
    required List<Map<String, dynamic>> studentData,
  }) async {
    List<List<dynamic>> rows = [
      ['Student Name', 'Email', 'Assignments Submitted', 'Quizzes Completed', 'Average Grade', 'Status'],
    ];

    for (var student in studentData) {
      rows.add([
        student['name'] ?? '',
        student['email'] ?? '',
        student['assignmentsSubmitted'] ?? 0,
        student['quizzesCompleted'] ?? 0,
        student['averageGrade']?.toStringAsFixed(1) ?? 'N/A',
        student['status'] ?? 'Active',
      ]);
    }

    return await _saveCsvFile(rows, 'course_report_${_sanitizeFilename(courseCode)}');
  }

  static Future<String> _saveCsvFile(List<List<dynamic>> rows, String filename) async {
    String csv = const ListToCsvConverter().convert(rows);
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fullFilename = '${filename}_$timestamp.csv';
    
    if (kIsWeb) {
      // Web download
      final bytes = csv.codeUnits;
      final blob = html.Blob([bytes]);
      final url = html. Url.createObjectUrlFromBlob(blob);
      final anchor = html. document.createElement('a') as html.AnchorElement
        ..href = url
        .. style.display = 'none'
        ..download = fullFilename;
      html.document.body?.children.add(anchor);
      anchor.click();
      html.document.body?.children.remove(anchor);
      html. Url.revokeObjectUrl(url);
      
      return 'Downloaded: $fullFilename';
    } else {
      // Mobile/Desktop file save
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fullFilename';
      final file = File(filePath);
      await file.writeAsString(csv);
      return filePath;
    }
  }

  static String _sanitizeFilename(String filename) {
    return filename
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        . replaceAll(RegExp(r'[\s]+'), '_')
        .toLowerCase();
  }
}