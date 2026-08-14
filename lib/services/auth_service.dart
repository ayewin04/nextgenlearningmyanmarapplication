// lib/services/auth_service.dart
import 'dart:async';  // ⭐ ADD THIS - Required for Timer
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
  String? _successMessage;
  Timer? _messageTimer;  // ✅ Now works with import

  User? get user => _user;
  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
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

  void _scheduleMessageClear() {
    _messageTimer?.cancel();
    _messageTimer = Timer(const Duration(seconds: 5), () {
      _errorMessage = null;
      _successMessage = null;
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
      _errorMessage = 'Could not load your profile data';
      _scheduleMessageClear();
      notifyListeners();
    }
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
      _errorMessage = 'Could not create your profile';
      _scheduleMessageClear();
      notifyListeners();
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    _messageTimer?.cancel();
    notifyListeners();

    try {
      // 1. Validate inputs
      if (email.trim().isEmpty) {
        _errorMessage = 'Please enter your email address';
        _isLoading = false;
        _scheduleMessageClear();
        notifyListeners();
        return false;
      }

      if (password.isEmpty) {
        _errorMessage = 'Please enter a password';
        _isLoading = false;
        _scheduleMessageClear();
        notifyListeners();
        return false;
      }

      if (password.length < 6) {
        _errorMessage = 'Password must be at least 6 characters';
        _isLoading = false;
        _scheduleMessageClear();
        notifyListeners();
        return false;
      }

      if (name.trim().isEmpty) {
        _errorMessage = 'Please enter your name';
        _isLoading = false;
        _scheduleMessageClear();
        notifyListeners();
        return false;
      }

      // 2. Create user
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );
      
      // 3. Update display name
      await userCredential.user?.updateDisplayName(name.trim());
      
      // 4. Create user document in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email.trim(),
        'name': name.trim(),
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
      
      // ⭐ Keep user signed in after registration
      _successMessage = 'Account created successfully! 🎉';
      _isLoading = false;
      _scheduleMessageClear();
      notifyListeners();
      
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getAuthErrorMessage(e);
      _isLoading = false;
      _scheduleMessageClear();
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Something went wrong. Please try again.';
      _isLoading = false;
      _scheduleMessageClear();
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
    _successMessage = null;
    _messageTimer?.cancel();
    notifyListeners();

    try {
      // 1. Validate inputs
      if (email.trim().isEmpty) {
        _errorMessage = 'Please enter your email address';
        _isLoading = false;
        _scheduleMessageClear();
        notifyListeners();
        return false;
      }

      if (password.isEmpty) {
        _errorMessage = 'Please enter your password';
        _isLoading = false;
        _scheduleMessageClear();
        notifyListeners();
        return false;
      }

      // 2. Sign in
      UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );
      
      _user = userCredential.user;
      await _loadUserData(userCredential.user!.uid);
      
      _successMessage = 'Welcome back! 👋';
      _isLoading = false;
      _scheduleMessageClear();
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getAuthErrorMessage(e);
      _isLoading = false;
      _scheduleMessageClear();
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Something went wrong. Please try again.';
      _isLoading = false;
      _scheduleMessageClear();
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _user = null;
      _userModel = null;
      _errorMessage = null;
      _successMessage = null;
      _messageTimer?.cancel();
      notifyListeners();
    } catch (e) {
      debugPrint('Error signing out: $e');
      _errorMessage = 'Could not sign out. Please try again.';
      _scheduleMessageClear();
      notifyListeners();
    }
  }

  Future<bool> resetPassword(String email) async {
    try {
      if (email.trim().isEmpty) {
        _errorMessage = 'Please enter your email address';
        _scheduleMessageClear();
        notifyListeners();
        return false;
      }

      await _auth.sendPasswordResetEmail(email: email.trim());
      _successMessage = 'Password reset link sent to $email';
      _scheduleMessageClear();
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getAuthErrorMessage(e);
      _scheduleMessageClear();
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Could not send reset link. Please try again.';
      _scheduleMessageClear();
      notifyListeners();
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
    if (_user == null) {
      _errorMessage = 'You must be logged in to update your profile';
      _scheduleMessageClear();
      notifyListeners();
      return false;
    }

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
      _successMessage = 'Profile updated successfully!';
      _scheduleMessageClear();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Could not update profile. Please try again.';
      _scheduleMessageClear();
      notifyListeners();
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
      _successMessage = 'You gained $points XP! 🎉';
      _scheduleMessageClear();
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating XP: $e');
      _errorMessage = 'Could not update your progress';
      _scheduleMessageClear();
      notifyListeners();
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

  String _getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email. Please sign up first.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'This email is already registered. Please sign in instead.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password is too weak. Please use at least 6 characters.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'operation-not-allowed':
        return 'Email/Password sign-in is not enabled. Please contact support.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }

  void clearMessages() {
    _messageTimer?.cancel();
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void resetLoading() {
    _isLoading = false;
    notifyListeners();
  }

  void updateUserModel(UserModel updatedUser) {
    _userModel = updatedUser;
    notifyListeners();
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    super.dispose();
  }
}