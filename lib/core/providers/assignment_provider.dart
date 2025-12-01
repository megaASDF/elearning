import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/assignment_model.dart';

class AssignmentProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<AssignmentModel> _assignments = [];
  AssignmentModel? _selectedAssignment;
  bool _isLoading = false;
  String? _error;

  List<AssignmentModel> get assignments => _assignments;
  AssignmentModel? get selectedAssignment => _selectedAssignment;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadAssignments(String courseId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('assignments')
          .where('courseId', isEqualTo: courseId)
          .get();

      _assignments = snapshot.docs.map((doc) {
        final data = doc.data();
        final now = DateTime.now();
        
        return AssignmentModel.fromJson({
          'id': doc.id,
          'courseId': data['courseId'] ?? '',
          'groupIds': data['groupIds'] ?? [],
          'title': data['title'] ?? '',
          'description': data['description'] ??  '',
          'attachments': data['attachments'] ?? [],
          'startDate': (data['startDate'] as Timestamp?)?. toDate(). toIso8601String() ??  now.toIso8601String(),
          'deadline': (data['deadline'] as Timestamp?)?. toDate().toIso8601String() ?? now.add(Duration(days: 7)).toIso8601String(),
          'lateDeadline': (data['lateDeadline'] as Timestamp?)?.toDate().toIso8601String(),
          'allowLateSubmission': data['allowLateSubmission'] ?? false,
          'maxAttempts': data['maxAttempts'] ?? 1,
          'allowedFileFormats': data['allowedFileFormats'] ?? ['pdf'],
          'maxFileSizeMB': (data['maxFileSizeMB'] ?? 10).toDouble(),
          'createdAt': (data['createdAt'] as Timestamp?)?.toDate().toIso8601String() ?? now. toIso8601String(),
          'updatedAt': (data['updatedAt'] as Timestamp?)?.toDate().toIso8601String() ?? now.toIso8601String(),
        });
      }).toList();

      // Sort in memory
      _assignments.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      debugPrint('✅ Loaded ${_assignments.length} assignments');
      for (var a in _assignments) {
        debugPrint('  - ${a.title}');
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('Error loading assignments: $e');
    }
  }

  Future<void> createAssignment(String courseId, String title, String description, {String? instructions, String? maxPoints}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final now = DateTime.now();
      await _firestore. collection('assignments').add({
        'courseId': courseId,
        'groupIds': [],
        'title': title,
        'description': description,
        'attachments': [],
        'startDate': Timestamp.fromDate(now),
        'deadline': Timestamp.fromDate(now.add(Duration(days: 7))),
        'lateDeadline': null,
        'allowLateSubmission': false,
        'maxAttempts': 1,
        'allowedFileFormats': ['pdf', 'doc', 'docx'],
        'maxFileSizeMB': 10,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await loadAssignments(courseId);
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('Error creating assignment: $e');
    }
  }

  Future<void> updateAssignment(String id, String courseId, String title, String description, {String? instructions, String? maxPoints}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firestore.collection('assignments').doc(id).update({
        'title': title,
        'description': description,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await loadAssignments(courseId);
    } catch (e) {
      _error = e. toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('Error updating assignment: $e');
    }
  }

  Future<void> deleteAssignment(String id, String courseId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firestore. collection('assignments').doc(id). delete();

      final submissions = await _firestore
          . collection('submissions')
          .where('assignmentId', isEqualTo: id)
          .get();

      for (var doc in submissions.docs) {
        await doc.reference.delete();
      }

      await loadAssignments(courseId);
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('Error deleting assignment: $e');
    }
  }

  void setSelectedAssignment(AssignmentModel assignment) {
    _selectedAssignment = assignment;
    notifyListeners();
  }

  void clearSelectedAssignment() {
    _selectedAssignment = null;
    notifyListeners();
  }
}