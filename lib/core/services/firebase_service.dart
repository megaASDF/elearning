import 'dart:typed_data'; // ADD THIS
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseService {
  static final FirebaseService instance = FirebaseService._internal();
  FirebaseService._internal();

  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;

  // Auth Methods
  Future<UserCredential> login(String email, String password) async {
    return await auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> register(String email, String password) async {
    return await auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> logout() async {
    await auth.signOut();
  }

  User? get currentUser => auth.currentUser;

  // Firestore Methods
  Future<void> createDocument(String collection, String docId, Map<String, dynamic> data) async {
    await firestore.collection(collection).doc(docId).set(data);
  }

  Future<DocumentSnapshot> getDocument(String collection, String docId) async {
    return await firestore.collection(collection). doc(docId).get();
  }

  Future<QuerySnapshot> getCollection(String collection) async {
    return await firestore.collection(collection).get();
  }

  Future<void> updateDocument(String collection, String docId, Map<String, dynamic> data) async {
    await firestore.collection(collection).doc(docId).update(data);
  }

  Future<void> deleteDocument(String collection, String docId) async {
    await firestore.collection(collection).doc(docId).delete();
  }

  // Storage Methods
  Future<String> uploadFile(String path, Uint8List data) async {
    final ref = storage.ref().child(path);
    await ref.putData(data);
    return await ref.getDownloadURL();
  }
}