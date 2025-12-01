import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/submission_model.dart';

class SubmissionProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<SubmissionModel> _submissions = [];
  SubmissionModel? _mySubmission;
  bool _isLoading = false;
  String?  _error;

  List<SubmissionModel> get submissions => _submissions;
  SubmissionModel? get mySubmission => _mySubmission;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load all submissions for an assignment (instructor view)
  Future<void> loadSubmissions(String assignmentId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('submissions')
          .where('assignmentId', isEqualTo: assignmentId)
          .get();

      _submissions = snapshot.docs.map((doc) {
        final data = doc.data();
        return SubmissionModel. fromJson({
          'id': doc.id,
          'assignmentId': data['assignmentId'] ?? '',
          'studentId': data['studentId'] ?? '',
          'studentName': data['studentName'] ??  'Unknown',
          'fileUrls': data['fileUrls'] ?? [],
          'submittedAt': (data['submittedAt'] as Timestamp?)?.toDate(). toIso8601String() ?? DateTime.now().toIso8601String(),
          'grade': data['grade'],
          'feedback': data['feedback'],
          'status': data['status'] ?? 'submitted',
          'attemptNumber': data['attemptNumber'] ??  1,
        });
      }).toList();

      _submissions.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));

      debugPrint('✅ Loaded ${_submissions. length} submissions');

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('Error loading submissions: $e');
    }
  }

  // Load my submission for an assignment (student view)
  Future<void> loadMySubmission(String assignmentId, String studentId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('submissions')
          .where('assignmentId', isEqualTo: assignmentId)
          .where('studentId', isEqualTo: studentId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        final data = doc.data();
        _mySubmission = SubmissionModel.fromJson({
          'id': doc.id,
          'assignmentId': data['assignmentId'] ?? '',
          'studentId': data['studentId'] ?? '',
          'studentName': data['studentName'] ?? 'Unknown',
          'fileUrls': data['fileUrls'] ??  [],
          'submittedAt': (data['submittedAt'] as Timestamp?)?.toDate().toIso8601String() ?? DateTime.now().toIso8601String(),
          'grade': data['grade'],
          'feedback': data['feedback'],
          'status': data['status'] ??  'submitted',
          'attemptNumber': data['attemptNumber'] ?? 1,
        });
      } else {
        _mySubmission = null;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('Error loading my submission: $e');
    }
  }

  // Submit an assignment
  Future<void> submitAssignment(
    String assignmentId,
    String studentId,
    String studentName,
    List<String> fileUrls,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firestore.collection('submissions').add({
        'assignmentId': assignmentId,
        'studentId': studentId,
        'studentName': studentName,
        'fileUrls': fileUrls,
        'submittedAt': FieldValue.serverTimestamp(),
        'grade': null,
        'feedback': null,
        'status': 'submitted',
        'attemptNumber': 1,
      });

      await loadMySubmission(assignmentId, studentId);

      debugPrint('✅ Assignment submitted');
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('Error submitting assignment: $e');
    }
  }

  // Grade a submission (instructor)
  Future<void> gradeSubmission(
    String submissionId,
    String assignmentId,
    double grade,
    String?  feedback,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firestore.collection('submissions').doc(submissionId).update({
        'grade': grade,
        'feedback': feedback,
        'status': 'graded',
      });

      await loadSubmissions(assignmentId);

      debugPrint('✅ Submission graded');
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('Error grading submission: $e');
    }
  }

  void clearSubmissions() {
    _submissions = [];
    _mySubmission = null;
    notifyListeners();
  }
}