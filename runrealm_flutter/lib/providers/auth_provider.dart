import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../services/user_service.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _authReady = false;
  bool _profileReady = false;
  bool? _setupComplete;

  User? get user => _user;
  bool get authReady => _authReady;
  bool get profileReady => _profileReady;
  bool? get setupComplete => _setupComplete;

  AuthProvider() {
    _initAuth();
  }

  void _initAuth() {
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      _user = user;
      _authReady = true;
      if (user != null) {
        await _handleUserSignIn(user);
      } else {
        _profileReady = false;
        _setupComplete = null;
      }
      notifyListeners();
    });
  }

  Future<void> _handleUserSignIn(User user) async {
    try {
      final profile = await UserService.getUserProfile(user.uid);
      if (profile == null) {
        await UserService.createUserProfile(user.uid);
        _setupComplete = false;
      } else {
        _setupComplete = profile.setupComplete ?? false;
      }
      _profileReady = true;
      notifyListeners();
    } catch (e) {
      print('Error handling user sign in: $e');
    }
  }

  bool _isSigningIn = false;

  Future<void> signInAnonymously() async {
    if (_isSigningIn) return;
    _isSigningIn = true;
    notifyListeners();

    try {
      await FirebaseAuth.instance.signInAnonymously();
    } catch (e) {
      print('Error signing in anonymously: $e');
      _isSigningIn = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  void setSetupComplete(bool complete) {
    _setupComplete = complete;
    notifyListeners();
  }
}
