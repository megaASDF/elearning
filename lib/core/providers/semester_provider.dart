import 'package:flutter/material.dart';
import '../models/semester_model.dart';
import '../services/api_service.dart';

class SemesterProvider with ChangeNotifier {
  List<SemesterModel> _semesters = [];
  SemesterModel? _currentSemester;
  bool _isLoading = false;

  List<SemesterModel> get semesters => _semesters;
  SemesterModel? get currentSemester => _currentSemester;
  bool get isLoading => _isLoading;

  Future<void> loadSemesters() async {
    _isLoading = true;
    notifyListeners();

    try {
      final apiService = ApiService();
      final data = await apiService.getSemesters();
      _semesters = data.map((json) => SemesterModel.fromJson(json)).toList();
      
      // Set current semester
      _currentSemester = _semesters.firstWhere(
        (s) => s.isCurrent,
        orElse: () => _semesters.isNotEmpty ? _semesters.first : _semesters.first,
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setCurrentSemester(SemesterModel semester) {
    _currentSemester = semester;
    notifyListeners();
  }
}