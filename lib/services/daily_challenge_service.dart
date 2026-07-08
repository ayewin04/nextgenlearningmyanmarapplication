// lib/services/daily_challenge_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/daily_challenge_model.dart';
import '../models/question_model.dart';

class DailyChallengeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Generate daily challenge for a specific language
  Future<DailyChallengeModel> generateDailyChallenge({
    required String userId,
    required String exam,
    int questionsCount = 5,
  }) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);

    // Check if challenge already exists for this language today
    final existing = await _getTodayChallenge(userId, exam, startOfDay);
    if (existing != null) {
      return existing;
    }

    // Get user's answered questions for this language
    final answeredIds = await _getAnsweredQuestionIds(userId, exam);

    // Fetch questions for this language
    final questions = await _getQuestionsForChallenge(
      exam: exam,
      excludeIds: answeredIds,
      limit: questionsCount * 2,
    );

    // Select random questions
    final selectedQuestions = _selectRandomQuestions(questions, questionsCount);

    // Create challenge questions
    final challengeQuestions = selectedQuestions.map((q) {
      return DailyChallengeQuestion(
        questionId: q.id,
        exam: q.exam,
        level: q.level,
        category: q.category,
        questionText: q.questionText,
        options: q.options ?? [],
        correctAnswer: q.correctAnswer ?? '',
      );
    }).toList();

    // Get language streak
    final languageStreak = await _getLanguageStreak(userId, exam);

    // Get global streak
    final globalStreak = await _getGlobalStreak(userId);

    // Create challenge
    final challenge = DailyChallengeModel(
      id: '',
      userId: userId,
      exam: exam,
      date: startOfDay,
      questions: challengeQuestions,
      totalQuestions: challengeQuestions.length,
      streak: globalStreak,
      languageStreak: languageStreak,
      answeredQuestionIds: answeredIds,
    );

    // Save to Firestore
    final docRef = await _firestore
        .collection('daily_challenges')
        .add(challenge.toMap());

    return challenge.copyWith(id: docRef.id);
  }

  // Get today's challenge for a specific language
  Future<DailyChallengeModel?> _getTodayChallenge(
    String userId,
    String exam,
    DateTime startOfDay,
  ) async {
    final snapshot = await _firestore
        .collection('daily_challenges')
        .where('userId', isEqualTo: userId)
        .where('exam', isEqualTo: exam)
        .where('date', isEqualTo: Timestamp.fromDate(startOfDay))
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return DailyChallengeModel.fromMap(
        snapshot.docs.first.id,
        snapshot.docs.first.data(),
      );
    }
    return null;
  }

  // Get all daily challenges for a user (dashboard)
  Future<List<DailyChallengeModel>> getAllDailyChallenges({
    required String userId,
    required List<String> languages,
  }) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);

    final List<DailyChallengeModel> challenges = [];

    for (final exam in languages) {
      // Check if challenge exists for today
      final existing = await _getTodayChallenge(userId, exam, startOfDay);
      
      if (existing != null) {
        challenges.add(existing);
      } else {
        // Generate placeholder for not-started challenges
        challenges.add(DailyChallengeModel(
          id: '',
          userId: userId,
          exam: exam,
          date: startOfDay,
          questions: [],
          totalQuestions: 5,
          isCompleted: false,
        ));
      }
    }

    return challenges;
  }

  // Get questions for challenge
  Future<List<QuestionModel>> _getQuestionsForChallenge({
    required String exam,
    required List<String> excludeIds,
    int limit = 10,
  }) async {
    try {
      Query query = _firestore
          .collection('questions')
          .where('exam', isEqualTo: exam);

      if (excludeIds.isNotEmpty) {
        query = query.limit(limit * 3);
      } else {
        query = query.limit(limit * 2);
      }

      final snapshot = await query.get();
      
      List<QuestionModel> questions = snapshot.docs
          .map((doc) => QuestionModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();

      if (excludeIds.isNotEmpty) {
        final excludeSet = Set<String>.from(excludeIds);
        questions = questions.where((q) => !excludeSet.contains(q.id)).toList();
      }

      return questions;
    } catch (e) {
      // Fallback: get random questions
      final snapshot = await _firestore
          .collection('questions')
          .where('exam', isEqualTo: exam)
          .limit(limit)
          .get();
      
      return snapshot.docs
          .map((doc) => QuestionModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    }
  }

  // Select random questions
  List<QuestionModel> _selectRandomQuestions(
    List<QuestionModel> questions,
    int count,
  ) {
    if (questions.isEmpty) return [];
    if (questions.length <= count) return questions;
    
    final shuffled = List<QuestionModel>.from(questions);
    shuffled.shuffle();
    return shuffled.take(count).toList();
  }

  // Get answered question IDs for a language
  Future<List<String>> _getAnsweredQuestionIds(String userId, String exam) async {
    final snapshot = await _firestore
        .collection('daily_challenges')
        .where('userId', isEqualTo: userId)
        .where('exam', isEqualTo: exam)
        .orderBy('date', descending: true)
        .limit(30)
        .get();

    final Set<String> ids = {};
    for (final doc in snapshot.docs) {
      final challenge = DailyChallengeModel.fromMap(doc.id, doc.data());
      ids.addAll(challenge.answeredQuestionIds);
    }
    return ids.toList();
  }

  // Get language streak
  Future<int> _getLanguageStreak(String userId, String exam) async {
    final snapshot = await _firestore
        .collection('daily_challenges')
        .where('userId', isEqualTo: userId)
        .where('exam', isEqualTo: exam)
        .orderBy('date', descending: true)
        .limit(7)
        .get();

    if (snapshot.docs.isEmpty) return 0;

    int streak = 0;
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);

    for (int i = 0; i < snapshot.docs.length; i++) {
      final doc = snapshot.docs[i];
      final challenge = DailyChallengeModel.fromMap(doc.id, doc.data());
      final challengeDate = DateTime(
        challenge.date.year,
        challenge.date.month,
        challenge.date.day,
      );
      
      final dayDifference = startOfToday.difference(challengeDate).inDays;
      
      if (dayDifference == i) {
        if (challenge.isCompleted) {
          streak++;
        } else {
          break;
        }
      } else {
        break;
      }
    }

    return streak;
  }

  // Get global streak
  Future<int> _getGlobalStreak(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) return 0;
    return userDoc.data()?['streak'] ?? 0;
  }

  // Submit answer
  Future<DailyChallengeModel> submitAnswer({
    required String challengeId,
    required int questionIndex,
    required String answer,
  }) async {
    final docRef = _firestore.collection('daily_challenges').doc(challengeId);
    final doc = await docRef.get();
    
    if (!doc.exists) {
      throw Exception('Challenge not found');
    }

    final challenge = DailyChallengeModel.fromMap(doc.id, doc.data()!);
    final question = challenge.questions[questionIndex];

    if (question.isAnswered) {
      throw Exception('Question already answered');
    }

    final isCorrect = question.correctAnswer == answer;
    final updatedQuestion = DailyChallengeQuestion(
      questionId: question.questionId,
      exam: question.exam,
      level: question.level,
      category: question.category,
      questionText: question.questionText,
      options: question.options,
      correctAnswer: question.correctAnswer,
      selectedAnswer: answer,
      isCorrect: isCorrect,
      isAnswered: true,
    );

    final updatedQuestions = List<DailyChallengeQuestion>.from(challenge.questions);
    updatedQuestions[questionIndex] = updatedQuestion;

    final answeredIds = List<String>.from(challenge.answeredQuestionIds);
    answeredIds.add(question.questionId);

    final updatedChallenge = DailyChallengeModel(
      id: challenge.id,
      userId: challenge.userId,
      exam: challenge.exam,
      date: challenge.date,
      questions: updatedQuestions,
      totalQuestions: challenge.totalQuestions,
      correctAnswers: challenge.correctAnswers + (isCorrect ? 1 : 0),
      xpEarned: challenge.xpEarned + (isCorrect ? 10 : 0),
      isCompleted: updatedQuestions.every((q) => q.isAnswered),
      streak: challenge.streak,
      languageStreak: challenge.languageStreak,
      answeredQuestionIds: answeredIds,
    );

    await docRef.update(updatedChallenge.toMap());

    if (updatedChallenge.isCompleted) {
      await _updateUserXP(
        userId: challenge.userId,
        xpEarned: updatedChallenge.xpEarned,
        exam: challenge.exam,
      );
    }

    return updatedChallenge;
  }

  // Update user XP and streaks
  Future<void> _updateUserXP({
    required String userId,
    required int xpEarned,
    required String exam,
  }) async {
    final userRef = _firestore.collection('users').doc(userId);
    
    final userDoc = await userRef.get();
    if (!userDoc.exists) return;
    
    final userData = userDoc.data()!;
    final currentXP = userData['totalXP'] ?? 0;
    final currentStreak = userData['streak'] ?? 0;
    
    // Update global streak
    final today = DateTime.now();
    final lastPractice = userData['lastPracticeDate'];
    int newStreak = currentStreak;
    
    if (lastPractice != null) {
      final lastDate = (lastPractice as Timestamp).toDate();
      final startOfToday = DateTime(today.year, today.month, today.day);
      final startOfLast = DateTime(lastDate.year, lastDate.month, lastDate.day);
      final difference = startOfToday.difference(startOfLast).inDays;
      
      if (difference == 1) {
        newStreak = currentStreak + 1;
      } else if (difference > 1) {
        newStreak = 1;
      }
    } else {
      newStreak = 1;
    }
    
    final newXP = currentXP + xpEarned;
    final newLevel = _calculateLevel(newXP);
    
    await userRef.update({
      'totalXP': newXP,
      'level': newLevel,
      'streak': newStreak,
      'lastPracticeDate': Timestamp.fromDate(today),
    });
  }

  int _calculateLevel(int xp) {
    if (xp < 100) return 1;
    if (xp < 300) return 2;
    if (xp < 600) return 3;
    if (xp < 1000) return 4;
    if (xp < 1500) return 5;
    return 5 + ((xp - 1500) ~/ 500);
  }
}

extension DailyChallengeModelCopyWith on DailyChallengeModel {
  DailyChallengeModel copyWith({
    String? id,
    String? userId,
    String? exam,
    DateTime? date,
    List<DailyChallengeQuestion>? questions,
    int? totalQuestions,
    int? correctAnswers,
    int? xpEarned,
    bool? isCompleted,
    int? streak,
    int? languageStreak,
    List<String>? answeredQuestionIds,
  }) {
    return DailyChallengeModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      exam: exam ?? this.exam,
      date: date ?? this.date,
      questions: questions ?? this.questions,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      xpEarned: xpEarned ?? this.xpEarned,
      isCompleted: isCompleted ?? this.isCompleted,
      streak: streak ?? this.streak,
      languageStreak: languageStreak ?? this.languageStreak,
      answeredQuestionIds: answeredQuestionIds ?? this.answeredQuestionIds,
    );
  }
}