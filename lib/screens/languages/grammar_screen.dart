// lib/screens/languages/grammar_screen.dart
import 'package:flutter/material.dart';

class GrammarScreen extends StatelessWidget {
  final String language;
  final String exam;

  const GrammarScreen({
    super.key,
    required this.language,
    required this.exam,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('📝 $exam Grammar'),
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
            'Grammar lessons coming soon!',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}