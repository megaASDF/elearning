import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class StudentProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<UserModel> _students = [];
  bool _isLoading = false;
  String? _error;

  List<UserModel> get students => _students;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadAllStudents() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      QuerySnapshot snapshot;
      try {
        // 1. Try Server (Timeout after 5 seconds)
        snapshot = await _firestore
            .collection('users')
            .where('role', isEqualTo: 'student')
            .get(const GetOptions(source: Source.server))
            .timeout(const Duration(seconds: 5));
      } catch (e) {
        // 2. Timeout or Offline -> Load from Cache
        debugPrint('Offline/Timeout: Loading all students from cache');
        snapshot = await _firestore
            .collection('users')
            .where('role', isEqualTo: 'student')
            .get(const GetOptions(source: Source.cache));
      }

      _students = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return UserModel.fromJson({
          'id': doc.id,
          ...data,
          'createdAt': (data['createdAt'] as Timestamp?)
                  ?.toDate()
                  .toIso8601String() ??
              DateTime.now().toIso8601String(),
        });
      }).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('Error loading students: $e');
    }
  }

  Future<void> loadStudentsByCourse(String courseId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Step A: Enrollments (Timeout Enabled)
      QuerySnapshot enrollmentSnapshot;
      try {
        enrollmentSnapshot = await _firestore
            .collection('enrollments')
            .where('courseId', isEqualTo: courseId)
            .get(const GetOptions(source: Source.server))
            .timeout(const Duration(seconds: 5));
      } catch (e) {
        enrollmentSnapshot = await _firestore
            .collection('enrollments')
            .where('courseId', isEqualTo: courseId)
            .get(const GetOptions(source: Source.cache));
      }

      final studentIds = enrollmentSnapshot.docs
          .map((doc) =>
              (doc.data() as Map<String, dynamic>)['studentId'] as String)
          .toSet()
          .toList();

      if (studentIds.isEmpty) {
        _students = [];
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Step B: Users (Timeout Enabled)
      QuerySnapshot studentSnapshot;
      try {
        studentSnapshot = await _firestore
            .collection('users')
            .where(FieldPath.documentId, whereIn: studentIds)
            .get(const GetOptions(source: Source.server))
            .timeout(const Duration(seconds: 5));
      } catch (e) {
        debugPrint('Offline/Timeout: Loading student profiles from cache');
        studentSnapshot = await _firestore
            .collection('users')
            .where(FieldPath.documentId, whereIn: studentIds)
            .get(const GetOptions(source: Source.cache));
      }

      _students = studentSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return UserModel.fromJson({
          'id': doc.id,
          ...data,
          'createdAt': (data['createdAt'] as Timestamp?)
                  ?.toDate()
                  .toIso8601String() ??
              DateTime.now().toIso8601String(),
        });
      }).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('Error loading students by course: $e');
    }
  }

  Future<void> loadStudentsByGroup(String groupId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Step A: Group Info (Timeout Enabled)
      DocumentSnapshot groupDoc;
      try {
        groupDoc = await _firestore
            .collection('groups')
            .doc(groupId)
            .get(const GetOptions(source: Source.server))
            .timeout(const Duration(seconds: 5));
      } catch (e) {
        groupDoc = await _firestore
            .collection('groups')
            .doc(groupId)
            .get(const GetOptions(source: Source.cache));
      }

      if (!groupDoc.exists) {
        _students = [];
        _isLoading = false;
        notifyListeners();
        return;
      }

      final studentIds =
          ((groupDoc.data() as Map<String, dynamic>)['studentIds'] as List?)
                  ?.cast<String>() ??
              [];

      if (studentIds.isEmpty) {
        _students = [];
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Step B: Batch Fetch Users (Timeout Enabled)
      _students = [];
      for (int i = 0; i < studentIds.length; i += 10) {
        final batch = studentIds.skip(i).take(10).toList();
        QuerySnapshot snapshot;
        try {
          snapshot = await _firestore
              .collection('users')
              .where(FieldPath.documentId, whereIn: batch)
              .get(const GetOptions(source: Source.server))
              .timeout(const Duration(seconds: 5));
        } catch (e) {
          snapshot = await _firestore
              .collection('users')
              .where(FieldPath.documentId, whereIn: batch)
              .get(const GetOptions(source: Source.cache));
        }

        _students.addAll(snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return UserModel.fromJson({
            'id': doc.id,
            ...data,
            'createdAt': (data['createdAt'] as Timestamp?)
                    ?.toDate()
                    .toIso8601String() ??
                DateTime.now().toIso8601String(),
          });
        }));
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('Error loading students by group: $e');
    }
  }

  Future<void> createStudent(String username, String email, String displayName,
      String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Store current user
      final currentUser = _auth.currentUser;

      // Create user in Firebase Auth
      final userCred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user document in Firestore
      await _firestore.collection('users').doc(userCred.user!.uid).set({
        'username': username,
        'email': email,
        'displayName': displayName,
        'role': 'student',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Sign out the newly created student
      await _auth.signOut();

      // Sign back in as the instructor (this is the workaround)
      // You'll need to handle this in the UI by re-authenticating

      debugPrint('✅ Student created: $displayName');

      await loadAllStudents();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('Error creating student: $e');
      rethrow;
    }
  }

  Future<void> deleteStudent(String studentId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Delete enrollments
      final enrollments = await _firestore
          .collection('enrollments')
          .where('studentId', isEqualTo: studentId)
          .get();

      for (var doc in enrollments.docs) {
        await doc.reference.delete();
      }

      // Remove from groups
      final groups = await _firestore
          .collection('groups')
          .where('studentIds', arrayContains: studentId)
          .get();

      for (var doc in groups.docs) {
        await doc.reference.update({
          'studentIds': FieldValue.arrayRemove([studentId]),
        });
      }

      // Delete user document
      await _firestore.collection('users').doc(studentId).delete();

      // Note: Can't delete from Firebase Auth without being logged in as that user
      // In production, use Firebase Admin SDK on backend

      await loadAllStudents();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('Error deleting student: $e');
    }
  }
}