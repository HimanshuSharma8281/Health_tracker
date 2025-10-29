import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../models/user_profile.dart';
import '../widgets/notification_widget.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.onSignedIn});

  final ValueChanged<UserProfile> onSignedIn;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF3A86FF), Color(0xFF8338EC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),
                Text('Aurora Wellness',
                    style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Text(
                    'AI-guided insights, holistic tracking, and connected experiences for your healthiest self.',
                    style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.85), fontSize: 18)),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF3A86FF),
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                  ),
                  onPressed: auth.loading
                      ? null
                      : () async {
                          await auth.signInWithGoogle();
                          if (mounted && auth.user != null) {
                            widget.onSignedIn(auth.user!);
                          }
                        },
                  icon: auth.loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.login_rounded),
                  label: Text(
                      auth.loading ? 'Signing In' : 'Continue with Google',
                      style: GoogleFonts.inter(
                          fontSize: 18, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 12),
                Text(
                    'Secure authentication powered by Firebase-ready architecture.',
                    style: GoogleFonts.inter(color: Colors.white70)),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
