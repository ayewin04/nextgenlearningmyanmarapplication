// lib/models/exam_model.dart
class ExamModel {
  final String id;
  final String name;
  final String icon;
  final String flag;
  final String description;
  final List<String> levels;
  final List<String> categories;
  final int totalQuestions;
  final int estimatedDuration;
  final String color;
  final bool isPremium;

  ExamModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.flag,
    required this.description,
    required this.levels,
    required this.categories,
    required this.totalQuestions,
    required this.estimatedDuration,
    required this.color,
    this.isPremium = false,
  });

  factory ExamModel.fromMap(String id, Map<String, dynamic> data) {
    return ExamModel(
      id: id,
      name: data['name'] ?? '',
      icon: data['icon'] ?? '📚',
      flag: data['flag'] ?? '🌍',
      description: data['description'] ?? '',
      levels: List<String>.from(data['levels'] ?? []),
      categories: List<String>.from(data['categories'] ?? []),
      totalQuestions: data['totalQuestions'] ?? 0,
      estimatedDuration: data['estimatedDuration'] ?? 60,
      color: data['color'] ?? '#4CAF50',
      isPremium: data['isPremium'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'icon': icon,
      'flag': flag,
      'description': description,
      'levels': levels,
      'categories': categories,
      'totalQuestions': totalQuestions,
      'estimatedDuration': estimatedDuration,
      'color': color,
      'isPremium': isPremium,
    };
  }
}