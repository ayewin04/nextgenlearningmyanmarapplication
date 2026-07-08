// lib/screens/languages/language_exam_screen.dart
import 'package:flutter/material.dart';

class LanguageExamScreen extends StatelessWidget {
  final String language;
  final String exam;

  const LanguageExamScreen({
    super.key,
    required this.language,
    required this.exam,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('📖 $exam Preparation'),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A0E27),
              Color(0xFF0D47A1),
              Color(0xFF1A237E),
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.emoji_events,
                  size: 64,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(height: 16),
                Text(
                  '📖 $exam Prep Coming Soon!',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Practice for $exam exam',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}