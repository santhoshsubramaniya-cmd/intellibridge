import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'config/themes.dart';
import 'services/auth_service.dart';
import 'screens/auth/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Load .env safely ──────────────────────────────────
  // If the .env asset is missing (common on fresh installs / other devices),
  // we catch the error and continue instead of crashing.
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('⚠️  .env file not found or failed to load: $e');
    // App will still run. Gemini/JSearch features will degrade gracefully.
  }

  // ── Initialize Firebase ───────────────────────────────
  // Always pass options explicitly — required for multi-platform and
  // for the app to connect to the correct Firebase project on ANY device.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const InteliBridgeApp());
}

class InteliBridgeApp extends StatelessWidget {
  const InteliBridgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: MaterialApp(
        title: 'InteliBridge',
        debugShowCheckedModeBanner: false,
        theme: AppThemes.lightTheme,
        darkTheme: AppThemes.darkTheme,
        themeMode: ThemeMode.system,
        home: const SplashScreen(),
      ),
    );
  }
}
