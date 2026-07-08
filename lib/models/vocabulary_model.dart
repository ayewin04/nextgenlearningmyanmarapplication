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

// ✅ Category Model
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
    // Everyday Life
    CategoryModel(
      id: 'daily_routine',
      name: 'Daily Routine',
      icon: '🌅',
      color: const Color(0xFFFF6B6B),
      description: 'Morning to night activities',
      group: 'Everyday Life',
    ),
    CategoryModel(
      id: 'home_living',
      name: 'Home & Living',
      icon: '🏠',
      color: const Color(0xFF4ECDC4),
      description: 'Rooms, furniture, household items',
      group: 'Everyday Life',
    ),
    CategoryModel(
      id: 'family',
      name: 'Family & Relationships',
      icon: '👨‍👩‍👧‍👦',
      color: const Color(0xFFFFA07A),
      description: 'Family members, relatives',
      group: 'Everyday Life',
    ),
    CategoryModel(
      id: 'friends',
      name: 'Friends & Socializing',
      icon: '🤝',
      color: const Color(0xFF6C63FF),
      description: 'Social events, meeting people',
      group: 'Everyday Life',
    ),
    CategoryModel(
      id: 'neighborhood',
      name: 'Neighborhood',
      icon: '🏘️',
      color: const Color(0xFF4CAF50),
      description: 'Places nearby, community',
      group: 'Everyday Life',
    ),
    CategoryModel(
      id: 'weather',
      name: 'Weather & Seasons',
      icon: '🌤️',
      color: const Color(0xFF2196F3),
      description: 'Weather conditions, seasons',
      group: 'Everyday Life',
    ),
    CategoryModel(
      id: 'time',
      name: 'Time & Calendar',
      icon: '📅',
      color: const Color(0xFFFF9800),
      description: 'Days, months, telling time',
      group: 'Everyday Life',
    ),
    CategoryModel(
      id: 'colors',
      name: 'Colors & Shapes',
      icon: '🎨',
      color: const Color(0xFFE91E63),
      description: 'Colors, shapes, appearance',
      group: 'Everyday Life',
    ),
    CategoryModel(
      id: 'numbers',
      name: 'Numbers & Measurements',
      icon: '🔢',
      color: const Color(0xFF9C27B0),
      description: 'Counting, math, measurements',
      group: 'Everyday Life',
    ),
    CategoryModel(
      id: 'clothing',
      name: 'Clothing & Fashion',
      icon: '👗',
      color: const Color(0xFF00BCD4),
      description: 'Clothes, accessories, fashion',
      group: 'Everyday Life',
    ),

    // Food & Dining
    CategoryModel(
      id: 'food',
      name: 'Food & Ingredients',
      icon: '🥘',
      color: const Color(0xFFFF5722),
      description: 'Common foods, ingredients',
      group: 'Food & Dining',
    ),
    CategoryModel(
      id: 'cooking',
      name: 'Cooking & Recipes',
      icon: '👨‍🍳',
      color: const Color(0xFF795548),
      description: 'Cooking methods, recipes',
      group: 'Food & Dining',
    ),
    CategoryModel(
      id: 'restaurants',
      name: 'Restaurants & Dining',
      icon: '🍽️',
      color: const Color(0xFF3F51B5),
      description: 'Ordering food, menu items',
      group: 'Food & Dining',
    ),
    CategoryModel(
      id: 'drinks',
      name: 'Drinks & Beverages',
      icon: '☕',
      color: const Color(0xFF8D6E63),
      description: 'Coffee, tea, juice, drinks',
      group: 'Food & Dining',
    ),
    CategoryModel(
      id: 'nutrition',
      name: 'Diet & Nutrition',
      icon: '🥗',
      color: const Color(0xFF4CAF50),
      description: 'Healthy eating, diets',
      group: 'Food & Dining',
    ),

    // Health & Wellness
    CategoryModel(
      id: 'body_parts',
      name: 'Body Parts',
      icon: '🦴',
      color: const Color(0xFFE53935),
      description: 'Human body parts, anatomy',
      group: 'Health & Wellness',
    ),
    CategoryModel(
      id: 'health',
      name: 'Health & Illness',
      icon: '🤒',
      color: const Color(0xFFFF7043),
      description: 'Symptoms, common illnesses',
      group: 'Health & Wellness',
    ),
    CategoryModel(
      id: 'doctor',
      name: 'Doctor & Hospital',
      icon: '🏥',
      color: const Color(0xFF26C6DA),
      description: 'Medical visits, treatments',
      group: 'Health & Wellness',
    ),
    CategoryModel(
      id: 'fitness',
      name: 'Fitness & Exercise',
      icon: '💪',
      color: const Color(0xFF66BB6A),
      description: 'Exercise, gym, sports',
      group: 'Health & Wellness',
    ),
    CategoryModel(
      id: 'mental_health',
      name: 'Mental Health',
      icon: '🧠',
      color: const Color(0xFFAB47BC),
      description: 'Emotions, mental wellbeing',
      group: 'Health & Wellness',
    ),

    // Work & Career
    CategoryModel(
      id: 'jobs',
      name: 'Jobs & Professions',
      icon: '👨‍💼',
      color: const Color(0xFF1E88E5),
      description: 'Career names, job descriptions',
      group: 'Work & Career',
    ),
    CategoryModel(
      id: 'office',
      name: 'Office & Workplace',
      icon: '🏢',
      color: const Color(0xFF43A047),
      description: 'Office items, workplace',
      group: 'Work & Career',
    ),
    CategoryModel(
      id: 'business',
      name: 'Business & Finance',
      icon: '💰',
      color: const Color(0xFFFDD835),
      description: 'Money, banking, business',
      group: 'Work & Career',
    ),
    CategoryModel(
      id: 'meetings',
      name: 'Meetings & Presentations',
      icon: '📊',
      color: const Color(0xFFFF6F00),
      description: 'Meeting vocabulary, presentations',
      group: 'Work & Career',
    ),
    CategoryModel(
      id: 'job_search',
      name: 'Job Search & Interviews',
      icon: '📝',
      color: const Color(0xFF6D4C41),
      description: 'Applying for jobs, interviews',
      group: 'Work & Career',
    ),

    // Travel & Transportation
    CategoryModel(
      id: 'transportation',
      name: 'Transportation',
      icon: '🚗',
      color: const Color(0xFF1565C0),
      description: 'Cars, trains, planes, buses',
      group: 'Travel & Transportation',
    ),
    CategoryModel(
      id: 'travel',
      name: 'Travel & Tourism',
      icon: '✈️',
      color: const Color(0xFF00838F),
      description: 'Traveling, hotels, sightseeing',
      group: 'Travel & Transportation',
    ),
    CategoryModel(
      id: 'directions',
      name: 'Directions & Navigation',
      icon: '🧭',
      color: const Color(0xFF2E7D32),
      description: 'Asking directions, maps, GPS',
      group: 'Travel & Transportation',
    ),
    CategoryModel(
      id: 'airport',
      name: 'Airports & Flights',
      icon: '🛫',
      color: const Color(0xFF4A148C),
      description: 'Airport terms, flying, boarding',
      group: 'Travel & Transportation',
    ),
    CategoryModel(
      id: 'accommodation',
      name: 'Accommodation',
      icon: '🏨',
      color: const Color(0xFF00695C),
      description: 'Hotels, hostels, rentals',
      group: 'Travel & Transportation',
    ),

    // Education
    CategoryModel(
      id: 'school',
      name: 'School & University',
      icon: '🎓',
      color: const Color(0xFF0D47A1),
      description: 'Subjects, campus, student life',
      group: 'Education',
    ),
    CategoryModel(
      id: 'classroom',
      name: 'Classroom Vocabulary',
      icon: '📖',
      color: const Color(0xFFBF360C),
      description: 'Classroom items, teacher',
      group: 'Education',
    ),
    CategoryModel(
      id: 'exams',
      name: 'Exams & Tests',
      icon: '📝',
      color: const Color(0xFFE65100),
      description: 'Test types, studying, results',
      group: 'Education',
    ),
    CategoryModel(
      id: 'study_skills',
      name: 'Learning & Study Skills',
      icon: '🧠',
      color: const Color(0xFF4E342E),
      description: 'Study methods, note-taking',
      group: 'Education',
    ),

    // Shopping & Services
    CategoryModel(
      id: 'shopping',
      name: 'Shopping',
      icon: '🛍️',
      color: const Color(0xFF7B1FA2),
      description: 'Stores, products, buying',
      group: 'Shopping & Services',
    ),
    CategoryModel(
      id: 'money',
      name: 'Money & Banking',
      icon: '💳',
      color: const Color(0xFFF9A825),
      description: 'Currency, payments, banking',
      group: 'Shopping & Services',
    ),
    CategoryModel(
      id: 'services',
      name: 'Services',
      icon: '🛠️',
      color: const Color(0xFF5D4037),
      description: 'Repair, cleaning, services',
      group: 'Shopping & Services',
    ),
    CategoryModel(
      id: 'online_shopping',
      name: 'Online Shopping',
      icon: '📦',
      color: const Color(0xFF00838F),
      description: 'E-commerce, delivery',
      group: 'Shopping & Services',
    ),

    // Technology
    CategoryModel(
      id: 'technology',
      name: 'Technology & Gadgets',
      icon: '💻',
      color: const Color(0xFF1A237E),
      description: 'Computers, phones, devices',
      group: 'Technology',
    ),
    CategoryModel(
      id: 'internet',
      name: 'Internet & Social Media',
      icon: '🌐',
      color: const Color(0xFF00796B),
      description: 'Websites, social media',
      group: 'Technology',
    ),
    CategoryModel(
      id: 'ai',
      name: 'AI & Emerging Tech',
      icon: '🤖',
      color: const Color(0xFF37474F),
      description: 'AI, robotics, innovation',
      group: 'Technology',
    ),

    // Leisure & Entertainment
    CategoryModel(
      id: 'hobbies',
      name: 'Hobbies & Interests',
      icon: '🎨',
      color: const Color(0xFFFF6F00),
      description: 'Personal interests, activities',
      group: 'Leisure & Entertainment',
    ),
    CategoryModel(
      id: 'sports',
      name: 'Sports & Games',
      icon: '⚽',
      color: const Color(0xFF1B5E20),
      description: 'Sports, games, competitions',
      group: 'Leisure & Entertainment',
    ),
    CategoryModel(
      id: 'music',
      name: 'Music & Arts',
      icon: '🎵',
      color: const Color(0xFF880E4F),
      description: 'Music genres, instruments, arts',
      group: 'Leisure & Entertainment',
    ),
    CategoryModel(
      id: 'movies',
      name: 'Movies & TV Shows',
      icon: '🎬',
      color: const Color(0xFF311B92),
      description: 'Film types, cinema, TV shows',
      group: 'Leisure & Entertainment',
    ),
    CategoryModel(
      id: 'reading',
      name: 'Reading & Literature',
      icon: '📚',
      color: const Color(0xFF4E342E),
      description: 'Books, magazines, newspapers',
      group: 'Leisure & Entertainment',
    ),

    // Society & Culture
    CategoryModel(
      id: 'culture',
      name: 'Culture & Traditions',
      icon: '🎭',
      color: const Color(0xFF4A148C),
      description: 'Cultural practices, customs',
      group: 'Society & Culture',
    ),
    CategoryModel(
      id: 'history',
      name: 'History & Politics',
      icon: '🏛️',
      color: const Color(0xFF3E2723),
      description: 'Historical events, politics',
      group: 'Society & Culture',
    ),
    CategoryModel(
      id: 'social_issues',
      name: 'Social Issues',
      icon: '🌎',
      color: const Color(0xFF00695C),
      description: 'Environment, human rights',
      group: 'Society & Culture',
    ),
    CategoryModel(
      id: 'religion',
      name: 'Religion & Beliefs',
      icon: '🙏',
      color: const Color(0xFF4E342E),
      description: 'Religious practices, beliefs',
      group: 'Society & Culture',
    ),
  ];

  static List<String> get allGroups {
    return allCategories.map((c) => c.group).toSet().toList();
  }
}