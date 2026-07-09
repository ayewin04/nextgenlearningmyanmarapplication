// lib/models/vocabulary_model.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VocabularyModel {
  final String id;
  final String burmeseWord;
  final String romanization;
  final String partOfSpeech;
  final String category;
  final String subCategory;
  final Map<String, String> translations;
  final Map<String, String> romanizations;
  final Map<String, String> examples;
  final Map<String, String> exampleRomanizations;
  final Map<String, String> exampleTranslations;
  final String? audioUrl;
  final int difficulty;
  final List<String> tags;
  bool isFavourite;

  VocabularyModel({
    required this.id,
    required this.burmeseWord,
    required this.romanization,
    required this.partOfSpeech,
    required this.category,
    this.subCategory = '',
    required this.translations,
    required this.romanizations,
    required this.examples,
    required this.exampleRomanizations,
    required this.exampleTranslations,
    this.audioUrl,
    this.difficulty = 1,
    this.tags = const [],
    this.isFavourite = false,
  });

  factory VocabularyModel.fromMap(String id, Map<String, dynamic> data) {
    return VocabularyModel(
      id: id,
      burmeseWord: data['burmeseWord'] ?? '',
      romanization: data['romanization'] ?? '',
      partOfSpeech: data['partOfSpeech'] ?? 'noun',
      category: data['category'] ?? 'Daily',
      subCategory: data['subCategory'] ?? '',
      translations: Map<String, String>.from(data['translations'] ?? {}),
      romanizations: Map<String, String>.from(data['romanizations'] ?? {}),
      examples: Map<String, String>.from(data['examples'] ?? {}),
      exampleRomanizations: Map<String, String>.from(data['exampleRomanizations'] ?? {}),
      exampleTranslations: Map<String, String>.from(data['exampleTranslations'] ?? {}),
      audioUrl: data['audioUrl'],
      difficulty: data['difficulty'] ?? 1,
      tags: List<String>.from(data['tags'] ?? []),
      isFavourite: data['isFavourite'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'burmeseWord': burmeseWord,
      'romanization': romanization,
      'partOfSpeech': partOfSpeech,
      'category': category,
      'subCategory': subCategory,
      'translations': translations,
      'romanizations': romanizations,
      'examples': examples,
      'exampleRomanizations': exampleRomanizations,
      'exampleTranslations': exampleTranslations,
      'audioUrl': audioUrl,
      'difficulty': difficulty,
      'tags': tags,
      'isFavourite': isFavourite,
    };
  }

  String getTranslation(String language) => translations[language] ?? '';
  String getRomanization(String language) => romanizations[language] ?? '';
  String getExample(String language) => examples[language] ?? '';
  String getExampleRomanization(String language) => exampleRomanizations[language] ?? '';
  String getExampleTranslation(String language) => exampleTranslations[language] ?? '';
  bool hasAudio() => audioUrl != null && audioUrl!.isNotEmpty;
}

class ExamVocabularyModel {
  final String id;
  final String exam;
  final String level;
  final String category;
  
  // Burmese fields
  final String burmeseWord;
  final String romanization; // Burmese romanization
  
  // Word fields
  final String word;
  final String? pronunciation;
  final String? pinyin;
  final String? hiragana;
  final String? romaji; // Japanese romanization
  final String? hangul; // Korean characters
  final String? koreanRoman; // Korean romanization
  final String? thaiRoman;
  final String meaning;
  final String? exampleSentence;
  final String? exampleRomanization; // Romanization of the example sentence
  final String? exampleTranslation;
  final String? audioUrl;
  final String? partOfSpeech;
  final int difficulty;
  final List<String> tags;
  bool isFavourite;

  ExamVocabularyModel({
    required this.id,
    required this.exam,
    required this.level,
    required this.category,
    required this.burmeseWord,
    required this.romanization,
    required this.word,
    this.pronunciation,
    this.pinyin,
    this.hiragana,
    this.romaji,
    this.hangul,
    this.koreanRoman,
    this.thaiRoman,
    required this.meaning,
    this.exampleSentence,
    this.exampleRomanization,
    this.exampleTranslation,
    this.audioUrl,
    this.partOfSpeech,
    this.difficulty = 1,
    this.tags = const [],
    this.isFavourite = false,
  });

