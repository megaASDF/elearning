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
      // ✅ FIX: Sorted by startDate so the dropdown is ordered logically
      final snapshot = await _firestore
          .collection('semesters')
          .orderBy('startDate', descending: true) 
          .get();

      _semesters = snapshot.docs.map((doc) {
        final data = doc.data();
        return SemesterModel.fromJson({
          'id': doc.id,
          ...data,
          'startDate': (data['startDate'] as Timestamp).toDate().toIso8601String(),
          'endDate': (data['endDate'] as Timestamp).toDate().toIso8601String(),
          'createdAt': (data['createdAt'] as Timestamp?)?.toDate().toIso8601String() ?? DateTime.now().toIso8601String(),
        });
      }).toList();

      // Set current semester
      if (_semesters.isNotEmpty) {
        _currentSemester = _semesters.firstWhere(
          (s) => s.isCurrent,
          orElse: () => _semesters.first,
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

  // ✅ FIX: Uses Batch Write to ensure only ONE semester is current
  Future<void> createSemester(SemesterModel semester) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final batch = _firestore.batch();

      // 1. If new semester is current, mark ALL others as false first
      if (semester.isCurrent) {
        final allSemesters = await _firestore.collection('semesters').get();
        for (var doc in allSemesters.docs) {
          batch.update(doc.reference, {'isCurrent': false});
        }
      }

      // 2. Create the new semester
      final newDocRef = _firestore.collection('semesters').doc();
      batch.set(newDocRef, {
        'code': semester.code,
        'name': semester.name,
        'startDate': Timestamp.fromDate(semester.startDate),
        'endDate': Timestamp.fromDate(semester.endDate),
        'isCurrent': semester.isCurrent,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit(); // 3. Commit everything atomically
      await loadSemesters(); // 4. Refresh local state

    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('Error creating semester: $e');
    }
  }

  // ✅ FIX: Uses Batch Write for updates too
  Future<void> updateSemester(String id, SemesterModel semester) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final batch = _firestore.batch();

      // 1. If we are setting this one to current, unset everyone else
      if (semester.isCurrent) {
        // We can use our local list _semesters to find IDs to update, saving a read
        for (var s in _semesters) {
          if (s.id != id && s.isCurrent) {
             batch.update(_firestore.collection('semesters').doc(s.id), {'isCurrent': false});
          }
        }
      }

      // 2. Update the target semester
      batch.update(_firestore.collection('semesters').doc(id), {
        'code': semester.code,
        'name': semester.name,
        'startDate': Timestamp.fromDate(semester.startDate),
        'endDate': Timestamp.fromDate(semester.endDate),
        'isCurrent': semester.isCurrent,
      });

      await batch.commit();
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
      await _firestore.collection('semesters').doc(id).delete();
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