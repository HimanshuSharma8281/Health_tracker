import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';

import 'controllers/auth_controller.dart';
import 'controllers/health_data_controller.dart';
import 'controllers/theme_controller.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';
import 'widgets/home_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await _requestPermissions();
  runApp(const WellnessApp());
}

Future<void> _requestPermissions() async {
  if (await Permission.activityRecognition.isDenied) {
    await Permission.activityRecognition.request();
  }
  if (await Permission.sensors.isDenied) {
    await Permission.sensors.request();
  }
}

class WellnessApp extends StatelessWidget {
  const WellnessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => HealthDataController()),
        ChangeNotifierProvider(create: (_) => ThemeController()),
      ],
      child: Consumer<ThemeController>(
        builder: (context, themeController, _) {
          return MaterialApp(
            title: 'Aurora Wellness',
            debugShowCheckedModeBanner: false,
            themeMode: themeController.themeMode,
            theme: ThemeController.lightTheme.copyWith(
              textTheme: GoogleFonts.interTextTheme(
                  ThemeController.lightTheme.textTheme),
            ),
            darkTheme: ThemeController.darkTheme.copyWith(
              textTheme: GoogleFonts.interTextTheme(
                  ThemeController.darkTheme.textTheme),
            ),
            home: const AppLifecycleManager(child: SplashWrapper()),
          );
        },
      ),
    );
  }
}

class SplashWrapper extends StatefulWidget {
  const SplashWrapper({super.key});

  @override
  State<SplashWrapper> createState() => _SplashWrapperState();
}

class _SplashWrapperState extends State<SplashWrapper> {
  bool _showSplash = true;

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return SplashScreen(
        onComplete: () {
          setState(() {
            _showSplash = false;
          });
        },
      );
    }
    return const RootScreen();
  }
}

class AppLifecycleManager extends StatefulWidget {
  final Widget child;

  const AppLifecycleManager({super.key, required this.child});

  @override
  State<AppLifecycleManager> createState() => _AppLifecycleManagerState();
}

class _AppLifecycleManagerState extends State<AppLifecycleManager>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Check for daily reset when app comes to foreground
      Provider.of<HealthDataController>(context, listen: false)
          .checkDailyReset();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  @override
  void initState() {
    super.initState();
    // Check auth state on app start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthController>(context, listen: false);
      final healthData =
          Provider.of<HealthDataController>(context, listen: false);

      // If user is already signed in, set the user info
      if (auth.user != null) {
        final firebaseAuth = FirebaseAuth.instance;
        if (firebaseAuth.currentUser != null) {
          healthData.setUserInfo(
            firebaseAuth.currentUser!.uid,
            auth.user!.name,
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthController>(
      builder: (context, auth, _) {
        // If not authenticated, show login
        if (!auth.isAuthenticated) {
          return LoginScreen(
            onSignedIn: (profile) {
              // User info already set in auth controller
              setState(() {});
            },
          );
        }

        // Show main app
        return const HomeShell(); // Changed from MainScreen to HomeShell
      },
    );
  }
}
