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

// ✅ Category Model (for Learning Session)
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
    CategoryModel(id: 'daily_routine', name: 'Daily Routine', icon: '🌅', color: const Color(0xFFFF6B6B), group: 'Everyday Life'),
    CategoryModel(id: 'home_living', name: 'Home & Living', icon: '🏠', color: const Color(0xFF4ECDC4), group: 'Everyday Life'),
    CategoryModel(id: 'family', name: 'Family & Relationships', icon: '👨‍👩‍👧‍👦', color: const Color(0xFFFFA07A), group: 'Everyday Life'),
    CategoryModel(id: 'friends', name: 'Friends & Socializing', icon: '🤝', color: const Color(0xFF6C63FF), group: 'Everyday Life'),
    CategoryModel(id: 'food', name: 'Food & Ingredients', icon: '🥘', color: const Color(0xFFFF5722), group: 'Food & Dining'),
    CategoryModel(id: 'cooking', name: 'Cooking & Recipes', icon: '👨‍🍳', color: const Color(0xFF795548), group: 'Food & Dining'),
    CategoryModel(id: 'jobs', name: 'Jobs & Professions', icon: '👨‍💼', color: const Color(0xFF1E88E5), group: 'Work & Career'),
    CategoryModel(id: 'office', name: 'Office & Workplace', icon: '🏢', color: const Color(0xFF43A047), group: 'Work & Career'),
    CategoryModel(id: 'transportation', name: 'Transportation', icon: '🚗', color: const Color(0xFF1565C0), group: 'Travel & Transportation'),
    CategoryModel(id: 'travel', name: 'Travel & Tourism', icon: '✈️', color: const Color(0xFF00838F), group: 'Travel & Transportation'),
    CategoryModel(id: 'school', name: 'School & University', icon: '🎓', color: const Color(0xFF0D47A1), group: 'Education'),
    CategoryModel(id: 'classroom', name: 'Classroom Vocabulary', icon: '📖', color: const Color(0xFFBF360C), group: 'Education'),
    CategoryModel(id: 'shopping', name: 'Shopping', icon: '🛍️', color: const Color(0xFF7B1FA2), group: 'Shopping & Services'),
    CategoryModel(id: 'technology', name: 'Technology & Gadgets', icon: '💻', color: const Color(0xFF1A237E), group: 'Technology'),
    CategoryModel(id: 'hobbies', name: 'Hobbies & Interests', icon: '🎨', color: const Color(0xFFFF6F00), group: 'Leisure & Entertainment'),
    CategoryModel(id: 'sports', name: 'Sports & Games', icon: '⚽', color: const Color(0xFF1B5E20), group: 'Leisure & Entertainment'),
    CategoryModel(id: 'culture', name: 'Culture & Traditions', icon: '🎭', color: const Color(0xFF4A148C), group: 'Society & Culture'),
  ];

  static List<String> get allGroups {
    return allCategories.map((c) => c.group).toSet().toList();
  }
}