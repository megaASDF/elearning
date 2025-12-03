import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class SemesterProtectionService {
  final FirebaseFirestore _firestore = FirebaseFirestore. instance;

  // Check if a semester is past (read-only)
  Future<bool> isSemesterPast(String semesterId) async {
    try {
      final semesterDoc = await _firestore. collection('semesters').doc(semesterId).get();
      
      if (! semesterDoc.exists) return false;
      
      final data = semesterDoc.data()!;
      final endDate = DateTime.parse(data['endDate']);
      
      return DateTime.now().isAfter(endDate);
    } catch (e) {
      debugPrint('Error checking semester: $e');
      return false;
    }
  }

  // Check if assignment is from past semester
  Future<bool> isAssignmentReadOnly(String assignmentId) async {
    try {
      final assignmentDoc = await _firestore. collection('assignments').doc(assignmentId).get();
      
      if (!assignmentDoc.exists) return false;
      
      final courseId = assignmentDoc.data()! ['courseId'];
      final courseDoc = await _firestore.collection('courses').doc(courseId). get();
      
      if (! courseDoc.exists) return false;
      
      final semesterId = courseDoc.data()!['semesterId'];
      return await isSemesterPast(semesterId);
    } catch (e) {
      debugPrint('Error checking assignment: $e');
      return false;
    }
  }

  // Check if quiz is from past semester
  Future<bool> isQuizReadOnly(String quizId) async {
    try {
      final quizDoc = await _firestore.collection('quizzes').doc(quizId).get();
      
      if (!quizDoc.exists) return false;
      
      final courseId = quizDoc. data()!['courseId'];
      final courseDoc = await _firestore.collection('courses').doc(courseId).get();
      
      if (!courseDoc.exists) return false;
      
      final semesterId = courseDoc.data()!['semesterId'];
      return await isSemesterPast(semesterId);
    } catch (e) {
      debugPrint('Error checking quiz: $e');
      return false;
    }
  }

  // Check if course is from past semester
  Future<bool> isCourseReadOnly(String courseId) async {
    try {
      final courseDoc = await _firestore.collection('courses').doc(courseId).get();
      
      if (!courseDoc.exists) return false;
      
      final semesterId = courseDoc.data()!['semesterId'];
      return await isSemesterPast(semesterId);
    } catch (e) {
      debugPrint('Error checking course: $e');
      return false;
    }
  }
}