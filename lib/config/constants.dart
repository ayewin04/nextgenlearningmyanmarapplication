// lib/config/constants.dart
import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'Polyglot Exam Prep';
  static const String appVersion = '1.0.0';
  
  // Exam Types
  static const List<String> examTypes = [
    'IELTS',
    'HSK',
    'JLPT',
    'TOPIK',
    
    
  ];
  
  // Exam Icons/Flags
  static const Map<String, String> examFlags = {
    'IELTS': '🇬🇧',
    'HSK': '🇨🇳',
    'JLPT': '🇯🇵',
    'TOPIK': '🇰🇷',
    
  };
  
  // Exam Colors
  static const Map<String, int> examColors = {
    'IELTS': 0xFFE53935,
    'HSK': 0xFFD32F2F,
    'JLPT': 0xFFC62828,
    'TOPIK': 0xFF1565C0,
    
  };
  
  // Language Flags (for Daily Challenge)
  static Map<String, String> get languageFlags {
    return {
      'IELTS': '🇬🇧',
      'HSK': '🇨🇳',
      'JLPT': '🇯🇵',
      'TOPIK': '🇰🇷',
      
    };
  }
  
  // Language Colors (for Daily Challenge)
  static Map<String, Color> get languageColors {
    return {
      'IELTS': Colors.blue,
      'HSK': Colors.red,
      'JLPT': Colors.purple,
      'TOPIK': Colors.green,
      
    };
  }
  
  // Language Descriptions
  static Map<String, String> get languageDescriptions {
    return {
      'IELTS': 'International English Language Testing System',
      'HSK': 'Hanyu Shuiping Kaoshi - Chinese Proficiency Test',
      'JLPT': 'Japanese-Language Proficiency Test',
      'TOPIK': 'Test of Proficiency in Korean',
      
    };
  }
  
  // HSK Levels
  static const List<String> hskLevels = ['HSK 1', 'HSK 2', 'HSK 3', 'HSK 4', 'HSK 5', 'HSK 6'];
  
  // JLPT Levels
  static const List<String> jlptLevels = ['N5', 'N4', 'N3', 'N2', 'N1'];
  
  // TOPIK Levels
  static const List<String> topicLevels = ['TOPIK I', 'TOPIK II'];
  
  // IELTS Bands
  static const List<String> ieltsBands = ['Band 4', 'Band 5', 'Band 6', 'Band 7', 'Band 8', 'Band 9'];
  
  // Firebase Collections
  static const String usersCollection = 'users';
  static const String questionsCollection = 'questions';
  static const String examsCollection = 'exams';
  static const String vocabularyCollection = 'vocabulary';
  static const String userProgressCollection = 'user_progress';
  static const String flashcardsCollection = 'flashcards';
  
  // Shared Preferences Keys
  static const String prefUserId = 'user_id';
  static const String prefUserEmail = 'user_email';
  static const String prefUserName = 'user_name';
  static const String prefThemeMode = 'theme_mode';
  static const String prefNotifications = 'notifications';
  
  // API Endpoints
  static const String openAIEndpoint = 'https://api.openai.com/v1/chat/completions';
  
  // Spaced Repetition Settings
  static const int initialInterval = 1;
  static const double easeFactor = 2.5;
  static const int maxInterval = 365;
}