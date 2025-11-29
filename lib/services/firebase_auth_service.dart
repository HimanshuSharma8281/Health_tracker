import 'package:firebase_auth/firebase_auth.dart';
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
        return UserProfile(
          email: email,
          name: name,
          avatarUrl: '',
          devices: const [],
        );
      }
      return null;
    } catch (e) {
      throw Exception('Sign up failed: ${e.toString()}');
    }
  }

  // Sign in with email
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
        return UserProfile(
          email: userCredential.user!.email!,
          name: userCredential.user!.displayName ?? email.split('@')[0],
          avatarUrl: userCredential.user!.photoURL ?? '',
          devices: const [],
        );
      }
      return null;
    } catch (e) {
      throw Exception('Sign in failed: ${e.toString()}');
    }
  }

  // Sign in with Google
  Future<UserProfile?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        return UserProfile(
          email: userCredential.user!.email!,
          name: userCredential.user!.displayName ?? 'User',
          avatarUrl: userCredential.user!.photoURL ?? '',
          devices: const [],
        );
      }
      return null;
    } catch (e) {
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
