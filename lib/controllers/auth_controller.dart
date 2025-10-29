import 'package:flutter/material.dart';
import '../models/user_profile.dart';

class AuthController extends ChangeNotifier {
  UserProfile? user;
  bool loading = false;

  bool get isAuthenticated => user != null;

  Future<void> signInWithGoogle() async {
    loading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 900));
    user = UserProfile(
      name: 'Jordan Parker',
      email: 'jordan.parker@example.com',
      avatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e',
      devices: const ['Pixel Watch', 'WHOOP Strap', 'iPad Pro'],
    );
    loading = false;
    notifyListeners();
  }

  void signOut() {
    user = null;
    notifyListeners();
  }
}
