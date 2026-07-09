import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'config/constants.dart';
import 'services/auth_service.dart';
import 'services/theme_service.dart';
import 'services/audio_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/languages/language_learning_screen.dart';
import 'screens/favourites/favourites_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/leaderboard/leaderboard_full_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully!');
    
    // ✅ Initialize audio service
    try {
      await AudioService.initialize();
      print('✅ Audio service initialized!');
    } catch (e) {
      print('⚠️ Audio service initialization failed: $e');
    }
  } catch (e) {
    print('❌ Initialization error: $e');
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
        ChangeNotifierProvider(create: (_) => ThemeService()),
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: themeService.themeData,
            initialRoute: '/',
            routes: {
              '/': (context) => const AuthWrapper(),
              '/login': (context) => const LoginScreen(),
              '/register': (context) => const RegisterScreen(),
              '/home': (context) => const HomeScreen(),
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
          );
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