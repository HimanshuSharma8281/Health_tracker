import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/firebase_auth_service.dart';
import '../services/firestore_service.dart';
import '../services/social_service.dart';
import '../controllers/health_data_controller.dart';
import 'package:provider/provider.dart';

/// Auth state controller.
///
/// Responsibilities:
///   1. Firebase Auth sign-in / sign-out for all providers.
///   2. Load or create the Firestore user profile on every sign-in.
///   3. Initialize HealthDataController with the Firebase UID exactly ONCE
///      per login event (the _isLoadingData guard in HealthDataController
///      prevents duplicate initialization).
///
/// The Google/SharedPreferences synchronization fix from the previous session
/// remains intact — Future.delayed anti-patterns have been removed and the
/// setUserInfo guard prevents race conditions.
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

  // Initialize auth state listener
  void _initAuth() {
    _authService.authStateChanges.listen((firebaseUser) async {
      if (firebaseUser != null) {
        debugPrint(
            '🔒 [Auth] authStateChanges: user signed in uid=${firebaseUser.uid} '
            'provider=${firebaseUser.providerData.map((p) => p.providerId).join(",")}');
        await _loadUserProfile();
      } else {
        debugPrint('🔒 [Auth] authStateChanges: user signed out');
        _user = null;
        notifyListeners();
      }
    });
  }

  // Load user profile from Firebase Auth + Firestore.
  // Does NOT call setUserInfo — that is called explicitly from sign-in methods.
  Future<void> _loadUserProfile() async {
    try {
      final firebaseUser = _authService.currentUser;
      if (firebaseUser == null) return;
      final uid = firebaseUser.uid;

      // Try to load from Firestore first (may have demographics)
      final firestoreProfile = await FirestoreService.instance.loadProfile(uid);

      if (firestoreProfile != null) {
        _user = firestoreProfile;
      } else {
        // Build minimal profile from Firebase Auth data
        _user = UserProfile.fromFirebaseAuth(
          uid: uid,
          name: firebaseUser.displayName ?? 'User',
          email: firebaseUser.email ?? '',
          avatarUrl: firebaseUser.photoURL ?? '',
        );
      }

      debugPrint('🔒 [Auth] _loadUserProfile: uid=$uid name=${_user!.name}');
      notifyListeners();
    } catch (e) {
      debugPrint('🔒 [Auth] _loadUserProfile ERROR: $e');
    }
  }

  /// Save full user profile in Firestore and state.
  Future<void> saveFullProfile(UserProfile updatedProfile, [HealthDataController? healthData]) async {
    _user = updatedProfile;
    await FirestoreService.instance.saveProfile(updatedProfile);
    if (healthData != null) {
      healthData.loadProfile(updatedProfile);
    }
    notifyListeners();
  }

  // ── Sign-in methods ───────────────────────────────────────────────────────

  /// Sign in with email/password.
  Future<bool> signInWithEmail({
    required String email,
    required String password,
    required BuildContext? context,
  }) async {
    loading = true;
    _error = null;
    notifyListeners();

    try {
      final authProfile = await _authService.signInWithEmail(
        email: email,
        password: password,
      );

      if (authProfile != null && _authService.currentUser != null) {
        final uid = _authService.currentUser!.uid;
        debugPrint('🔒 [Auth] signInWithEmail success: uid=$uid');

        // Create or load Firestore profile
        _user = await FirestoreService.instance.createProfileIfAbsent(
          uid: uid,
          name: authProfile.name,
          email: authProfile.email,
          avatarUrl: authProfile.avatarUrl,
        );

        // Initialize health data — exactly once, no delay
        if (context != null && context.mounted) {
          final healthData =
              Provider.of<HealthDataController>(context, listen: false);
          healthData.setUserInfo(uid, _user!.name);
          healthData.loadProfile(_user!);
        }
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

  /// Sign in with Google.
  Future<bool> signInWithGoogle({BuildContext? context}) async {
    loading = true;
    _error = null;
    notifyListeners();

    try {
      final authProfile = await _authService.signInWithGoogle();

      if (authProfile != null && _authService.currentUser != null) {
        final uid = _authService.currentUser!.uid;
        debugPrint('🔒 [Auth] signInWithGoogle success: uid=$uid');

        // Create or load Firestore profile
        _user = await FirestoreService.instance.createProfileIfAbsent(
          uid: uid,
          name: authProfile.name,
          email: authProfile.email,
          avatarUrl: authProfile.avatarUrl,
        );

        // Initialize health data — exactly once, no delay
        if (context != null && context.mounted) {
          final healthData =
              Provider.of<HealthDataController>(context, listen: false);
          healthData.setUserInfo(uid, _user!.name);
          healthData.loadProfile(_user!);
        }
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

  /// Sign in with Twitter.
  Future<bool> signInWithTwitter({BuildContext? context}) async {
    loading = true;
    _error = null;
    notifyListeners();

    try {
      final authProfile = await _authService.signInWithTwitter();

      if (authProfile != null && _authService.currentUser != null) {
        final uid = _authService.currentUser!.uid;
        debugPrint('🔒 [Auth] signInWithTwitter success: uid=$uid');

        _user = await FirestoreService.instance.createProfileIfAbsent(
          uid: uid,
          name: authProfile.name,
          email: authProfile.email,
          avatarUrl: authProfile.avatarUrl,
        );

        if (context != null && context.mounted) {
          final healthData =
              Provider.of<HealthDataController>(context, listen: false);
          healthData.setUserInfo(uid, _user!.name);
          healthData.loadProfile(_user!);
        }
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

  /// Sign up with email/password.
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
      final authProfile = await _authService.signUpWithEmail(
        email: email,
        password: password,
        name: name,
      );

      if (authProfile != null && _authService.currentUser != null) {
        final uid = _authService.currentUser!.uid;
        debugPrint('🔒 [Auth] signUpWithEmail success: uid=$uid');

        // Always create a new Firestore profile for new users
        _user = await FirestoreService.instance.createProfileIfAbsent(
          uid: uid,
          name: authProfile.name,
          email: authProfile.email,
          avatarUrl: authProfile.avatarUrl,
        );

        if (context != null && context.mounted) {
          final healthData =
              Provider.of<HealthDataController>(context, listen: false);
          healthData.setUserInfo(uid, _user!.name);
          healthData.loadProfile(_user!);
        }
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

  // ── Other auth methods ────────────────────────────────────────────────────

  /// Sign out.
  Future<void> signOut() async {
    debugPrint('🔒 [Auth] signOut called for uid=${_authService.currentUser?.uid}');
    try {
      await _authService.signOut();
      _user = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Reset password.
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

  /// Update display name and/or avatar.
  Future<void> updateProfile({String? name, String? avatarUrl}) async {
    try {
      await _authService.updateUserProfile(name: name, avatarUrl: avatarUrl);

      if (_user != null) {
        _user = _user!.copyWith(name: name, avatarUrl: avatarUrl);

        // Persist to Firestore
        final fields = <String, dynamic>{};
        if (name != null) fields['name'] = name;
        if (avatarUrl != null) fields['avatarUrl'] = avatarUrl;
        if (fields.isNotEmpty) {
          await FirestoreService.instance.updateProfileFields(_user!.uid, fields);
        }

        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Save updated demographic profile fields.
  Future<void> updateDemographics({
    int? age,
    String? sex,
    double? heightCm,
    double? weightKg,
    String? activityLevel,
    String? fitnessGoal,
  }) async {
    if (_user == null) return;

    _user = _user!.copyWith(
      age: age,
      sex: sex,
      heightCm: heightCm,
      weightKg: weightKg,
      activityLevel: activityLevel,
      fitnessGoal: fitnessGoal,
    );

    final fields = <String, dynamic>{};
    if (age != null) fields['age'] = age;
    if (sex != null) fields['sex'] = sex;
    if (heightCm != null) fields['heightCm'] = heightCm;
    if (weightKg != null) fields['weightKg'] = weightKg;
    if (activityLevel != null) fields['activityLevel'] = activityLevel;
    if (fitnessGoal != null) fields['fitnessGoal'] = fitnessGoal;

    await FirestoreService.instance.updateProfileFields(_user!.uid, fields);
    debugPrint('✅ [Auth] updateDemographics: saved ${fields.keys.join(",")}');
    notifyListeners();
  }

  /// Save updated goal fields.
  Future<void> updateGoals({
    int? stepGoal,
    int? waterGoalMl,
    double? calorieGoal,
    double? sleepGoalHours,
  }) async {
    if (_user == null) return;

    _user = _user!.copyWith(
      stepGoal: stepGoal,
      waterGoalMl: waterGoalMl,
      calorieGoal: calorieGoal,
      sleepGoalHours: sleepGoalHours,
    );

    final fields = <String, dynamic>{};
    if (stepGoal != null) fields['stepGoal'] = stepGoal;
    if (waterGoalMl != null) fields['waterGoalMl'] = waterGoalMl;
    if (calorieGoal != null) fields['calorieGoal'] = calorieGoal;
    if (sleepGoalHours != null) fields['sleepGoalHours'] = sleepGoalHours;

    await FirestoreService.instance.updateProfileFields(_user!.uid, fields);
    notifyListeners();
  }

  /// Delete account forever: permanently wipes all Firestore records,
  /// Realtime Database stats, challenge entries, and the Firebase Authentication user.
  Future<bool> deleteAccount() async {
    final uid = _user?.uid ?? _authService.currentUser?.uid;
    loading = true;
    _error = null;
    notifyListeners();

    try {
      if (uid != null && uid.isNotEmpty) {
        // 1. Permanently delete all Firestore data (readings, daily scores, profile, challenges)
        await FirestoreService.instance.deleteUserDataPermanently(uid);

        // 2. Permanently delete Realtime Database user leaderboard entry
        await SocialService.deleteUserScore(uid);
      }

      // 3. Delete Firebase Authentication user
      await _authService.deleteAccount();

      _user = null;
      loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('🔴 [AuthController] deleteAccount error: $e');
      _error = e.toString();
      try {
        await _authService.signOut();
      } catch (_) {}
      _user = null;
      loading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Called from HomeShell on first mount to handle the returning-user case.
  void initializeHealthDataIfNeeded(BuildContext context) {
    final uid = _authService.currentUser?.uid;
    if (uid == null || _user == null) return;

    final healthData =
        Provider.of<HealthDataController>(context, listen: false);

    if (healthData.profile == null || healthData.profile?.uid != uid) {
      debugPrint('🔒 [Auth] initializeHealthDataIfNeeded: syncing profile for uid=$uid');
      healthData.loadProfile(_user!);
    }

    if (healthData.userId == uid) {
      debugPrint('🔒 [Auth] initializeHealthDataIfNeeded: already initialized for uid=$uid');
      return;
    }

    debugPrint('🔒 [Auth] initializeHealthDataIfNeeded: initializing for returning user uid=$uid');
    healthData.setUserInfo(uid, _user!.name);
  }
}
