import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';

class CsvImportService {
  static Future<List<Map<String, dynamic>>> parseCsv(String csvContent) async {
    try {
      final List<List<dynamic>> rows = const CsvToListConverter().convert(csvContent);
      
      if (rows.isEmpty) {
        throw Exception('CSV file is empty');
      }

      // First row is headers
      final headers = rows[0]. map((e) => e.toString().trim()).toList();
      
      // Parse remaining rows
      List<Map<String, dynamic>> data = [];
      for (int i = 1; i < rows. length; i++) {
        if (rows[i].isEmpty) continue;
        
        Map<String, dynamic> row = {};
        for (int j = 0; j < headers.length && j < rows[i].length; j++) {
          row[headers[j]] = rows[i][j]?.toString().trim() ?? '';
        }
        data.add(row);
      }
      
      return data;
    } catch (e) {
      debugPrint('Error parsing CSV: $e');
      rethrow;
    }
  }

  static String generateSampleStudentsCsv() {
    return '''username,displayName,email,studentId,department
john. doe,John Doe,john. doe@student.fit. edu,20210001,Computer Science
jane.smith,Jane Smith,jane.smith@student.fit.edu,20210002,Information Technology
mike.johnson,Mike Johnson,mike. johnson@student.fit.edu,20210003,Software Engineering
sarah.williams,Sarah Williams,sarah.williams@student.fit.edu,20210004,Data Science
david.brown,David Brown,david.brown@student.fit.edu,20210005,Computer Science''';
  }

  static String generateSampleSemestersCsv() {
    return '''code,name,startDate,endDate,isCurrent
2024-1,Spring 2024,2024-01-15,2024-05-15,false
2024-2,Fall 2024,2024-08-20,2024-12-20,false
2025-1,Spring 2025,2025-01-15,2025-05-15,true''';
  }

static String generateSampleCoursesCsv() {
    return '''code,name,description,instructorName,numberOfSessions,semesterCode
INT3123,Web Programming,Advanced web development course,Dr. Smith,15,HK1-2025
INT3120,Mobile Development,iOS and Android development,Dr. Johnson,15,HK1-2025
INT3115,Database Systems,Relational and NoSQL databases,Prof. Williams,10,HK1-2025''';
  }

  static String generateSampleGroupsCsv() {
    return '''courseCode,name,maxStudents
INT3123,Group 1,30
INT3123,Group 2,30
INT3120,Group 1,25
INT3120,Group 2,25
INT3115,Group 1,35''';
  }
}