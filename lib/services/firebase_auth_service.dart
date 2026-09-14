import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_profile.dart';

class AuthResult {
  final UserProfile? profile;
  final UserCredential? credential;
  final bool isNewUser;

  const AuthResult({
    this.profile,
    this.credential,
    this.isNewUser = false,
  });
}

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email
  Future<AuthResult?> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    debugPrint('🔒 [AUTH] Firebase account creation started for email=$email');
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = userCredential.user;
    if (user == null) {
      throw Exception('Firebase account created but authenticated user is unavailable.');
    }

    final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? true;
    debugPrint('🔒 [AUTH] Firebase account creation succeeded: uid=${user.uid} isNewUser=$isNewUser');

    // Update display name if provided (non-fatal if network glitches)
    if (name.isNotEmpty) {
      try {
        await user.updateDisplayName(name);
        await user.reload();
      } catch (e) {
        debugPrint('⚠️ [AUTH] Non-fatal display name update error: $e');
      }
    }

    final profile = UserProfile(
      uid: user.uid,
      email: user.email ?? email,
      name: name.isNotEmpty ? name : (user.displayName ?? email.split('@')[0]),
      avatarUrl: user.photoURL ?? '',
      devices: const [],
    );

    return AuthResult(
      profile: profile,
      credential: userCredential,
      isNewUser: isNewUser,
    );
  }

  // Sign in with email/password
  Future<AuthResult?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    debugPrint('🔒 [AUTH] Firebase sign-in started for email=$email');
    final userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = userCredential.user;
    if (user != null) {
      debugPrint('🔒 [AUTH] Firebase sign-in succeeded: uid=${user.uid}');
      final profile = UserProfile(
        uid: user.uid,
        email: user.email ?? email,
        name: user.displayName ?? email.split('@')[0],
        avatarUrl: user.photoURL ?? '',
        devices: const [],
      );
      return AuthResult(
        profile: profile,
        credential: userCredential,
        isNewUser: userCredential.additionalUserInfo?.isNewUser ?? false,
      );
    }
    return null;
  }

  // Sign in with Google
  Future<AuthResult?> signInWithGoogle() async {
    debugPrint('🔒 [AUTH] Google sign-in started');
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      debugPrint('🔒 [AUTH] Google sign-in cancelled by user');
      return null;
    }
    debugPrint('🔒 [AUTH] Google authentication succeeded for email=${googleUser.email}');

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    debugPrint('🔒 [AUTH] Firebase authentication with Google credential started');
    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user;
    final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;

    if (user != null) {
      debugPrint('🔒 [AUTH] Firebase authentication succeeded: uid=${user.uid} isNewUser=$isNewUser');
      final profile = UserProfile(
        uid: user.uid,
        email: user.email ?? googleUser.email,
        name: user.displayName ?? googleUser.displayName ?? 'User',
        avatarUrl: user.photoURL ?? googleUser.photoUrl ?? '',
        devices: const [],
      );
      return AuthResult(
        profile: profile,
        credential: userCredential,
        isNewUser: isNewUser,
      );
    }
    return null;
  }

  // Sign in with Twitter
  Future<AuthResult?> signInWithTwitter() async {
    debugPrint('🔒 [TwitterAuth] Sign-in started');
    debugPrint('🔒 [TwitterAuth] Step 1: provider created');
    final twitterProvider = TwitterAuthProvider();
    debugPrint('🔒 [TwitterAuth] Provider initialized: providerId=${twitterProvider.providerId}');
    debugPrint('🔒 [TwitterAuth] Step 2: provider sign-in started');
    debugPrint('🔒 [TwitterAuth] Starting Firebase provider sign-in');
    debugPrint('🔒 [TwitterAuth] Step 3: browser OAuth launched');
    debugPrint('🔒 [TwitterAuth] Browser OAuth flow started');

    UserCredential? userCredential;

    try {
      if (kIsWeb) {
        userCredential = await _auth.signInWithPopup(twitterProvider);
      } else {
        userCredential = await _auth.signInWithProvider(twitterProvider);
      }
      debugPrint('🔒 [TwitterAuth] Step 4: app resumed');
      debugPrint('🔒 [TwitterAuth] Firebase credential/result received');
    } on FirebaseAuthException catch (e) {
      debugPrint('🔒 [TwitterAuth] Step 4: app resumed');
      debugPrint('🔒 [TwitterAuth] Exception caught during sign-in');
      debugPrint('🔒 [TwitterAuth] runtimeType: ${e.runtimeType}');
      debugPrint('🔒 [TwitterAuth] code: ${e.code}');
      debugPrint('🔒 [TwitterAuth] message: ${e.message}');
      debugPrint('🔒 [TwitterAuth] plugin: ${e.plugin}');
      debugPrint('🔒 [TwitterAuth] stackTrace: ${e.stackTrace}');

      if (e.code == 'web-context-cancelled' ||
          e.code == 'canceled' ||
          e.code == 'cancelled' ||
          e.code == 'user-cancelled') {
        debugPrint('🔒 [TwitterAuth] Browser OAuth flow cancelled by user: ${e.code}');
        return null;
      }

      // If the user was actually authenticated despite a channel exception
      if (_auth.currentUser != null) {
        debugPrint('🔒 [TwitterAuth] Step 8: currentUser exists: true');
        debugPrint('🔒 [TwitterAuth] Current Firebase user exists: true');
        debugPrint('🔒 [TwitterAuth] Firebase authentication completed successfully');
        final user = _auth.currentUser!;
        final profile = UserProfile(
          uid: user.uid,
          email: user.email ?? '',
          name: user.displayName ?? 'User',
          avatarUrl: user.photoURL ?? '',
          devices: const [],
        );
        return AuthResult(
          profile: profile,
          credential: null,
          isNewUser: false,
        );
      }

      debugPrint('🔒 [TwitterAuth] Step 8: currentUser exists: false');
      debugPrint('🔒 [TwitterAuth] Current Firebase user exists: false');
      debugPrint('🔒 [TwitterAuth] Firebase authentication result not available');
      debugPrint('🔴 [TwitterAuth] FirebaseAuthException: code=${e.code} msg=${e.message}');
      rethrow;
    } catch (e, stack) {
      debugPrint('🔴 [TwitterAuth] Non-FirebaseAuthException: $e');
      debugPrint('🔴 [TwitterAuth] StackTrace: $stack');
      rethrow;
    }

    final user = userCredential.user ?? _auth.currentUser;
    final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;
    final userExists = user != null;
    debugPrint('🔒 [TwitterAuth] Step 7: Firebase authentication completed');
    debugPrint('🔒 [TwitterAuth] Step 8: currentUser exists: $userExists isNewUser=$isNewUser');
    debugPrint('🔒 [TwitterAuth] Current Firebase user exists: $userExists');

    if (user != null) {
      debugPrint('🔒 [TwitterAuth] Firebase authentication completed successfully');
      debugPrint('🔒 [TwitterAuth] Firebase user available: true');
      final profile = UserProfile(
        uid: user.uid,
        email: user.email ?? '',
        name: user.displayName ?? 'User',
        avatarUrl: user.photoURL ?? '',
        devices: const [],
      );
      return AuthResult(
        profile: profile,
        credential: userCredential,
        isNewUser: isNewUser,
      );
    } else {
      debugPrint('🔒 [TwitterAuth] Firebase authentication result not available');
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    debugPrint('🔒 [AUTH] Signing out user');
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    debugPrint('🔒 [AUTH] Sending password reset email to $email');
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Update user profile
  Future<void> updateUserProfile({String? name, String? avatarUrl}) async {
    final user = _auth.currentUser;
    if (user != null) {
      if (name != null) await user.updateDisplayName(name);
      if (avatarUrl != null) await user.updatePhotoURL(avatarUrl);
      await user.reload();
    }
  }

  // Delete account
  Future<void> deleteAccount() async {
    debugPrint('🔒 [AUTH] Deleting Firebase user account');
    await _auth.currentUser?.delete();
  }
}

