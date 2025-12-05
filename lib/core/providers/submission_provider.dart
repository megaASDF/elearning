import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/submission_model.dart';
import '../services/notification_service.dart';

class SubmissionProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<SubmissionModel> _submissions = [];
  SubmissionModel? _mySubmission;
  bool _isLoading = false;
  String? _error;

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
      QuerySnapshot snapshot;
      try {
        // 1. Try Server (Timeout after 5 seconds)
        snapshot = await _firestore
            .collection('submissions')
            .where('assignmentId', isEqualTo: assignmentId)
            .get(const GetOptions(source: Source.server))
            .timeout(const Duration(seconds: 5));
      } catch (e) {
        // 2. Timeout or Offline -> Load from Cache
        debugPrint('Offline/Timeout: Loading submissions from cache');
        snapshot = await _firestore
            .collection('submissions')
            .where('assignmentId', isEqualTo: assignmentId)
            .get(const GetOptions(source: Source.cache));
      }

      _submissions = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return SubmissionModel.fromJson({
          'id': doc.id,
          'assignmentId': data['assignmentId'] ?? '',
          'studentId': data['studentId'] ?? '',
          'studentName': data['studentName'] ?? 'Unknown',
          'fileUrls': data['fileUrls'] ?? [],
          'submittedAt': (data['submittedAt'] as Timestamp?)
                  ?.toDate()
                  .toIso8601String() ??
              DateTime.now().toIso8601String(),
          'grade': data['grade'],
          'feedback': data['feedback'],
          'status': data['status'] ?? 'submitted',
          'attemptNumber': data['attemptNumber'] ?? 1,
        });
      }).toList();

      _submissions.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));

      debugPrint('✅ Loaded ${_submissions.length} submissions');

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
      QuerySnapshot snapshot;
      try {
        // 1. Try Server (Timeout after 5 seconds)
        snapshot = await _firestore
            .collection('submissions')
            .where('assignmentId', isEqualTo: assignmentId)
            .where('studentId', isEqualTo: studentId)
            .limit(1)
            .get(const GetOptions(source: Source.server))
            .timeout(const Duration(seconds: 5));
      } catch (e) {
        // 2. Timeout or Offline -> Load from Cache
        debugPrint('Offline/Timeout: Loading my submission from cache');
        snapshot = await _firestore
            .collection('submissions')
            .where('assignmentId', isEqualTo: assignmentId)
            .where('studentId', isEqualTo: studentId)
            .limit(1)
            .get(const GetOptions(source: Source.cache));
      }

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        final data = doc.data() as Map<String, dynamic>;
        _mySubmission = SubmissionModel.fromJson({
          'id': doc.id,
          'assignmentId': data['assignmentId'] ?? '',
          'studentId': data['studentId'] ?? '',
          'studentName': data['studentName'] ?? 'Unknown',
          'fileUrls': data['fileUrls'] ?? [],
          'submittedAt': (data['submittedAt'] as Timestamp?)
                  ?.toDate()
                  .toIso8601String() ??
              DateTime.now().toIso8601String(),
          'grade': data['grade'],
          'feedback': data['feedback'],
          'status': data['status'] ?? 'submitted',
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
      // 🛑 STEP 1: VALIDATION CHECK
      // Fetch the assignment details to check the deadline
      final assignmentDoc = await _firestore
          .collection('assignments')
          .doc(assignmentId)
          .get();

      if (!assignmentDoc.exists) {
        throw Exception("Assignment not found");
      }

      final data = assignmentDoc.data() as Map<String, dynamic>;
      final now = DateTime.now();
      
      // Parse dates safeley
      final deadline = (data['deadline'] as Timestamp).toDate();
      final allowLateSubmission = data['allowLateSubmission'] ?? false;
      
      DateTime? lateDeadline;
      if (data['lateDeadline'] != null) {
        lateDeadline = (data['lateDeadline'] as Timestamp).toDate();
      }

      // 🛑 STEP 2: COMPARE DATES
      // Logic: Is it past the normal deadline?
      if (now.isAfter(deadline)) {
        
        // If late submissions are NOT allowed -> BLOCK IT
        if (!allowLateSubmission) {
           throw Exception("The deadline for this assignment has passed.");
        }

        // If late submissions ARE allowed, but it's past the LATE deadline -> BLOCK IT
        if (lateDeadline != null && now.isAfter(lateDeadline)) {
           throw Exception("The late submission deadline has passed.");
        }
      }

      // Determine status (submitted vs late)
      String submissionStatus = 'submitted';
      if (now.isAfter(deadline)) {
        submissionStatus = 'late';
      }

      // ✅ STEP 3: PROCEED IF VALID
      await _firestore.collection('submissions').add({
        'assignmentId': assignmentId,
        'studentId': studentId,
        'studentName': studentName,
        'fileUrls': fileUrls,
        'submittedAt': FieldValue.serverTimestamp(),
        'grade': null,
        'feedback': null,
        'status': submissionStatus, // 'submitted' or 'late'
        'attemptNumber': 1,
      });

      // Get assignment title for notification
      final assignmentTitle = data['title'] ?? 'Assignment';

      // Send confirmation notification
      final notificationService = NotificationService();
      await notificationService.notifySubmissionReceived(
        studentId: studentId,
        assignmentTitle: assignmentTitle,
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('Error submitting assignment: $e');
      
      // Rethrow so the UI knows to show the Red SnackBar
      rethrow; 
    }
  }

  Future<void> gradeSubmission(
    String submissionId,
    String assignmentId,
    double grade,
    String? feedback,
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