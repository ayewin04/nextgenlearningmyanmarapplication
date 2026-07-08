// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'config/theme.dart';
import 'config/constants.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/home/language_selection_screen.dart';
import 'screens/languages/language_learning_screen.dart';  // ✅ ADD THIS
import 'screens/favourites/favourites_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/leaderboard/leaderboard_full_screen.dart';
import 'services/auth_service.dart';

// ❌ REMOVE THIS DUPLICATE IMPORT
// import 'screens/home/language_selection_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully!');
  } catch (e) {
    print('❌ Firebase initialization error: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF6C63FF),
            secondary: Color(0xFF4CAF50),
            background: Color(0xFF0A0E27),
            surface: Color(0xFF1A237E),
          ),
          textTheme: const TextTheme(
            displayLarge: TextStyle(color: Colors.white),
            displayMedium: TextStyle(color: Colors.white),
            headlineLarge: TextStyle(color: Colors.white),
            headlineMedium: TextStyle(color: Colors.white),
            titleLarge: TextStyle(color: Colors.white),
            bodyLarge: TextStyle(color: Colors.white70),
            bodyMedium: TextStyle(color: Colors.white70),
          ),
          scaffoldBackgroundColor: const Color(0xFF0A0E27),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const AuthWrapper(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/home': (context) => const HomeScreen(),
          '/learning': (context) => const LanguageLearningScreen(),  // ✅ Learning content
          '/favourites': (context) => const FavouritesScreen(),
          '/settings': (context) => const SettingsScreen(),
          '/leaderboard': (context) => const LeaderboardFullScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/home') {
            return MaterialPageRoute(
              builder: (context) => const HomeScreen(),
            );
          }
          if (settings.name == '/learning') {
            return MaterialPageRoute(
              builder: (context) => const LanguageLearningScreen(),
            );
          }
          if (settings.name == '/favourites') {
            return MaterialPageRoute(
              builder: (context) => const FavouritesScreen(),
            );
          }
          if (settings.name == '/settings') {
            return MaterialPageRoute(
              builder: (context) => const SettingsScreen(),
            );
          }
          if (settings.name == '/leaderboard') {
            return MaterialPageRoute(
              builder: (context) => const LeaderboardFullScreen(),
            );
          }
          return null;
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
    if (authService.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (authService.user != null) {
      return const HomeScreen();
    }
    
    return const LoginScreen();
  }
}