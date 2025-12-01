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

  Future<void> loadAnnouncements(String courseId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('announcements')
          .where('courseId', isEqualTo: courseId)
          .orderBy('createdAt', descending: true)
          .get();

      _announcements = snapshot.docs.map((doc) {
        final data = doc.data();
        return AnnouncementModel.fromJson({
          'id': doc.id,
          ...data,
          'createdAt':
              (data['createdAt'] as Timestamp?)?.toDate().toIso8601String() ??
                  DateTime.now().toIso8601String(),
        });
      }).toList();

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
    await _firestore. collection('announcements').add({
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
