import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'config/themes.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'screens/auth/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env (Gemini + JSearch API keys)
  await dotenv.load(fileName: '.env');

  // Pass explicit options so Firebase connects to the correct project
  // on every platform (Android, iOS, web, Windows, macOS).
  // Without this, iOS/web/Windows silently connect to nothing and
  // every Firestore write fails.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const SmartPlaceApp());
}

class SmartPlaceApp extends StatelessWidget {
  const SmartPlaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: MaterialApp(
        title: 'SmartPlace',
        debugShowCheckedModeBanner: false,
        theme: AppThemes.lightTheme,
        darkTheme: AppThemes.darkTheme,
        themeMode: ThemeMode.system,
        home: const SplashScreen(),
      ),
    );
  }
}
