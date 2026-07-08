// lib/models/daily_challenge_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class DailyChallengeModel {
  final String id;
  final String userId;
  final String exam; // 👈 NEW: Language-specific challenge
  final DateTime date;
  final List<DailyChallengeQuestion> questions;
  final int totalQuestions;
  final int correctAnswers;
  final int xpEarned;
  final bool isCompleted;
  final int streak;
  final int languageStreak; // 👈 NEW: Streak per language
  final List<String> answeredQuestionIds;

  DailyChallengeModel({
    required this.id,
    required this.userId,
    required this.exam,
    required this.date,
    required this.questions,
    this.totalQuestions = 5,
    this.correctAnswers = 0,
    this.xpEarned = 0,
    this.isCompleted = false,
    this.streak = 0,
    this.languageStreak = 0,
    this.answeredQuestionIds = const [],
  });

  factory DailyChallengeModel.fromMap(String id, Map<String, dynamic> data) {
    return DailyChallengeModel(
      id: id,
      userId: data['userId'] ?? '',
      exam: data['exam'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      questions: (data['questions'] as List? ?? [])
          .map((q) => DailyChallengeQuestion.fromMap(q))
          .toList(),
      totalQuestions: data['totalQuestions'] ?? 5,
      correctAnswers: data['correctAnswers'] ?? 0,
      xpEarned: data['xpEarned'] ?? 0,
      isCompleted: data['isCompleted'] ?? false,
      streak: data['streak'] ?? 0,
      languageStreak: data['languageStreak'] ?? 0,
      answeredQuestionIds: List<String>.from(data['answeredQuestionIds'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'exam': exam,
      'date': Timestamp.fromDate(date),
      'questions': questions.map((q) => q.toMap()).toList(),
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      'xpEarned': xpEarned,
      'isCompleted': isCompleted,
      'streak': streak,
      'languageStreak': languageStreak,
      'answeredQuestionIds': answeredQuestionIds,
    };
  }

  double get completionPercentage {
    if (totalQuestions == 0) return 0;
    return correctAnswers / totalQuestions * 100;
  }

  int get answeredQuestions {
    return questions.where((q) => q.isAnswered).length;
  }

  bool get isFullyAnswered {
    return answeredQuestions == totalQuestions;
  }
}

class DailyChallengeQuestion {
  final String questionId;
  final String exam;
  final String level;
  final String category;
  final String questionText;
  final List<String> options;
  final String correctAnswer;
  final String? selectedAnswer;
  final bool isCorrect;
  final bool isAnswered;

  DailyChallengeQuestion({
    required this.questionId,
    required this.exam,
    required this.level,
    required this.category,
    required this.questionText,
    required this.options,
    required this.correctAnswer,
    this.selectedAnswer,
    this.isCorrect = false,
    this.isAnswered = false,
  });

  factory DailyChallengeQuestion.fromMap(Map<String, dynamic> data) {
    return DailyChallengeQuestion(
      questionId: data['questionId'] ?? '',
      exam: data['exam'] ?? '',
      level: data['level'] ?? '',
      category: data['category'] ?? '',
      questionText: data['questionText'] ?? '',
      options: List<String>.from(data['options'] ?? []),
      correctAnswer: data['correctAnswer'] ?? '',
      selectedAnswer: data['selectedAnswer'],
      isCorrect: data['isCorrect'] ?? false,
      isAnswered: data['isAnswered'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'questionId': questionId,
      'exam': exam,
      'level': level,
      'category': category,
      'questionText': questionText,
      'options': options,
      'correctAnswer': correctAnswer,
      'selectedAnswer': selectedAnswer,
      'isCorrect': isCorrect,
      'isAnswered': isAnswered,
    };
  }
}