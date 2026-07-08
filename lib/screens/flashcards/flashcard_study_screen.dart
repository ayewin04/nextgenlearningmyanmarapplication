import 'package:flutter/material.dart';

class FlashcardStudyScreen extends StatelessWidget {
  const FlashcardStudyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Flashcards'),
      ),
      body: const Center(
        child: Text('Flashcard Study - Coming Soon'),
      ),
    );
  }
}