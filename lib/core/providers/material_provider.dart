import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/material_model.dart';

class MaterialProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<MaterialModel> _materials = [];
  bool _isLoading = false;
  String? _error;

  List<MaterialModel> get materials => _materials;
  bool get isLoading => _isLoading;
  String? get error => _error;

Future<void> loadMaterials(String courseId) async {
  _isLoading = true;
  _error = null;
  notifyListeners();

  try {
    final snapshot = await _firestore
        .collection('materials')
        .where('courseId', isEqualTo: courseId)
        .orderBy('createdAt', descending: true)
        .get();

    _materials = snapshot.docs.map((doc) {
      final data = doc.data();
      return MaterialModel.fromJson({
        'id': doc.id,
        'courseId': data['courseId'] ?? courseId,
        'title': data['title'] ?? '',
        'description': data['description'] ?? '',
        'fileUrls': data['fileUrls'] ?? [],
        'links': data['links'] ?? [],
        'authorName': data['authorName'] ??  'Unknown',
        'viewCount': data['viewCount'] ??  0,
        'downloadCount': data['downloadCount'] ?? 0,
        'createdAt': _convertToIsoString(data['createdAt']),
        'updatedAt': _convertToIsoString(data['updatedAt']),
      });
    }).toList();

    _isLoading = false;
    notifyListeners();
  } catch (e) {
    _error = e. toString();
    _isLoading = false;
    notifyListeners();
    debugPrint('Error loading materials: $e');
  }
}

// Add this helper method in the provider class
String _convertToIsoString(dynamic value) {
  if (value == null) {
    return DateTime.now().toIso8601String();
  } else if (value is Timestamp) {
    return value.toDate(). toIso8601String();
  } else if (value is String) {
    return value;
  } else {
    return DateTime.now().toIso8601String();
  }
}

  Future<void> createMaterial(String courseId, String title, String description, String contentType, {String? url, String? fileName, int? fileSize}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firestore.collection('materials'). add({
        'courseId': courseId,
        'title': title,
        'description': description,
        'contentType': contentType,
        'url': url,
        'fileName': fileName,
        'fileSize': fileSize,
        'viewCount': 0,
        'downloadCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await loadMaterials(courseId);
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('Error creating material: $e');
    }
  }

  Future<void> updateMaterial(String id, String courseId, String title, String description) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firestore.collection('materials').doc(id).update({
        'title': title,
        'description': description,
      });

      await loadMaterials(courseId);
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('Error updating material: $e');
    }
  }

  Future<void> deleteMaterial(String id, String courseId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firestore. collection('materials').doc(id). delete();
      await loadMaterials(courseId);
    } catch (e) {
      _error = e. toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('Error deleting material: $e');
    }
  }

  Future<void> incrementViewCount(String id) async {
    try {
      await _firestore. collection('materials').doc(id). update({
        'viewCount': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('Error incrementing view count: $e');
    }
  }

  Future<void> incrementDownloadCount(String id) async {
    try {
      await _firestore.collection('materials'). doc(id).update({
        'downloadCount': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('Error incrementing download count: $e');
    }
  }
}