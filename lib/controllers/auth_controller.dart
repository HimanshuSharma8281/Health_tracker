import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/firebase_auth_service.dart';
import '../controllers/health_data_controller.dart';
import 'package:provider/provider.dart';

class AuthController extends ChangeNotifier {
  final FirebaseAuthService _authService = FirebaseAuthService();
  UserProfile? _user;
  bool loading = false;
  String? _error;

  bool get isAuthenticated => _user != null;
  UserProfile? get user => _user;
  String? get error => _error;

  AuthController() {
    _initAuth();
  }

  // Initialize auth state
  void _initAuth() {
    _authService.authStateChanges.listen((firebaseUser) async {
      if (firebaseUser != null) {
        await _loadUserProfile();
      } else {
        _user = null;
        notifyListeners();
      }
    });
  }

  // Load user profile
  Future<void> _loadUserProfile() async {
    try {
      final uid = _authService.currentUser?.uid;
      if (uid != null) {
        // Get profile from Firestore or create default
        _user = UserProfile(
          name: _authService.currentUser?.displayName ?? 'User',
          email: _authService.currentUser?.email ?? '',
          avatarUrl: _authService.currentUser?.photoURL ?? '',
          devices: const [],
        );
        notifyListeners();
      }
    } catch (e) {
      print('Error loading user profile: $e');
    }
  }

  // Sign in with email
  Future<bool> signInWithEmail({
    required String email,
    required String password,
    required BuildContext? context,
  }) async {
    loading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _authService.signInWithEmail(
        email: email,
        password: password,
      );

      // Set user info in HealthDataController IMMEDIATELY
      if (_user != null && context != null && context.mounted) {
        final healthData =
            Provider.of<HealthDataController>(context, listen: false);
        await Future.delayed(const Duration(
            milliseconds: 100)); // Small delay to ensure context is ready
        healthData.setUserInfo(
          _authService.currentUser!.uid,
          _user!.name,
        );
      }

      loading = false;
      notifyListeners();
      return _user != null;
    } catch (e) {
      _error = e.toString();
      loading = false;
      notifyListeners();
      return false;
    }
  }

  // Sign in with Google
  Future<bool> signInWithGoogle({BuildContext? context}) async {
    loading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _authService.signInWithGoogle();

      // Set user info in HealthDataController IMMEDIATELY
      if (_user != null && context != null && context.mounted) {
        final healthData =
            Provider.of<HealthDataController>(context, listen: false);
        await Future.delayed(const Duration(
            milliseconds: 100)); // Small delay to ensure context is ready
        healthData.setUserInfo(
          _authService.currentUser!.uid,
          _user!.name,
        );
      }

      loading = false;
      notifyListeners();
      return _user != null;
    } catch (e) {
      _error = e.toString();
      loading = false;
      notifyListeners();
      return false;
    }
  }

  // Sign in with Twitter
  Future<bool> signInWithTwitter({BuildContext? context}) async {
    loading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _authService.signInWithTwitter();

      // Set user info in HealthDataController IMMEDIATELY
      if (_user != null && context != null && context.mounted) {
        final healthData =
            Provider.of<HealthDataController>(context, listen: false);
        await Future.delayed(const Duration(
            milliseconds: 100)); // Small delay to ensure context is ready
        healthData.setUserInfo(
          _authService.currentUser!.uid,
          _user!.name,
        );
      }

      loading = false;
      notifyListeners();
      return _user != null;
    } catch (e) {
      _error = e.toString();
      loading = false;
      notifyListeners();
      return false;
    }
  }

  // Sign up with email
  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    required BuildContext? context,
  }) async {
    loading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _authService.signUpWithEmail(
        email: email,
        password: password,
        name: name,
      );

      // Set user info in HealthDataController IMMEDIATELY
      if (_user != null && context != null && context.mounted) {
        final healthData =
            Provider.of<HealthDataController>(context, listen: false);
        await Future.delayed(const Duration(
            milliseconds: 100)); // Small delay to ensure context is ready
        healthData.setUserInfo(
          _authService.currentUser!.uid,
          _user!.name,
        );
      }

      loading = false;
      notifyListeners();
      return _user != null;
    } catch (e) {
      _error = e.toString();
      loading = false;
      notifyListeners();
      return false;
    }
  }

  // Sign out - Clear health data controller user info
  Future<void> signOut() async {
    try {
      await _authService.signOut();
      _user = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    try {
      await _authService.resetPassword(email);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Update profile
  Future<void> updateProfile({String? name, String? avatarUrl}) async {
    try {
      await _authService.updateUserProfile(name: name, avatarUrl: avatarUrl);

      if (_user != null) {
        _user = UserProfile(
          name: name ?? _user!.name,
          email: _user!.email,
          avatarUrl: avatarUrl ?? _user!.avatarUrl,
          devices: _user!.devices,
        );
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Delete account
  Future<bool> deleteAccount() async {
    try {
      await _authService.deleteAccount();
      _user = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
