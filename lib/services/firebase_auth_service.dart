import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_profile.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email
  Future<UserProfile?> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await userCredential.user?.updateDisplayName(name);
      await userCredential.user?.reload();

      if (userCredential.user != null) {
        debugPrint('🔒 [FirebaseAuth] signUpWithEmail: uid=${userCredential.user!.uid}');
        return UserProfile(
          uid: userCredential.user!.uid,
          email: email,
          name: name,
          avatarUrl: '',
          devices: const [],
        );
      }
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint('🔒 [FirebaseAuth] signUpWithEmail FirebaseAuthException: code=${e.code}');
      throw Exception('Sign up failed [${e.code}]: ${e.message}');
    } catch (e) {
      throw Exception('Sign up failed: ${e.toString()}');
    }
  }

  // Sign in with email/password
  Future<UserProfile?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        debugPrint('🔒 [FirebaseAuth] signInWithEmail: uid=${userCredential.user!.uid}');
        return UserProfile(
          uid: userCredential.user!.uid,
          email: userCredential.user!.email!,
          name: userCredential.user!.displayName ?? email.split('@')[0],
          avatarUrl: userCredential.user!.photoURL ?? '',
          devices: const [],
        );
      }
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint('🔒 [FirebaseAuth] signInWithEmail FirebaseAuthException: code=${e.code}');
      throw Exception('Sign in failed [${e.code}]: ${e.message}');
    } catch (e) {
      throw Exception('Sign in failed: ${e.toString()}');
    }
  }

  // Sign in with Google
  Future<UserProfile?> signInWithGoogle() async {
    try {
      debugPrint('🔒 [FirebaseAuth] signInWithGoogle: starting Google account selection');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('🔒 [FirebaseAuth] signInWithGoogle: user cancelled selection');
        return null;
      }
      debugPrint('🔒 [FirebaseAuth] signInWithGoogle: Google account selected → ${googleUser.email}');

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      debugPrint('🔒 [FirebaseAuth] signInWithGoogle: Google auth tokens obtained (accessToken=${googleAuth.accessToken != null}, idToken=${googleAuth.idToken != null})');

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      debugPrint('🔒 [FirebaseAuth] signInWithGoogle: calling Firebase signInWithCredential');
      final userCredential = await _auth.signInWithCredential(credential);
      final uid = userCredential.user?.uid;
      final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;
      debugPrint('🔒 [FirebaseAuth] signInWithGoogle: Firebase sign-in complete → uid=$uid isNewUser=$isNewUser');

      if (userCredential.user != null) {
        return UserProfile(
          uid: userCredential.user!.uid,
          email: userCredential.user!.email!,
          name: userCredential.user!.displayName ?? 'User',
          avatarUrl: userCredential.user!.photoURL ?? '',
          devices: const [],
        );
      }
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint('🔒 [FirebaseAuth] signInWithGoogle FirebaseAuthException: code=${e.code} message=${e.message}');
      throw Exception('Google sign in failed [${e.code}]: ${e.message}');
    } catch (e) {
      debugPrint('🔒 [FirebaseAuth] signInWithGoogle ERROR: $e');
      throw Exception('Google sign in failed: ${e.toString()}');
    }
  }

  // Sign in with Twitter
  Future<UserProfile?> signInWithTwitter() async {
    try {
      final twitterProvider = TwitterAuthProvider();
      final userCredential = await _auth.signInWithProvider(twitterProvider);

      if (userCredential.user != null) {
        return UserProfile(
          uid: userCredential.user!.uid,
          email: userCredential.user!.email ?? '',
          name: userCredential.user!.displayName ?? 'User',
          avatarUrl: userCredential.user!.photoURL ?? '',
          devices: const [],
        );
      }
      return null;
    } catch (e) {
      throw Exception('Twitter sign in failed: ${e.toString()}');
    }
  }

  // Sign out
  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  // Reset password
  Future<void> resetPassword(String email) async {
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
    await _auth.currentUser?.delete();
  }
}
