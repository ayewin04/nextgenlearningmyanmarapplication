// lib/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String name;
  final List<String> targetLanguages;
  final int streak;
  final int totalXP;
  final int level;
  final DateTime? createdAt;
  final Map<String, dynamic>? examProgress;
  final Map<String, dynamic>? settings;
  final List<String> favourites;
  final int wordsLearned;
  final Map<String, int> wordsPerCategory;
  final Map<String, int> wordsPerLanguage;
  final DateTime? lastPracticeDate;
  final List<String> unlockedAchievements;
  final int weeklyXP;
  final int weeklyRank;
  final Map<String, dynamic> dailyTasks;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    this.targetLanguages = const [],
    this.streak = 0,
    this.totalXP = 0,
    this.level = 1,
    this.createdAt,
    this.examProgress,
    this.settings,
    this.favourites = const [],
    this.wordsLearned = 0,
    this.wordsPerCategory = const {},
    this.wordsPerLanguage = const {},
    this.lastPracticeDate,
    this.unlockedAchievements = const [],
    this.weeklyXP = 0,
    this.weeklyRank = 0,
    this.dailyTasks = const {},
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      targetLanguages: List<String>.from(data['targetLanguages'] ?? []),
      streak: data['streak'] ?? 0,
      totalXP: data['totalXP'] ?? 0,
      level: data['level'] ?? 1,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      examProgress: data['examProgress'] ?? {},
      settings: data['settings'] ?? {},
      favourites: List<String>.from(data['favourites'] ?? []),
      wordsLearned: data['wordsLearned'] ?? 0,
      wordsPerCategory: Map<String, int>.from(data['wordsPerCategory'] ?? {}),
      wordsPerLanguage: Map<String, int>.from(data['wordsPerLanguage'] ?? {}),
      lastPracticeDate: (data['lastPracticeDate'] as Timestamp?)?.toDate(),
      unlockedAchievements: List<String>.from(data['unlockedAchievements'] ?? []),
      weeklyXP: data['weeklyXP'] ?? 0,
      weeklyRank: data['weeklyRank'] ?? 0,
      dailyTasks: Map<String, dynamic>.from(data['dailyTasks'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'targetLanguages': targetLanguages,
      'streak': streak,
      'totalXP': totalXP,
      'level': level,
      'createdAt': FieldValue.serverTimestamp(),
      'examProgress': examProgress,
      'settings': settings,
      'favourites': favourites,
      'wordsLearned': wordsLearned,
      'wordsPerCategory': wordsPerCategory,
      'wordsPerLanguage': wordsPerLanguage,
      'lastPracticeDate': lastPracticeDate != null 
          ? Timestamp.fromDate(lastPracticeDate!) 
          : null,
      'unlockedAchievements': unlockedAchievements,
      'weeklyXP': weeklyXP,
      'weeklyRank': weeklyRank,
      'dailyTasks': dailyTasks,
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    List<String>? targetLanguages,
    int? streak,
    int? totalXP,
    int? level,
    DateTime? createdAt,
    Map<String, dynamic>? examProgress,
    Map<String, dynamic>? settings,
    List<String>? favourites,
    int? wordsLearned,
    Map<String, int>? wordsPerCategory,
    Map<String, int>? wordsPerLanguage,
    DateTime? lastPracticeDate,
    List<String>? unlockedAchievements,
    int? weeklyXP,
    int? weeklyRank,
    Map<String, dynamic>? dailyTasks,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      targetLanguages: targetLanguages ?? this.targetLanguages,
      streak: streak ?? this.streak,
      totalXP: totalXP ?? this.totalXP,
      level: level ?? this.level,
      createdAt: createdAt ?? this.createdAt,
      examProgress: examProgress ?? this.examProgress,
      settings: settings ?? this.settings,
      favourites: favourites ?? this.favourites,
      wordsLearned: wordsLearned ?? this.wordsLearned,
      wordsPerCategory: wordsPerCategory ?? this.wordsPerCategory,
      wordsPerLanguage: wordsPerLanguage ?? this.wordsPerLanguage,
      lastPracticeDate: lastPracticeDate ?? this.lastPracticeDate,
      unlockedAchievements: unlockedAchievements ?? this.unlockedAchievements,
      weeklyXP: weeklyXP ?? this.weeklyXP,
      weeklyRank: weeklyRank ?? this.weeklyRank,
      dailyTasks: dailyTasks ?? this.dailyTasks,
    );
  }

  // ✅ Helper method to check if word is learned
  bool isWordLearned(String wordId) {
    final learnedWords = Map<String, bool>.from(
      dailyTasks['learnedWords'] as Map? ?? {}
    );
    return learnedWords[wordId] == true;
  }

  // ✅ Helper method to get total learned words
  int getTotalLearnedWords() {
    final learnedWords = Map<String, bool>.from(
      dailyTasks['learnedWords'] as Map? ?? {}
    );
    return learnedWords.length;
  }

  // ✅ Helper method to mark a word as learned
  Map<String, dynamic> markWordLearned(String wordId) {
    final learnedWords = Map<String, bool>.from(
      dailyTasks['learnedWords'] as Map? ?? {}
    );
    learnedWords[wordId] = true;
    final updatedDailyTasks = Map<String, dynamic>.from(dailyTasks);
    updatedDailyTasks['learnedWords'] = learnedWords;
    return updatedDailyTasks;
  }

  // ✅ Helper method to get words learned today
  int getWordsLearnedToday() {
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month}-${today.day}';
    return dailyTasks[todayKey] == true ? 1 : 0;
  }

  // ✅ Helper method to get XP progress to next level
  int getXPToNextLevel() {
    final xpForCurrentLevel = (level - 1) * 200;
    final xpForNextLevel = level * 200;
    return xpForNextLevel - totalXP;
  }

  // ✅ Helper method to get XP progress percentage
  double getLevelProgress() {
    final xpForCurrentLevel = (level - 1) * 200;
    final xpForNextLevel = level * 200;
    final progress = (totalXP - xpForCurrentLevel) / 
        (xpForNextLevel - xpForCurrentLevel);
    return progress.clamp(0.0, 1.0);
  }

  // ✅ Helper method to check if user has any language selected
  bool hasLanguages() {
    return targetLanguages.isNotEmpty;
  }

  // ✅ Helper method to get user's rank tier
  String getRankTier() {
    if (level >= 50) return 'Legendary';
    if (level >= 25) return 'Master';
    if (level >= 15) return 'Expert';
    if (level >= 10) return 'Advanced';
    if (level >= 5) return 'Intermediate';
    return 'Beginner';
  }

  // ✅ Helper method to get user's rank emoji
  String getRankEmoji() {
    if (level >= 50) return '👑';
    if (level >= 25) return '💎';
    if (level >= 15) return '🌟';
    if (level >= 10) return '⭐';
    if (level >= 5) return '📚';
    return '🌱';
  }
}