import 'package:cloud_firestore/cloud_firestore.dart';

class DailyConversationModel {
  final String id;
  final String language;
  final String exam;
  final String category;
  final String subCategory;
  final String title;
  final String titleRomanization;
  final String burmeseTitle;
  final String description;
  final String burmeseDescription;
  final List<ConversationEntry> conversation;
  final int difficulty;
  final DateTime? createdAt;

  DailyConversationModel({
    required this.id,
    required this.language,
    required this.exam,
    required this.category,
    required this.subCategory,
    required this.title,
    required this.titleRomanization,
    required this.burmeseTitle,
    required this.description,
    required this.burmeseDescription,
    required this.conversation,
    this.difficulty = 1,
    this.createdAt,
  });

  factory DailyConversationModel.fromMap(String id, Map<String, dynamic> data) {
    final conversationList = data['conversation'] as List? ?? [];
    final conversation = conversationList.map((entry) {
      return ConversationEntry.fromMap(entry as Map<String, dynamic>);
    }).toList();

    return DailyConversationModel(
      id: id,
      language: data['language'] ?? '',
      exam: data['exam'] ?? '',
      category: data['category'] ?? '',
      subCategory: data['subCategory'] ?? '',
      title: data['title'] ?? '',
      titleRomanization: data['titleRomanization'] ?? '',
      burmeseTitle: data['burmeseTitle'] ?? '',
      description: data['description'] ?? '',
      burmeseDescription: data['burmeseDescription'] ?? '',
      conversation: conversation,
      difficulty: data['difficulty'] ?? 1,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'language': language,
      'exam': exam,
      'category': category,
      'subCategory': subCategory,
      'title': title,
      'titleRomanization': titleRomanization,
      'burmeseTitle': burmeseTitle,
      'description': description,
      'burmeseDescription': burmeseDescription,
      'conversation': conversation.map((e) => e.toMap()).toList(),
      'difficulty': difficulty,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
    };
  }
}

class ConversationEntry {
  final String speaker;
  final String text;
  final String romanization;
  final String burmese;
  final String? audioUrl;

  ConversationEntry({
    required this.speaker,
    required this.text,
    required this.romanization,
    required this.burmese,
    this.audioUrl,
  });

  factory ConversationEntry.fromMap(Map<String, dynamic> data) {
    return ConversationEntry(
      speaker: data['speaker'] ?? '',
      text: data['text'] ?? '',
      romanization: data['romanization'] ?? '',
      burmese: data['burmese'] ?? '',
      audioUrl: data['audioUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'speaker': speaker,
      'text': text,
      'romanization': romanization,
      'burmese': burmese,
      'audioUrl': audioUrl,
    };
  }
}

// Model for Categories
class ConversationCategory {
  final String id;
  final String name;
  final String icon;
  final String category;
  final String exam;
  final String language;
  final String? description;

  ConversationCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.category,
    required this.exam,
    required this.language,
    this.description,
  });

  factory ConversationCategory.fromMap(String id, Map<String, dynamic> data) {
    return ConversationCategory(
      id: id,
      name: data['name'] ?? '',
      icon: data['icon'] ?? '📚',
      category: data['category'] ?? '',
      exam: data['exam'] ?? '',
      language: data['language'] ?? '',
      description: data['description'],
    );
  }
}

class ConversationSubCategory {
  final String id;
  final String name;
  final String icon;
  final String categoryId;
  final String exam;
  final String language;
  final String? description;

  ConversationSubCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.categoryId,
    required this.exam,
    required this.language,
    this.description,
  });

  factory ConversationSubCategory.fromMap(String id, Map<String, dynamic> data) {
    return ConversationSubCategory(
      id: id,
      name: data['name'] ?? '',
      icon: data['icon'] ?? '📚',
      categoryId: data['categoryId'] ?? '',
      exam: data['exam'] ?? '',
      language: data['language'] ?? '',
      description: data['description'],
    );
  }
}