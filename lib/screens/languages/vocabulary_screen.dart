// lib/screens/languages/vocabulary_screen.dart
import 'package:flutter/material.dart';

class VocabularyScreen extends StatelessWidget {
  final String language;
  final String exam;

  const VocabularyScreen({
    super.key,
    required this.language,
    required this.exam,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('📚 $exam Vocabulary'),
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
        child: const Center(
          child: Text(
            'Vocabulary coming soon!',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}