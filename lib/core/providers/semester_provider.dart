import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/semester_model.dart';

class SemesterProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<SemesterModel> _semesters = [];
  SemesterModel? _currentSemester;
  bool _isLoading = false;
  String? _error;

  List<SemesterModel> get semesters => _semesters;
  SemesterModel? get currentSemester => _currentSemester;
  bool get isLoading => _isLoading;
  String? get error => _error;

  SemesterProvider() {
    loadSemesters();
  }

  Future<void> loadSemesters() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('semesters')
          .orderBy('startDate', descending: true)
          .get();

      _semesters = snapshot.docs.map((doc) {
        final data = doc.data();
        return SemesterModel. fromJson({
          'id': doc.id,
          ... data,
          'startDate': (data['startDate'] as Timestamp). toDate(). toIso8601String(),
          'endDate': (data['endDate'] as Timestamp).toDate().toIso8601String(),
          'createdAt': (data['createdAt'] as Timestamp?)?.toDate(). toIso8601String() ??  DateTime.now().toIso8601String(),
        });
      }).toList();

      // Set current semester
      if (_semesters.isNotEmpty) {
        _currentSemester = _semesters.firstWhere(
          (s) => s.isCurrent,
          orElse: () => _semesters. first,
        );
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('Error loading semesters: $e');
    }
  }

  Future<void> createSemester(SemesterModel semester) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final docRef = await _firestore. collection('semesters').add({
        'code': semester.code,
        'name': semester.name,
        'startDate': Timestamp.fromDate(semester.startDate),
        'endDate': Timestamp. fromDate(semester.endDate),
        'isCurrent': semester.isCurrent,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // If this is marked as current, unmark others
      if (semester.isCurrent) {
        final batch = _firestore.batch();
        for (var s in _semesters. where((s) => s.isCurrent)) {
          batch. update(_firestore.collection('semesters').doc(s.id), {'isCurrent': false});
        }
        await batch.commit();
      }

      await loadSemesters();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('Error creating semester: $e');
    }
  }

  Future<void> updateSemester(String id, SemesterModel semester) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firestore.collection('semesters').doc(id).update({
        'code': semester.code,
        'name': semester.name,
        'startDate': Timestamp.fromDate(semester.startDate),
        'endDate': Timestamp. fromDate(semester.endDate),
        'isCurrent': semester.isCurrent,
      });

      // If this is marked as current, unmark others
      if (semester.isCurrent) {
        final batch = _firestore.batch();
        for (var s in _semesters.where((s) => s.isCurrent && s.id != id)) {
          batch.update(_firestore. collection('semesters').doc(s.id), {'isCurrent': false});
        }
        await batch.commit();
      }

      await loadSemesters();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('Error updating semester: $e');
    }
  }

  Future<void> deleteSemester(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firestore.collection('semesters').doc(id). delete();
      await loadSemesters();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('Error deleting semester: $e');
    }
  }

  void setCurrentSemester(SemesterModel semester) {
    _currentSemester = semester;
    notifyListeners();
  }
}