// lib/models/achievement.dart
import 'user_model.dart';

class Achievement {
  final String id;
  final String name;
  final String description;
  final String icon;
  final String category;
  final int requiredValue;
  final int xpReward;

  Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.category,
    required this.requiredValue,
    this.xpReward = 10,
  });

  static List<Achievement> get allAchievements => [
    // Streak Achievements
    Achievement(
      id: 'streak_7',
      name: 'Week Warrior',
      description: '7 day learning streak',
      icon: '🔥',
      category: 'streak',
      requiredValue: 7,
      xpReward: 20,
    ),
    Achievement(
      id: 'streak_30',
      name: 'Dedicated Learner',
      description: '30 day learning streak',
      icon: '⭐',
      category: 'streak',
      requiredValue: 30,
      xpReward: 50,
    ),
    Achievement(
      id: 'streak_100',
      name: 'Century Club',
      description: '100 day learning streak',
      icon: '🏆',
      category: 'streak',
      requiredValue: 100,
      xpReward: 100,
    ),

    // Vocabulary Achievements
    Achievement(
      id: 'words_10',
      name: 'First Steps',
      description: 'Learn 10 words',
      icon: '📚',
      category: 'vocabulary',
      requiredValue: 10,
      xpReward: 10,
    ),
    Achievement(
      id: 'words_50',
      name: 'Word Collector',
      description: 'Learn 50 words',
      icon: '📖',
      category: 'vocabulary',
      requiredValue: 50,
      xpReward: 25,
    ),
    Achievement(
      id: 'words_100',
      name: 'Linguist',
      description: 'Learn 100 words',
      icon: '🎓',
      category: 'vocabulary',
      requiredValue: 100,
      xpReward: 50,
    ),
    Achievement(
      id: 'words_500',
      name: 'Language Master',
      description: 'Learn 500 words',
      icon: '👑',
      category: 'vocabulary',
      requiredValue: 500,
      xpReward: 100,
    ),

    // XP Achievements
    Achievement(
      id: 'xp_100',
      name: 'XP Collector',
      description: 'Earn 100 XP',
      icon: '💎',
      category: 'xp',
      requiredValue: 100,
      xpReward: 10,
    ),
    Achievement(
      id: 'xp_1000',
      name: 'XP Master',
      description: 'Earn 1000 XP',
      icon: '💎',
      category: 'xp',
      requiredValue: 1000,
      xpReward: 50,
    ),
    Achievement(
      id: 'xp_5000',
      name: 'XP Legend',
      description: 'Earn 5000 XP',
      icon: '💎',
      category: 'xp',
      requiredValue: 5000,
      xpReward: 100,
    ),

    // Level Achievements
    Achievement(
      id: 'level_5',
      name: 'Level 5 Achieved',
      description: 'Reach level 5',
      icon: '🌟',
      category: 'level',
      requiredValue: 5,
      xpReward: 20,
    ),
    Achievement(
      id: 'level_10',
      name: 'Level 10 Achieved',
      description: 'Reach level 10',
      icon: '🌟',
      category: 'level',
      requiredValue: 10,
      xpReward: 50,
    ),
    Achievement(
      id: 'level_25',
      name: 'Level 25 Achieved',
      description: 'Reach level 25',
      icon: '🌟',
      category: 'level',
      requiredValue: 25,
      xpReward: 100,
    ),
  ];

  static Achievement? getAchievement(String id) {
    try {
      return allAchievements.firstWhere((a) => a.id == id);
    } catch (e) {
      return null;
    }
  }

  static List<Achievement> getAchievementsForUser(UserModel user) {
    final unlocked = <Achievement>[];
    final unlockedIds = user.unlockedAchievements.toSet();

    for (final achievement in allAchievements) {
      if (unlockedIds.contains(achievement.id)) {
        unlocked.add(achievement);
      }
    }
    return unlocked;
  }

  static List<Achievement> getPendingAchievements(UserModel user) {
    final pending = <Achievement>[];
    final unlockedIds = user.unlockedAchievements.toSet();

    for (final achievement in allAchievements) {
      if (!unlockedIds.contains(achievement.id)) {
        if (isAchievementEligible(user, achievement)) {
          pending.add(achievement);
        }
      }
    }
    return pending;
  }

  static bool isAchievementEligible(UserModel user, Achievement achievement) {
    switch (achievement.category) {
      case 'streak':
        return user.streak >= achievement.requiredValue;
      case 'vocabulary':
        return user.wordsLearned >= achievement.requiredValue;
      case 'xp':
        return user.totalXP >= achievement.requiredValue;
      case 'level':
        return user.level >= achievement.requiredValue;
      default:
        return false;
    }
  }
}