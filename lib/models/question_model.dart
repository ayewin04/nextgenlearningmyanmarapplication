// lib/models/question_model.dart
class QuestionModel {
  final String id;
  final String exam;
  final String level;
  final String category;
  final String type;
  final String questionText;
  final List<String>? options;
  final String? correctAnswer;
  final String? audioUrl;
  final String? passageText;
  final String? aiExplanation;
  final int? timeLimit;
  final int? points;

  QuestionModel({
    required this.id,
    required this.exam,
    required this.level,
    required this.category,
    required this.type,
    required this.questionText,
    this.options,
    this.correctAnswer,
    this.audioUrl,
    this.passageText,
    this.aiExplanation,
    this.timeLimit,
    this.points,
  });

  factory QuestionModel.fromMap(String id, Map<String, dynamic> data) {
    return QuestionModel(
      id: id,
      exam: data['exam'] ?? '',
      level: data['level'] ?? '',
      category: data['category'] ?? '',
      type: data['type'] ?? '',
      questionText: data['questionText'] ?? '',
      options: data['options'] != null ? List<String>.from(data['options']) : null,
      correctAnswer: data['correctAnswer'],
      audioUrl: data['audioUrl'],
      passageText: data['passageText'],
      aiExplanation: data['aiExplanation'],
      timeLimit: data['timeLimit'],
      points: data['points'] ?? 10,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'exam': exam,
      'level': level,
      'category': category,
      'type': type,
      'questionText': questionText,
      'options': options,
      'correctAnswer': correctAnswer,
      'audioUrl': audioUrl,
      'passageText': passageText,
      'aiExplanation': aiExplanation,
      'timeLimit': timeLimit,
      'points': points,
    };
  }

  bool isMultipleChoice() => type == 'multiple_choice';
  bool isFillBlank() => type == 'fill_blank';
  bool isEssay() => type == 'essay';
  bool isListening() => category == 'Listening';
  bool isReading() => category == 'Reading';
  bool isWriting() => category == 'Writing';
  bool isSpeaking() => category == 'Speaking';
}