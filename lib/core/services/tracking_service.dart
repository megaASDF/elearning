import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class TrackingService {
  final FirebaseFirestore _firestore = FirebaseFirestore. instance;

  // Track announcement view
  Future<void> trackAnnouncementView({
    required String announcementId,
    required String userId,
    required String userName,
  }) async {
    try {
      // Check if already viewed
      final existing = await _firestore
          . collection('announcementViews')
          .where('announcementId', isEqualTo: announcementId)
          .where('userId', isEqualTo: userId)
          .get();

      if (existing.docs.isEmpty) {
        // First time viewing
        await _firestore.collection('announcementViews').add({
          'announcementId': announcementId,
          'userId': userId,
          'userName': userName,
          'viewedAt': FieldValue.serverTimestamp(),
        });

        // Increment view count
        await _firestore
            .collection('announcements')
            . doc(announcementId)
            .update({'viewCount': FieldValue.increment(1)});

        debugPrint('✅ Tracked announcement view');
      }
    } catch (e) {
      debugPrint('❌ Error tracking view: $e');
    }
  }

  // Track announcement file download
  Future<void> trackAnnouncementDownload({
    required String announcementId,
    required String userId,
    required String userName,
    required String fileName,
  }) async {
    try {
      await _firestore.collection('announcementDownloads').add({
        'announcementId': announcementId,
        'userId': userId,
        'userName': userName,
        'fileName': fileName,
        'downloadedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Tracked file download');
    } catch (e) {
      debugPrint('❌ Error tracking download: $e');
    }
  }

  // Track material view
  Future<void> trackMaterialView({
    required String materialId,
    required String userId,
    required String userName,
  }) async {
    try {
      final existing = await _firestore
          .collection('materialViews')
          .where('materialId', isEqualTo: materialId)
          .where('userId', isEqualTo: userId)
          . get();

      if (existing. docs.isEmpty) {
        await _firestore.collection('materialViews').add({
          'materialId': materialId,
          'userId': userId,
          'userName': userName,
          'viewedAt': FieldValue.serverTimestamp(),
        });

        // Increment view count
        await _firestore
            .collection('materials')
            .doc(materialId)
            .update({'viewCount': FieldValue.increment(1)});

        debugPrint('✅ Tracked material view');
      }
    } catch (e) {
      debugPrint('❌ Error tracking material view: $e');
    }
  }

  // Track material download
  Future<void> trackMaterialDownload({
    required String materialId,
    required String userId,
    required String userName,
    required String fileName,
  }) async {
    try {
      await _firestore.collection('materialDownloads').add({
        'materialId': materialId,
        'userId': userId,
        'userName': userName,
        'fileName': fileName,
        'downloadedAt': FieldValue. serverTimestamp(),
      });

      // Increment download count
      await _firestore
          .collection('materials')
          .doc(materialId)
          .update({'downloadCount': FieldValue.increment(1)});

      debugPrint('✅ Tracked material download');
    } catch (e) {
      debugPrint('❌ Error tracking download: $e');
    }
  }

  // Get who viewed an announcement
  Future<List<Map<String, dynamic>>> getAnnouncementViewers(String announcementId) async {
    try {
      final snapshot = await _firestore
          . collection('announcementViews')
          .where('announcementId', isEqualTo: announcementId)
          .orderBy('viewedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'userId': data['userId'],
          'userName': data['userName'],
          'viewedAt': (data['viewedAt'] as Timestamp). toDate(),
        };
      }).toList();
    } catch (e) {
      debugPrint('❌ Error getting viewers: $e');
      return [];
    }
  }

  // Get who downloaded announcement files
  Future<List<Map<String, dynamic>>> getAnnouncementDownloaders(String announcementId) async {
    try {
      final snapshot = await _firestore
          .collection('announcementDownloads')
          .where('announcementId', isEqualTo: announcementId)
          .orderBy('downloadedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'userId': data['userId'],
          'userName': data['userName'],
          'fileName': data['fileName'],
          'downloadedAt': (data['downloadedAt'] as Timestamp).toDate(),
        };
      }).toList();
    } catch (e) {
      debugPrint('❌ Error getting downloaders: $e');
      return [];
    }
  }

  // Get who viewed a material
  Future<List<Map<String, dynamic>>> getMaterialViewers(String materialId) async {
    try {
      final snapshot = await _firestore
          .collection('materialViews')
          .where('materialId', isEqualTo: materialId)
          .orderBy('viewedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'userId': data['userId'],
          'userName': data['userName'],
          'viewedAt': (data['viewedAt'] as Timestamp).toDate(),
        };
      }).toList();
    } catch (e) {
      debugPrint('❌ Error getting viewers: $e');
      return [];
    }
  }

  // Get who downloaded materials
  Future<List<Map<String, dynamic>>> getMaterialDownloaders(String materialId) async {
    try {
      final snapshot = await _firestore
          . collection('materialDownloads')
          .where('materialId', isEqualTo: materialId)
          .orderBy('downloadedAt', descending: true)
          .get();

      return snapshot. docs.map((doc) {
        final data = doc.data();
        return {
          'userId': data['userId'],
          'userName': data['userName'],
          'fileName': data['fileName'],
          'downloadedAt': (data['downloadedAt'] as Timestamp).toDate(),
        };
      }).toList();
    } catch (e) {
      debugPrint('❌ Error getting downloaders: $e');
      return [];
    }
  }
}