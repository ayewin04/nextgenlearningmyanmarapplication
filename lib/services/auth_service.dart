// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  User? _user;
  UserModel? _userModel;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  AuthService() {
    _auth.authStateChanges().listen((User? user) async {
      _user = user;
      if (user != null) {
        await _loadUserData(user.uid);
      } else {
        _userModel = null;
      }
      notifyListeners();
    });
  }

  Future<void> _loadUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(uid)
          .get();
      
      if (doc.exists) {
        _userModel = UserModel.fromFirestore(doc);
      } else {
        await _createUserDocument(uid);
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
    notifyListeners();
  }

  Future<void> _createUserDocument(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'email': _user?.email ?? '',
        'name': _user?.displayName ?? 'User',
        'targetLanguages': [],
        'streak': 0,
        'totalXP': 0,
        'level': 1,
        'createdAt': FieldValue.serverTimestamp(),
        'examProgress': {},
        'settings': {},
        'favourites': [],
        'wordsLearned': 0,
        'wordsPerCategory': {},
        'wordsPerLanguage': {},
        'lastPracticeDate': null,
        'unlockedAchievements': [],
        'weeklyXP': 0,
        'weeklyRank': 0,
        'dailyTasks': {},
      });
      
      await _loadUserData(uid);
    } catch (e) {
      debugPrint('Error creating user document: $e');
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );
      
      await userCredential.user?.updateDisplayName(name);
      
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email.trim(),
        'name': name,
        'targetLanguages': [],
        'streak': 0,
        'totalXP': 0,
        'level': 1,
        'createdAt': FieldValue.serverTimestamp(),
        'examProgress': {},
        'settings': {},
        'favourites': [],
        'wordsLearned': 0,
        'wordsPerCategory': {},
        'wordsPerLanguage': {},
        'lastPracticeDate': null,
        'unlockedAchievements': [],
        'weeklyXP': 0,
        'weeklyRank': 0,
        'dailyTasks': {},
      });
      
      _user = userCredential.user;
      await _loadUserData(userCredential.user!.uid);
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getAuthErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );
      
      _user = userCredential.user;
      await _loadUserData(userCredential.user!.uid);
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getAuthErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _user = null;
      _userModel = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
  }

  Future<bool> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  Future<bool> updateUserProfile({
    String? name,
    List<String>? targetLanguages,
    Map<String, dynamic>? examProgress,
    Map<String, dynamic>? settings,
    List<String>? favourites,
  }) async {
    if (_user == null) return false;

    try {
      Map<String, dynamic> updates = {};
      if (name != null) updates['name'] = name;
      if (targetLanguages != null) updates['targetLanguages'] = targetLanguages;
      if (examProgress != null) updates['examProgress'] = examProgress;
      if (settings != null) updates['settings'] = settings;
      if (favourites != null) updates['favourites'] = favourites;

      await _firestore
          .collection('users')
          .doc(_user!.uid)
          .update(updates);
      
      await _loadUserData(_user!.uid);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  Future<void> updateXP(int points) async {
    if (_user == null || _userModel == null) return;

    try {
      int newXP = (_userModel?.totalXP ?? 0) + points;
      int newLevel = _calculateLevel(newXP);
      
      await _firestore
          .collection('users')
          .doc(_user!.uid)
          .update({
            'totalXP': newXP,
            'level': newLevel,
          });
      
      await _loadUserData(_user!.uid);
    } catch (e) {
      debugPrint('Error updating XP: $e');
    }
  }

  int _calculateLevel(int xp) {
    if (xp < 100) return 1;
    if (xp < 300) return 2;
    if (xp < 600) return 3;
    if (xp < 1000) return 4;
    if (xp < 1500) return 5;
    return 5 + ((xp - 1500) ~/ 500);
  }

  Future<bool> _updateStreak() async {
    if (_userModel == null) return false;
    return true;
  }

  String _getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'email-already-in-use':
        return 'Email already in use';
      case 'invalid-email':
        return 'Invalid email address';
      case 'weak-password':
        return 'Password is too weak';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      default:
        return e.message ?? 'Authentication failed';
    }
  }

  void resetLoading() {
    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ✅ Update user model from external source (for real-time updates)
  void updateUserModel(UserModel updatedUser) {
    _userModel = updatedUser;
    notifyListeners();
  }
}