import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/course_model.dart';

class CourseProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<CourseModel> _courses = [];
  CourseModel? _selectedCourse;
  bool _isLoading = false;
  String? _error;

  List<CourseModel> get courses => _courses;
  CourseModel? get selectedCourse => _selectedCourse;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadCourses(String semesterId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('courses')
          .where('semesterId', isEqualTo: semesterId)
          .get();

      _courses = snapshot.docs.map((doc) {
        final data = doc.data();
        return CourseModel.fromJson({
          'id': doc.id,
          ... data,
          'createdAt': (data['createdAt'] as Timestamp?)?.toDate(). toIso8601String() ?? DateTime.now().toIso8601String(),
        });
      }).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('Error loading courses: $e');
    }
  }


  Future<void> loadEnrolledCourses(String semesterId, String studentId) async {
  _isLoading = true;
  _error = null;
  notifyListeners();

  try {
    // Get student's enrollments
    final enrollmentsSnapshot = await _firestore
        . collection('enrollments')
        .where('studentId', isEqualTo: studentId)
        .get();

    // Get course IDs from enrollments
    final courseIds = enrollmentsSnapshot. docs
        .map((doc) => doc.data()['courseId'] as String)
        .toSet()
        .toList();

    if (courseIds.isEmpty) {
      _courses = [];
      _isLoading = false;
      notifyListeners();
      return;
    }

    // Firestore 'in' queries are limited to 10 items
    // Split into chunks if needed
    List<CourseModel> allCourses = [];
    
    for (int i = 0; i < courseIds.length; i += 10) {
      final chunk = courseIds.skip(i).take(10).toList();
      
      final coursesSnapshot = await _firestore
          .collection('courses')
          .where('semesterId', isEqualTo: semesterId)
          .where(FieldPath.documentId, whereIn: chunk)
          .get();

      final courses = coursesSnapshot.docs. map((doc) {
        final data = doc.data();
        return CourseModel.fromJson({
          'id': doc.id,
          ...data,
          'createdAt': _convertToIsoString(data['createdAt']),
        });
      }).toList();
      
      allCourses. addAll(courses);
    }

    _courses = allCourses;
    _isLoading = false;
    notifyListeners();
  } catch (e) {
    _error = e.toString();
    _isLoading = false;
    notifyListeners();
    debugPrint('Error loading enrolled courses: $e');
  }
}

String _convertToIsoString(dynamic value) {
  if (value == null) {
    return DateTime.now().toIso8601String();
  } else if (value is Timestamp) {
    return value. toDate().toIso8601String();
  } else if (value is String) {
    return value;
  } else {
    return DateTime.now().toIso8601String();
  }
}


  Future<void> createCourse(CourseModel course) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firestore.collection('courses').add({
        'semesterId': course.semesterId,
        'code': course.code,
        'name': course.name,
        'description': course.description,
        'instructorName': course.instructorName,
        'groupCount': 0,
        'studentCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await loadCourses(course.semesterId);
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('Error creating course: $e');
    }
  }

  Future<void> updateCourse(String id, CourseModel course) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firestore. collection('courses').doc(id).update({
        'code': course.code,
        'name': course.name,
        'description': course.description,
      });

      await loadCourses(course.semesterId);
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('Error updating course: $e');
    }
  }

  Future<void> deleteCourse(String id, String semesterId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firestore.collection('courses').doc(id).delete();
      await loadCourses(semesterId);
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('Error deleting course: $e');
    }
  }

  void setSelectedCourse(CourseModel course) {
    _selectedCourse = course;
    notifyListeners();
  }

  void clearSelectedCourse() {
    _selectedCourse = null;
    notifyListeners();
  }
}