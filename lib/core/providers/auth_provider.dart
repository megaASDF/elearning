import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  String? _error;
  
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isInstructor => _user?.role == 'instructor';
  bool get isLoading => _isLoading;
  String? get error => _error;

  AuthProvider() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    _auth.authStateChanges().listen((User? firebaseUser) async {
      if (firebaseUser != null) {
        await _loadUserData(firebaseUser. uid);
      } else {
        _user = null;
        notifyListeners();
      }
    });
  }

  Future<void> _loadUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      
      if (doc.exists) {
        final data = doc.data()!;
        _user = UserModel.fromJson({
          'id': doc.id,
          ... data,
          'createdAt': (data['createdAt'] as Timestamp?)?.toDate(). toIso8601String() ?? DateTime.now().toIso8601String(),
        });
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Special handling for admin
      if (username == 'admin' && password == 'admin123') {
        try {
          // Try to sign in first
          await _auth.signInWithEmailAndPassword(
            email: 'admin@fit.edu',
            password: 'admin123',
          );
        } catch (e) {
          // If sign in fails, create the admin account
          debugPrint('Creating admin account...');
          final userCred = await _auth.createUserWithEmailAndPassword(
            email: 'admin@fit.edu',
            password: 'admin123',
          );

          // Create admin document in Firestore
          await _firestore.collection('users').doc(userCred.user! .uid).set({
            'username': 'admin',
            'displayName': 'Administrator',
            'email': 'admin@fit.edu',
            'role': 'instructor',
            'createdAt': FieldValue.serverTimestamp(),
          });
        }

        // Load admin user data
        final currentUser = _auth.currentUser;
        if (currentUser != null) {
          await _loadUserData(currentUser.uid);
          _isLoading = false;
          notifyListeners();
          return true;
        }
        
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Regular user login
      final querySnapshot = await _firestore
          .collection('users')
          . where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (querySnapshot.docs. isEmpty) {
        throw Exception('User not found');
      }

      final userDoc = querySnapshot.docs.first;
      final email = userDoc. data()['email'];

      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _loadUserData(userDoc. id);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('Login error: $e');
      return false;
    }
  }

  Future<void> signUp(String email, String password, String displayName, String role) async {
  _isLoading = true;
  _error = null;
  notifyListeners();

  try {
    // Create Firebase Auth user
    final userCred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Create user document in Firestore
    await _firestore.collection('users').doc(userCred.user!.uid).set({
      'email': email,
      'displayName': displayName,
      'role': role,
      'username': email.split('@')[0], // Generate username from email
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Load user data
    await _loadUserData(userCred.user!.uid);

    _isLoading = false;
    notifyListeners();
  } catch (e) {
    _error = e.toString();
    _isLoading = false;
    notifyListeners();
    debugPrint('Error signing up: $e');
    rethrow;
  }
}

  Future<void> signOut() async {
  await _auth.signOut();
  _user = null;
  notifyListeners();
}

  Future<void> logout() async {
    await _auth.signOut();
    _user = null;
    notifyListeners();
  }
}