  factory ExamVocabularyModel.fromMap(String id, Map<String, dynamic> data) {
    return ExamVocabularyModel(
      id: id,
      exam: data['exam'] ?? '',
      level: data['level'] ?? '',
      category: data['category'] ?? '',
      burmeseWord: data['burmeseWord'] ?? '',
      romanization: data['romanization'] ?? '',
      word: data['word'] ?? '',
      pronunciation: data['pronunciation'],
      pinyin: data['pinyin'],
      hiragana: data['hiragana'],
      romaji: data['romaji'],
      hangul: data['hangul'],
      koreanRoman: data['koreanRoman'],
      thaiRoman: data['thaiRoman'],
      meaning: data['meaning'] ?? '',
      exampleSentence: data['exampleSentence'],
      exampleRomanization: data['exampleRomanization'],
      exampleTranslation: data['exampleTranslation'],
      audioUrl: data['audioUrl'],
      partOfSpeech: data['partOfSpeech'],
      difficulty: data['difficulty'] ?? 1,
      tags: List<String>.from(data['tags'] ?? []),
      isFavourite: data['isFavourite'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'exam': exam,
      'level': level,
      'category': category,
      'burmeseWord': burmeseWord,
      'romanization': romanization,
      'word': word,
      'pronunciation': pronunciation,
      'pinyin': pinyin,
      'hiragana': hiragana,
      'romaji': romaji,
      'hangul': hangul,
      'koreanRoman': koreanRoman,
      'thaiRoman': thaiRoman,
      'meaning': meaning,
      'exampleSentence': exampleSentence,
      'exampleRomanization': exampleRomanization,
      'exampleTranslation': exampleTranslation,
      'audioUrl': audioUrl,
      'partOfSpeech': partOfSpeech,
      'difficulty': difficulty,
      'tags': tags,
      'isFavourite': isFavourite,
    };
  }

  String getDisplayWord() {
    if (exam == 'hsk') return word;
    if (exam == 'jlpt') return word;
    if (exam == 'topik') return word;
    if (exam == 'thai') return word;
    return word;
  }

  String getPronunciationDisplay() {
    if (pinyin != null) return 'Pinyin: $pinyin';
    if (hiragana != null) return 'Hiragana: $hiragana';
    if (hangul != null) return 'Hangul: $hangul';
    if (thaiRoman != null) return 'Thai: $thaiRoman';
    if (pronunciation != null) return 'Pronunciation: $pronunciation';
    if (romaji != null) return 'Romaji: $romaji';
    if (koreanRoman != null) return 'Romaji: $koreanRoman';
    return '';
  }

  bool hasAudio() => audioUrl != null && audioUrl!.isNotEmpty;
}

// ✅ Category Model (for Learning Session) - 50+ Categories
class CategoryModel {
  final String id;
  final String name;
  final String icon;
  final Color color;
  final String description;
  final List<String> subCategories;
  final String group;

  CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.description = '',
    this.subCategories = const [],
    this.group = '',
  });

  static List<CategoryModel> get allCategories => [
    // ========== EVERYDAY LIFE ==========
    CategoryModel(
      id: 'daily_routine', 
      name: 'Daily Routine', 
      icon: '🌅', 
      color: const Color(0xFFFF6B6B), 
      description: 'Morning to night activities',
      group: 'Everyday Life'
    ),
    CategoryModel(
      id: 'home_living', 
      name: 'Home & Living', 
      icon: '🏠', 
      color: const Color(0xFF4ECDC4), 
      description: 'Rooms, furniture, household items',
      group: 'Everyday Life'
    ),
    CategoryModel(
      id: 'family', 
      name: 'Family & Relationships', 
      icon: '👨‍👩‍👧‍👦', 
      color: const Color(0xFFFFA07A), 
      description: 'Family members, relatives',
      group: 'Everyday Life'
    ),
    CategoryModel(
      id: 'friends', 
      name: 'Friends & Socializing', 
      icon: '🤝', 
      color: const Color(0xFF6C63FF), 
      description: 'Friends, social activities',
      group: 'Everyday Life'
    ),
    CategoryModel(
      id: 'neighborhood', 
      name: 'Neighborhood', 
      icon: '🏘️', 
      color: const Color(0xFF8D6E63), 
      description: 'Places in your neighborhood',
      group: 'Everyday Life'
    ),
    CategoryModel(
      id: 'weather_seasons', 
      name: 'Weather & Seasons', 
      icon: '🌤️', 
      color: const Color(0xFF4FC3F7), 
      description: 'Weather conditions, seasons',
      group: 'Everyday Life'
    ),

    // ========== FOOD & DINING ==========
    CategoryModel(
      id: 'food', 
      name: 'Food & Ingredients', 
      icon: '🥘', 
      color: const Color(0xFFFF5722), 
      description: 'Food items, ingredients',
      group: 'Food & Dining'
    ),
    CategoryModel(
      id: 'cooking', 
      name: 'Cooking & Recipes', 
      icon: '👨‍🍳', 
      color: const Color(0xFF795548), 
      description: 'Cooking methods, kitchen tools',
      group: 'Food & Dining'
    ),
    CategoryModel(
      id: 'restaurant', 
      name: 'Restaurant & Dining Out', 
      icon: '🍽️', 
      color: const Color(0xFFD84315), 
      description: 'Ordering food, restaurant vocabulary',
      group: 'Food & Dining'
    ),
    CategoryModel(
      id: 'beverages', 
      name: 'Beverages', 
      icon: '🍹', 
      color: const Color(0xFF26A69A), 
      description: 'Drinks, beverages',
      group: 'Food & Dining'
    ),
    CategoryModel(
      id: 'fruits_vegetables', 
      name: 'Fruits & Vegetables', 
      icon: '🍎', 
      color: const Color(0xFF66BB6A), 
      description: 'Fruits, vegetables, produce',
      group: 'Food & Dining'
    ),
    CategoryModel(
      id: 'meat_seafood', 
      name: 'Meat & Seafood', 
      icon: '🥩', 
      color: const Color(0xFFD32F2F), 
      description: 'Meat, poultry, seafood',
      group: 'Food & Dining'
    ),

    // ========== WORK & CAREER ==========
    CategoryModel(
      id: 'jobs', 
      name: 'Jobs & Professions', 
      icon: '👨‍💼', 
      color: const Color(0xFF1E88E5), 
      description: 'Various occupations',
      group: 'Work & Career'
    ),
    CategoryModel(
      id: 'office', 
      name: 'Office & Workplace', 
      icon: '🏢', 
      color: const Color(0xFF43A047), 
      description: 'Office equipment, workplace',
      group: 'Work & Career'
    ),
    CategoryModel(
      id: 'business', 
      name: 'Business & Finance', 
      icon: '💼', 
      color: const Color(0xFF0D47A1), 
      description: 'Business terms, finance',
      group: 'Work & Career'
    ),
    CategoryModel(
      id: 'interview', 
      name: 'Job Interview', 
      icon: '🤵', 
      color: const Color(0xFF4A148C), 
      description: 'Interview questions, phrases',
      group: 'Work & Career'
    ),
    CategoryModel(
      id: 'meetings', 
      name: 'Meetings & Presentations', 
      icon: '📊', 
      color: const Color(0xFFBF360C), 
      description: 'Meeting vocabulary, presentations',
      group: 'Work & Career'
    ),

    // ========== TRAVEL & TRANSPORTATION ==========
    CategoryModel(
      id: 'transportation', 
      name: 'Transportation', 
      icon: '🚗', 
      color: const Color(0xFF1565C0), 
      description: 'Vehicles, transport modes',
      group: 'Travel & Transportation'
    ),
    CategoryModel(
      id: 'travel', 
      name: 'Travel & Tourism', 
      icon: '✈️', 
      color: const Color(0xFF00838F), 
      description: 'Travel, tourist activities',
      group: 'Travel & Transportation'
    ),
    CategoryModel(
      id: 'hotel', 
      name: 'Hotel & Accommodation', 
      icon: '🏨', 
      color: const Color(0xFF4E342E), 
      description: 'Hotels, booking, accommodation',
      group: 'Travel & Transportation'
    ),
    CategoryModel(
      id: 'airport', 
      name: 'Airport & Flying', 
      icon: '🛫', 
      color: const Color(0xFF283593), 
      description: 'Airport, flight vocabulary',
      group: 'Travel & Transportation'
    ),
    CategoryModel(
      id: 'directions', 
      name: 'Directions & Navigation', 
      icon: '🧭', 
      color: const Color(0xFF00695C), 
      description: 'Giving and asking directions',
      group: 'Travel & Transportation'
    ),

    // ========== EDUCATION ==========
    CategoryModel(
      id: 'school', 
      name: 'School & University', 
      icon: '🎓', 
      color: const Color(0xFF0D47A1), 
      description: 'School subjects, university',
      group: 'Education'
    ),
    CategoryModel(
      id: 'classroom', 
      name: 'Classroom Vocabulary', 
      icon: '📖', 
      color: const Color(0xFFBF360C), 
      description: 'Classroom objects, activities',
      group: 'Education'
    ),
    CategoryModel(
      id: 'subjects', 
      name: 'School Subjects', 
      icon: '📚', 
      color: const Color(0xFF6A1B9A), 
      description: 'Academic subjects',
      group: 'Education'
    ),
    CategoryModel(
      id: 'exams', 
      name: 'Exams & Tests', 
      icon: '📝', 
      color: const Color(0xFFE65100), 
      description: 'Exam vocabulary, testing',
      group: 'Education'
    ),
    CategoryModel(
      id: 'studying', 
      name: 'Studying & Learning', 
      icon: '🧠', 
      color: const Color(0xFF2E7D32), 
      description: 'Study methods, learning',
      group: 'Education'
    ),

    // ========== SHOPPING & SERVICES ==========
    CategoryModel(
      id: 'shopping', 
      name: 'Shopping', 
      icon: '🛍️', 
      color: const Color(0xFF7B1FA2), 
      description: 'Shopping vocabulary',
      group: 'Shopping & Services'
    ),
    CategoryModel(
      id: 'clothing', 
      name: 'Clothing & Fashion', 
      icon: '👗', 
      color: const Color(0xFFE91E63), 
      description: 'Clothes, fashion, accessories',
      group: 'Shopping & Services'
    ),
    CategoryModel(
      id: 'bank', 
      name: 'Banking & Money', 
      icon: '🏦', 
      color: const Color(0xFF2E7D32), 
      description: 'Banking, money, transactions',
      group: 'Shopping & Services'
    ),
    CategoryModel(
      id: 'post_office', 
      name: 'Post Office', 
      icon: '📬', 
      color: const Color(0xFFBF360C), 
      description: 'Postal services, mailing',
      group: 'Shopping & Services'
    ),
    CategoryModel(
      id: 'pharmacy', 
      name: 'Pharmacy & Health', 
      icon: '💊', 
      color: const Color(0xFF00695C), 
      description: 'Medicine, pharmacy items',
      group: 'Shopping & Services'
    ),

    // ========== TECHNOLOGY ==========
    CategoryModel(
      id: 'technology', 
      name: 'Technology & Gadgets', 
      icon: '💻', 
      color: const Color(0xFF1A237E), 
      description: 'Tech devices, gadgets',
      group: 'Technology'
    ),
    CategoryModel(
      id: 'internet', 
      name: 'Internet & Social Media', 
      icon: '📱', 
      color: const Color(0xFF0D47A1), 
      description: 'Internet terms, social media',
      group: 'Technology'
    ),
    CategoryModel(
      id: 'software', 
      name: 'Software & Apps', 
      icon: '🖥️', 
      color: const Color(0xFF263238), 
      description: 'Software, applications',
      group: 'Technology'
    ),
    CategoryModel(
      id: 'computer_parts', 
      name: 'Computer Parts', 
      icon: '🖱️', 
      color: const Color(0xFF37474F), 
      description: 'Computer hardware, parts',
      group: 'Technology'
    ),

    // ========== LEISURE & ENTERTAINMENT ==========
    CategoryModel(
      id: 'hobbies', 
      name: 'Hobbies & Interests', 
      icon: '🎨', 
      color: const Color(0xFFFF6F00), 
      description: 'Hobbies, personal interests',
      group: 'Leisure & Entertainment'
    ),
    CategoryModel(
      id: 'sports', 
      name: 'Sports & Games', 
      icon: '⚽', 
      color: const Color(0xFF1B5E20), 
      description: 'Sports, games, activities',
      group: 'Leisure & Entertainment'
    ),
    CategoryModel(
      id: 'music', 
      name: 'Music & Instruments', 
      icon: '🎵', 
      color: const Color(0xFFD32F2F), 
      description: 'Music, instruments, genres',
      group: 'Leisure & Entertainment'
    ),
    CategoryModel(
      id: 'movies', 
      name: 'Movies & TV Shows', 
      icon: '🎬', 
      color: const Color(0xFF4A148C), 
      description: 'Movies, TV, cinema',
      group: 'Leisure & Entertainment'
    ),
    CategoryModel(
      id: 'books', 
      name: 'Books & Reading', 
      icon: '📚', 
      color: const Color(0xFF3E2723), 
      description: 'Books, reading, literature',
      group: 'Leisure & Entertainment'
    ),
    CategoryModel(
      id: 'art', 
      name: 'Art & Culture', 
      icon: '🎭', 
      color: const Color(0xFF4A148C), 
      description: 'Art, museums, culture',
      group: 'Leisure & Entertainment'
    ),
    CategoryModel(
      id: 'photography', 
      name: 'Photography', 
      icon: '📷', 
      color: const Color(0xFF263238), 
      description: 'Photography terms',
      group: 'Leisure & Entertainment'
    ),

    // ========== HEALTH & WELLNESS ==========
    CategoryModel(
      id: 'health', 
      name: 'Health & Wellness', 
      icon: '💪', 
      color: const Color(0xFF2E7D32), 
      description: 'Health, fitness, wellness',
      group: 'Health & Wellness'
    ),
    CategoryModel(
      id: 'hospital', 
      name: 'Hospital & Medical', 
      icon: '🏥', 
      color: const Color(0xFFD32F2F), 
      description: 'Hospital, medical terms',
      group: 'Health & Wellness'
    ),
    CategoryModel(
      id: 'exercise', 
      name: 'Exercise & Fitness', 
      icon: '🏋️', 
      color: const Color(0xFFFF6F00), 
      description: 'Exercise, fitness activities',
      group: 'Health & Wellness'
    ),
    CategoryModel(
      id: 'mental_health', 
      name: 'Mental Health', 
      icon: '🧘', 
      color: const Color(0xFF6A1B9A), 
      description: 'Mental health, mindfulness',
      group: 'Health & Wellness'
    ),

    // ========== SOCIETY & CULTURE ==========
    CategoryModel(
      id: 'culture', 
      name: 'Culture & Traditions', 
      icon: '🎭', 
      color: const Color(0xFF4A148C), 
      description: 'Cultural traditions',
      group: 'Society & Culture'
    ),
    CategoryModel(
      id: 'festivals', 
      name: 'Festivals & Celebrations', 
      icon: '🎉', 
      color: const Color(0xFFFF6F00), 
      description: 'Festivals, celebrations',
      group: 'Society & Culture'
    ),
    CategoryModel(
      id: 'politics', 
      name: 'Politics & Government', 
      icon: '🏛️', 
      color: const Color(0xFF1A237E), 
      description: 'Political vocabulary',
      group: 'Society & Culture'
    ),
    CategoryModel(
      id: 'environment', 
      name: 'Environment & Nature', 
      icon: '🌿', 
      color: const Color(0xFF2E7D32), 
      description: 'Environment, nature, conservation',
      group: 'Society & Culture'
    ),
    CategoryModel(
      id: 'animals', 
      name: 'Animals & Pets', 
      icon: '🐾', 
      color: const Color(0xFF795548), 
      description: 'Animals, pets, wildlife',
      group: 'Society & Culture'
    ),

    // ========== EMERGENCY & SAFETY ==========
    CategoryModel(
      id: 'emergency', 
      name: 'Emergency & Safety', 
      icon: '🚨', 
      color: const Color(0xFFD32F2F), 
      description: 'Emergency situations',
      group: 'Emergency & Safety'
    ),
    CategoryModel(
      id: 'first_aid', 
      name: 'First Aid', 
      icon: '🩹', 
      color: const Color(0xFFE53935), 
      description: 'First aid vocabulary',
      group: 'Emergency & Safety'
    ),

    // ========== MISCELLANEOUS ==========
    CategoryModel(
      id: 'time', 
      name: 'Time & Dates', 
      icon: '⏰', 
      color: const Color(0xFF1565C0), 
      description: 'Telling time, dates',
      group: 'General'
    ),
    CategoryModel(
      id: 'colors', 
      name: 'Colors', 
      icon: '🎨', 
      color: const Color(0xFFFF6F00), 
      description: 'Colors, shades',
      group: 'General'
    ),
    CategoryModel(
      id: 'numbers', 
      name: 'Numbers & Counting', 
      icon: '🔢', 
      color: const Color(0xFF0D47A1), 
      description: 'Numbers, counting, math',
      group: 'General'
    ),
    CategoryModel(
      id: 'greetings', 
      name: 'Greetings & Polite Expressions', 
      icon: '👋', 
      color: const Color(0xFF43A047), 
      description: 'Greetings, polite phrases',
      group: 'General'
    ),
    CategoryModel(
      id: 'basic_verbs', 
      name: 'Basic Verbs', 
      icon: '🏃', 
      color: const Color(0xFFFF6B6B), 
      description: 'Common everyday verbs',
      group: 'General'
    ),
    CategoryModel(
      id: 'basic_adjectives', 
      name: 'Basic Adjectives', 
      icon: '📝', 
      color: const Color(0xFF4ECDC4), 
      description: 'Common adjectives',
      group: 'General'
    ),
  ];

  static List<String> get allGroups {
    return allCategories.map((c) => c.group).toSet().toList();
  }

  // Get categories by group
  static List<CategoryModel> getCategoriesByGroup(String group) {
    return allCategories.where((c) => c.group == group).toList();
  }

  // Get category by ID
  static CategoryModel? getCategoryById(String id) {
    try {
      return allCategories.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }
}