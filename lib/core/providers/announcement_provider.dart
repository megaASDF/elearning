import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/announcement_model.dart';

class AnnouncementProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<AnnouncementModel> _announcements = [];
  bool _isLoading = false;
  String? _error;

  List<AnnouncementModel> get announcements => _announcements;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ✅ UPDATED: Now accepts optional studentId for group filtering
  Future<void> loadAnnouncements(String courseId, {String? studentId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      QuerySnapshot snapshot;

      try {
        // 1. Try Server (Timeout after 5 seconds for Web)
        snapshot = await _firestore
            .collection('announcements')
            .where('courseId', isEqualTo: courseId)
            .orderBy('createdAt', descending: true)
            .get(const GetOptions(source: Source.server))
            .timeout(const Duration(seconds: 5));
      } catch (e) {
        // 2. Timeout or Offline -> Load from Cache
        debugPrint('Offline/Timeout: Loading announcements from cache');
        snapshot = await _firestore
            .collection('announcements')
            .where('courseId', isEqualTo: courseId)
            .orderBy('createdAt', descending: true)
            .get(const GetOptions(source: Source.cache));
      }

      var loadedAnnouncements = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return AnnouncementModel.fromJson({
          'id': doc.id,
          ...data,
          'createdAt':
              (data['createdAt'] as Timestamp?)?.toDate().toIso8601String() ??
                  DateTime.now().toIso8601String(),
        });
      }).toList();

      // 🛑 GROUP FILTERING LOGIC 🛑
      if (studentId != null) {
        // A. Find student's group in this course
        final enrollmentQuery = await _firestore
            .collection('enrollments')
            .where('courseId', isEqualTo: courseId)
            .where('studentId', isEqualTo: studentId)
            .get(const GetOptions(source: Source.cache));

        String? myGroupId;
        if (enrollmentQuery.docs.isNotEmpty) {
          final data = enrollmentQuery.docs.first.data();
          if (data.containsKey('groupId')) {
            myGroupId = data['groupId'];
          }
        }

        // B. Filter the list
        loadedAnnouncements = loadedAnnouncements.where((announcement) {
          // 1. If groupIds is empty/null, it is for EVERYONE
          if (announcement.groupIds == null || announcement.groupIds!.isEmpty) {
            return true;
          }
          // 2. If student has no group, they only see public ones
          if (myGroupId == null) return false;

          // 3. Check if announcement is for the student's group
          return announcement.groupIds!.contains(myGroupId);
        }).toList();
      }

      _announcements = loadedAnnouncements;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('Error loading announcements: $e');
    }
  }

  Future<void> createAnnouncement(
    String courseId,
    String title,
    String content,
    String authorName,
    List<String> attachmentUrls,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firestore.collection('announcements').add({
        'courseId': courseId,
        'title': title,
        'content': content,
        'authorName': authorName,
        'attachmentUrls': attachmentUrls,
        'groupIds': [], // All groups by default
        'createdAt': FieldValue.serverTimestamp(),
        'viewCount': 0,
        'commentCount': 0,
      });

      await loadAnnouncements(courseId);
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('Error creating announcement: $e');
    }
  }

  Future<void> updateAnnouncement(
      String id, String courseId, String title, String content) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firestore.collection('announcements').doc(id).update({
        'title': title,
        'content': content,
      });

      await loadAnnouncements(courseId);
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('Error updating announcement: $e');
    }
  }

  Future<void> deleteAnnouncement(String id, String courseId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firestore.collection('announcements').doc(id).delete();
      await loadAnnouncements(courseId);
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('Error deleting announcement: $e');
    }
  }
}