import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/forum_topic_model.dart';
import '../models/forum_reply_model.dart';

class ForumProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<ForumTopicModel> _topics = [];
  List<ForumReplyModel> _replies = [];
  bool _isLoading = false;
  String? _error;

  List<ForumTopicModel> get topics => _topics;
  List<ForumReplyModel> get replies => _replies;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load Topics with Offline Support + Group Filtering
  Future<void> loadTopics(String courseId, {String? studentId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      QuerySnapshot snapshot;
      try {
        // 1. Try Server (5s Timeout)
        snapshot = await _firestore
            .collection('forum_topics')
            .where('courseId', isEqualTo: courseId)
            .orderBy('createdAt', descending: true)
            .get(const GetOptions(source: Source.server))
            .timeout(const Duration(seconds: 5));
      } catch (e) {
        // 2. Offline/Timeout Fallback
        debugPrint('Offline: Loading forum topics from cache');
        snapshot = await _firestore
            .collection('forum_topics')
            .where('courseId', isEqualTo: courseId)
            .orderBy('createdAt', descending: true)
            .get(const GetOptions(source: Source.cache));
      }

      var loadedTopics = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return ForumTopicModel.fromJson({
          'id': doc.id,
          ...data,
          // Handle timestamps safely
          'createdAt': (data['createdAt'] as Timestamp?)?.toDate().toIso8601String(),
          'updatedAt': (data['updatedAt'] as Timestamp?)?.toDate().toIso8601String(),
        });
      }).toList();

      // 🛑 GROUP FILTERING 🛑
      if (studentId != null) {
        // Check student's group in enrollment cache
        final enrollmentQuery = await _firestore
            .collection('enrollments')
            .where('courseId', isEqualTo: courseId)
            .where('studentId', isEqualTo: studentId)
            .get(const GetOptions(source: Source.cache));

        String? myGroupId;
        if (enrollmentQuery.docs.isNotEmpty) {
           final data = enrollmentQuery.docs.first.data();
           if (data is Map && data.containsKey('groupId')) {
             myGroupId = data['groupId'];
           }
        }

        loadedTopics = loadedTopics.where((topic) {
          if (topic.groupIds == null || topic.groupIds!.isEmpty) return true; // Public
          if (myGroupId == null) return false; // Student has no group
          return topic.groupIds!.contains(myGroupId); // Group Match
        }).toList();
      }

      _topics = loadedTopics;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('Error loading topics: $e');
    }
  }

  // Load Replies for a specific Topic
  Future<void> loadReplies(String topicId) async {
    _isLoading = true;
    notifyListeners();

    try {
      QuerySnapshot snapshot;
      try {
        snapshot = await _firestore
            .collection('forum_replies')
            .where('topicId', isEqualTo: topicId)
            .orderBy('createdAt', descending: false)
            .get(const GetOptions(source: Source.server))
            .timeout(const Duration(seconds: 5));
      } catch (e) {
        snapshot = await _firestore
            .collection('forum_replies')
            .where('topicId', isEqualTo: topicId)
            .orderBy('createdAt', descending: false)
            .get(const GetOptions(source: Source.cache));
      }

      _replies = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return ForumReplyModel.fromJson({
          'id': doc.id,
          ...data,
          'createdAt': (data['createdAt'] as Timestamp?)?.toDate().toIso8601String(),
        });
      }).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('Error loading replies: $e');
    }
  }

  Future<void> createTopic(String courseId, String title, String content, String authorId, String authorName, List<String>? groupIds) async {
    try {
      await _firestore.collection('forum_topics').add({
        'courseId': courseId,
        'title': title,
        'content': content,
        'authorId': authorId,
        'authorName': authorName,
        'groupIds': groupIds ?? [],
        'replyCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      // Reload is handled by UI calling loadTopics
    } catch (e) {
      debugPrint('Error creating topic: $e');
      rethrow;
    }
  }

  Future<void> createReply(String topicId, String content, String authorId, String authorName) async {
    try {
      // 1. Add Reply
      await _firestore.collection('forum_replies').add({
        'topicId': topicId,
        'content': content,
        'authorId': authorId,
        'authorName': authorName,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2. Increment Reply Count on Topic
      await _firestore.collection('forum_topics').doc(topicId).update({
        'replyCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await loadReplies(topicId);
    } catch (e) {
      debugPrint('Error creating reply: $e');
      rethrow;
    }
  }
}