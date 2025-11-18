import 'package:flutter/material.dart';
import '../models/course_model.dart';
import '../services/api_service.dart';

class CourseProvider with ChangeNotifier {
  List<CourseModel> _courses = [];
  bool _isLoading = false;

  List<CourseModel> get courses => _courses;
  bool get isLoading => _isLoading;

  Future<void> loadCourses(String semesterId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final apiService = ApiService();
      final data = await apiService.getCourses(semesterId);
      _courses = data.map((json) => CourseModel.fromJson(json)).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearCourses() {
    _courses = [];
    notifyListeners();
  }
}