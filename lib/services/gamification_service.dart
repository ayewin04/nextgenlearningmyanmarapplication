// lib/services/gamification_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/achievement.dart';

class GamificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const int XP_PER_WORD = 10;
  static const int XP_PER_LEVEL = 200;

  Future<UserModel> updateProgress({
    required String userId,
    required String language,
    required String category,
    required String wordId,
  }) async {
    print('🚀 [Gamification] updateProgress called for word: $wordId');
    
    final userRef = _firestore.collection('users').doc(userId);
    final userDoc = await userRef.get();
    
    if (!userDoc.exists) {
      throw Exception('User not found');
    }

    final user = UserModel.fromFirestore(userDoc);
    
    // ✅ Get learned words from dailyTasks
    Map<String, bool> learnedWords = {};
    if (user.dailyTasks.containsKey('learnedWords')) {
      learnedWords = Map<String, bool>.from(user.dailyTasks['learnedWords'] as Map);
    }
    
    // ✅ Check if word was already learned
    if (learnedWords[wordId] == true) {
      print('⚠️ Word already learned: $wordId - No XP awarded');
      return user;
    }

    print('✅ New word detected! Awarding 10 XP...');
    
    // ✅ Mark word as learned
    learnedWords[wordId] = true;
    
    // ✅ Calculate new XP
    final newXP = user.totalXP + XP_PER_WORD;
    final newLevel = _calculateLevel(newXP);
    final streakData = await _updateStreak(user);
    final newWeeklyXP = user.weeklyXP + XP_PER_WORD;
    
    // ✅ Update daily tasks
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month}-${today.day}';
    final updatedDailyTasks = Map<String, dynamic>.from(user.dailyTasks);
    updatedDailyTasks[todayKey] = true;
    updatedDailyTasks['learnedWords'] = learnedWords; // ✅ Store as Map

    // ✅ Update Firestore
    await userRef.update({
      'totalXP': newXP,
      'level': newLevel,
      'streak': streakData['streak'],
      'lastPracticeDate': FieldValue.serverTimestamp(),
      'wordsLearned': FieldValue.increment(1),
      'weeklyXP': newWeeklyXP,
      'dailyTasks': updatedDailyTasks,
      'wordsPerLanguage.${language.toLowerCase()}': FieldValue.increment(1),
      'wordsPerCategory.${category.toLowerCase()}': FieldValue.increment(1),
    });

    // ✅ Return updated user
    final updatedUser = user.copyWith(
      totalXP: newXP,
      level: newLevel,
      streak: streakData['streak'],
      weeklyXP: newWeeklyXP,
      dailyTasks: updatedDailyTasks,
      wordsLearned: user.wordsLearned + 1,
    );

    await _checkAchievements(userId, updatedUser);

    print('✅ XP awarded! New total: $newXP');
    return updatedUser;
  }

  Future<Map<String, dynamic>> _updateStreak(UserModel user) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    if (user.lastPracticeDate == null) {
      return {'streak': 1, 'isNewDay': true};
    }

    final lastPractice = DateTime(
      user.lastPracticeDate!.year,
      user.lastPracticeDate!.month,
      user.lastPracticeDate!.day,
    );

    final difference = today.difference(lastPractice).inDays;

    if (difference == 0) {
      return {'streak': user.streak, 'isNewDay': false};
    } else if (difference == 1) {
      return {'streak': user.streak + 1, 'isNewDay': true};
    } else {
      return {'streak': 1, 'isNewDay': true};
    }
  }

  int _calculateLevel(int xp) {
    return (xp / XP_PER_LEVEL).floor() + 1;
  }

  Future<void> _checkAchievements(String userId, UserModel user) async {
    final pending = Achievement.getPendingAchievements(user);
    
    if (pending.isEmpty) return;

    final userRef = _firestore.collection('users').doc(userId);
    final unlockedIds = user.unlockedAchievements.toList();
    final newAchievements = <Achievement>[];

    for (final achievement in pending) {
      if (Achievement.isAchievementEligible(user, achievement)) {
        unlockedIds.add(achievement.id);
        newAchievements.add(achievement);
        
        await userRef.update({
          'totalXP': FieldValue.increment(achievement.xpReward),
        });
      }
    }

    if (newAchievements.isNotEmpty) {
      await userRef.update({
        'unlockedAchievements': unlockedIds,
      });
    }
  }

  // ✅ Get learned words for a user
  Future<Map<String, bool>> getLearnedWords(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return {};
      
      final data = userDoc.data()!;
      final dailyTasks = data['dailyTasks'] ?? {};
      return Map<String, bool>.from(dailyTasks['learnedWords'] as Map? ?? {});
    } catch (e) {
      return {};
    }
  }

  // ✅ Get top 10 learners with real-time updates
  Stream<List<Map<String, dynamic>>> streamTop10Learners() {
    return _firestore
        .collection('users')
        .orderBy('totalXP', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) {
          final List<Map<String, dynamic>> topLearners = [];
          int rank = 1;
          for (final doc in snapshot.docs) {
            final data = doc.data() as Map<String, dynamic>;
            topLearners.add({
              'userId': doc.id,
              'name': data['name'] ?? 'User',
              'totalXP': data['totalXP'] ?? 0,
              'weeklyXP': data['weeklyXP'] ?? 0,
              'level': data['level'] ?? 1,
              'streak': data['streak'] ?? 0,
              'wordsLearned': data['wordsLearned'] ?? 0,
              'rank': rank,
            });
            rank++;
          }
          return topLearners;
        });
  }

  // ✅ Get user rank with real-time updates
  Stream<int> streamUserRank(String userId) {
    return _firestore
        .collection('users')
        .snapshots()
        .map((snapshot) {
          // Find user's XP
          String? userXP;
          for (final doc in snapshot.docs) {
            if (doc.id == userId) {
              final data = doc.data() as Map<String, dynamic>;
              userXP = data['totalXP']?.toString();
              break;
            }
          }
          
          if (userXP == null) return 0;
          
          // Count users with more XP
          int rank = 1;
          for (final doc in snapshot.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final xp = data['totalXP']?.toString() ?? '0';
            if (int.parse(xp) > int.parse(userXP)) {
              rank++;
            }
          }
          return rank;
        });
  }

  Future<List<Map<String, dynamic>>> getLeaderboard({
    int limit = 20,
    String period = 'all',
  }) async {
    try {
      Query query = _firestore
          .collection('users')
          .orderBy('totalXP', descending: true)
          .limit(limit);

      if (period == 'weekly') {
        query = _firestore
            .collection('users')
            .orderBy('weeklyXP', descending: true)
            .limit(limit);
      }

      final snapshot = await query.get();
      
      final List<Map<String, dynamic>> leaderboard = [];
      int rank = 1;

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        leaderboard.add({
          'userId': doc.id,
          'name': data['name'] ?? 'User',
          'totalXP': data['totalXP'] ?? 0,
          'weeklyXP': data['weeklyXP'] ?? 0,
          'level': data['level'] ?? 1,
          'streak': data['streak'] ?? 0,
          'rank': rank,
          'isTop3': rank <= 3,
        });
        rank++;
      }

      return leaderboard;
    } catch (e) {
      throw Exception('Failed to get leaderboard: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getTop10Learners() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .orderBy('totalXP', descending: true)
          .limit(10)
          .get();

      final List<Map<String, dynamic>> topLearners = [];
      int rank = 1;

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        topLearners.add({
          'userId': doc.id,
          'name': data['name'] ?? 'User',
          'totalXP': data['totalXP'] ?? 0,
          'weeklyXP': data['weeklyXP'] ?? 0,
          'level': data['level'] ?? 1,
          'streak': data['streak'] ?? 0,
          'wordsLearned': data['wordsLearned'] ?? 0,
          'rank': rank,
        });
        rank++;
      }

      return topLearners;
    } catch (e) {
      throw Exception('Failed to get top 10 learners: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getTop3Users() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .orderBy('totalXP', descending: true)
          .limit(3)
          .get();

      final List<Map<String, dynamic>> topUsers = [];
      int rank = 1;

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        topUsers.add({
          'userId': doc.id,
          'name': data['name'] ?? 'User',
          'totalXP': data['totalXP'] ?? 0,
          'level': data['level'] ?? 1,
          'streak': data['streak'] ?? 0,
          'rank': rank,
        });
        rank++;
      }

      return topUsers;
    } catch (e) {
      throw Exception('Failed to get top 3 users: $e');
    }
  }

  Future<int> getUserRank(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return 0;

      final userXP = userDoc.data()?['totalXP'] ?? 0;

      final snapshot = await _firestore
          .collection('users')
          .where('totalXP', isGreaterThan: userXP)
          .count()
          .get();

      final count = snapshot.count ?? 0;
      return count + 1;
    } catch (e) {
      return 0;
    }
  }

  Future<bool> isWordLearned({
    required String userId,
    required String wordId,
  }) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return false;

      final data = userDoc.data()!;
      final dailyTasks = data['dailyTasks'] ?? {};
      final learnedWords = Map<String, bool>.from(dailyTasks['learnedWords'] as Map? ?? {});
      
      return learnedWords[wordId] == true;
    } catch (e) {
      return false;
    }
  }

  Future<void> resetWeeklyXP() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .get();

      final batch = _firestore.batch();
      
      for (final doc in snapshot.docs) {
        final userRef = _firestore.collection('users').doc(doc.id);
        batch.update(userRef, {'weeklyXP': 0});
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to reset weekly XP: $e');
    }
  }

  // Real-time user progress stream
  Stream<UserModel> streamUserProgress(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) => UserModel.fromFirestore(snapshot));
  }
}