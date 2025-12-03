import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

Future<void> testFirebaseStorage() async {
  try {
    debugPrint('🧪 Testing Firebase Storage...');
    
    final storage = FirebaseStorage.instance;
    final ref = storage.ref(). child('test/test.txt');
    
    debugPrint('📤 Uploading test file...');
    await ref.putString('Hello World'). timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw Exception('Upload timeout');
      },
    );
    
    debugPrint('✅ Upload successful!');
    
    final url = await ref.getDownloadURL();
    debugPrint('🔗 Download URL: $url');
    
    debugPrint('🗑️ Deleting test file...');
    await ref.delete();
    
    debugPrint('✅ Firebase Storage is working!');
  } catch (e) {
    debugPrint('❌ Firebase Storage test failed: $e');
  }
}