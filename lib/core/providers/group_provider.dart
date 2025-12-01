import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/group_model.dart';

class GroupProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<GroupModel> _groups = [];
  GroupModel? _selectedGroup;
  bool _isLoading = false;
  String?  _error;

  List<GroupModel> get groups => _groups;
  GroupModel? get selectedGroup => _selectedGroup;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadGroups(String courseId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('groups')
          .where('courseId', isEqualTo: courseId)
          .get();

      _groups = snapshot.docs.map((doc) {
        final data = doc.data();
        return GroupModel.fromJson({
          'id': doc.id,
          ...data,
          'studentCount': (data['studentIds'] as List?)?.length ?? 0,
          'createdAt': (data['createdAt'] as Timestamp?)?.toDate().toIso8601String() ?? DateTime.now().toIso8601String(),
        });
      }).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('Error loading groups: $e');
    }
  }

  Future<void> createGroup(GroupModel group) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firestore.collection('groups').add({
        'courseId': group.courseId,
        'name': group.name,
        'description': group.description,
        'maxStudents': group.maxStudents,
        'studentIds': [],
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update course group count
      await _firestore. collection('courses').doc(group. courseId).update({
        'groupCount': FieldValue.increment(1),
      });

      await loadGroups(group.courseId);
    } catch (e) {
      _error = e. toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('Error creating group: $e');
    }
  }

  Future<void> updateGroup(String id, GroupModel group) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firestore.collection('groups').doc(id).update({
        'name': group.name,
        'description': group.description,
        'maxStudents': group.maxStudents,
      });

      await loadGroups(group.courseId);
    } catch (e) {
      _error = e. toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('Error updating group: $e');
    }
  }

  Future<void> deleteGroup(String id, String courseId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firestore. collection('groups').doc(id). delete();

      // Update course group count
      await _firestore.collection('courses').doc(courseId).update({
        'groupCount': FieldValue.increment(-1),
      });

      await loadGroups(courseId);
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('Error deleting group: $e');
    }
  }

  Future<void> enrollStudent(String groupId, String studentId, String courseId) async {
    try {
      // Add student to group
      await _firestore.collection('groups').doc(groupId).update({
        'studentIds': FieldValue.arrayUnion([studentId]),
      });

      // Create enrollment record
      await _firestore.collection('enrollments').add({
        'studentId': studentId,
        'groupId': groupId,
        'courseId': courseId,
        'enrolledAt': FieldValue.serverTimestamp(),
      });

      // Update course student count
      await _firestore. collection('courses').doc(courseId).update({
        'studentCount': FieldValue.increment(1),
      });

      await loadGroups(courseId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      debugPrint('Error enrolling student: $e');
    }
  }

  Future<void> removeStudent(String groupId, String studentId, String courseId) async {
    try {
      // Remove student from group
      await _firestore. collection('groups').doc(groupId).update({
        'studentIds': FieldValue.arrayRemove([studentId]),
      });

      // Delete enrollment record
      final enrollmentQuery = await _firestore
          .collection('enrollments')
          .where('studentId', isEqualTo: studentId)
          .where('groupId', isEqualTo: groupId)
          .get();

      for (var doc in enrollmentQuery.docs) {
        await doc.reference.delete();
      }

      // Update course student count
      await _firestore.collection('courses').doc(courseId).update({
        'studentCount': FieldValue.increment(-1),
      });

      await loadGroups(courseId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      debugPrint('Error removing student: $e');
    }
  }

  void setSelectedGroup(GroupModel group) {
    _selectedGroup = group;
    notifyListeners();
  }

  void clearSelectedGroup() {
    _selectedGroup = null;
    notifyListeners();
  }
}