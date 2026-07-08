class QuestionModel {
  final String id;
  final String exam;
  final String level;
  final String category;
  final String type;
  final String questionText;
  final String? burmeseQuestion;
  final String? burmeseQuestionRomanization;
  final List<String> options;
  final String correctAnswer;
  final int correctAnswerIndex;
  final String? passage;
  final String? explanation;
  final String? burmeseExplanation;
  final int? points;
  final int difficulty;

  QuestionModel({
    required this.id,
    required this.exam,
    required this.level,
    required this.category,
    required this.type,
    required this.questionText,
    this.burmeseQuestion,
    this.burmeseQuestionRomanization,
    required this.options,
    required this.correctAnswer,
    required this.correctAnswerIndex,
    this.passage,
    this.explanation,
    this.burmeseExplanation,
    this.points,
    this.difficulty = 1,
  });

  factory QuestionModel.fromMap(String id, Map<String, dynamic> map) {
    final options = List<String>.from(map['options'] ?? []);
    final correctAnswer = map['correctAnswer'] ?? '';
    int correctIndex = map['correctAnswerIndex'] ?? 0;
    
    // If correctAnswerIndex is not provided, try to find it from options
    if (correctIndex == 0 && correctAnswer.isNotEmpty && options.isNotEmpty) {
      correctIndex = options.indexOf(correctAnswer);
      if (correctIndex == -1) correctIndex = 0;
    }
    
    return QuestionModel(
      id: id,
      exam: map['exam'] ?? '',
      level: map['level'] ?? '',
      category: map['category'] ?? '',
      type: map['type'] ?? 'multiple_choice',
      questionText: map['questionText'] ?? '',
      burmeseQuestion: map['burmeseQuestion'],
      burmeseQuestionRomanization: map['burmeseQuestionRomanization'],
      options: options,
      correctAnswer: correctAnswer,
      correctAnswerIndex: correctIndex,
      passage: map['passage'],
      explanation: map['explanation'],
      burmeseExplanation: map['burmeseExplanation'],
      points: map['points'] ?? 10,
      difficulty: map['difficulty'] ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'exam': exam,
      'level': level,
      'category': category,
      'type': type,
      'questionText': questionText,
      'burmeseQuestion': burmeseQuestion,
      'burmeseQuestionRomanization': burmeseQuestionRomanization,
      'options': options,
      'correctAnswer': correctAnswer,
      'correctAnswerIndex': correctAnswerIndex,
      'passage': passage,
      'explanation': explanation,
      'burmeseExplanation': burmeseExplanation,
      'points': points,
      'difficulty': difficulty,
    };
  }
}