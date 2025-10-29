import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'controllers/auth_controller.dart';
import 'controllers/health_data_controller.dart';
import 'screens/login_screen.dart';
import 'widgets/home_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WellnessApp());
}

class WellnessApp extends StatelessWidget {
  const WellnessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => HealthDataController()),
      ],
      child: MaterialApp(
        title: 'Aurora Wellness',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3A86FF)),
          textTheme: GoogleFonts.interTextTheme(),
          scaffoldBackgroundColor: const Color(0xFFF7F7FB),
          appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
              foregroundColor: Colors.black87),
        ),
        home: const RootGate(),
      ),
    );
  }
}

class RootGate extends StatelessWidget {
  const RootGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthController, HealthDataController>(
      builder: (context, auth, health, _) {
        if (!auth.isAuthenticated) {
          return LoginScreen(
              onSignedIn: (profile) => health.loadProfile(profile));
        }
        return const HomeShell();
      },
    );
  }
}
