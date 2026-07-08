import 'package:flutter/material.dart';

class FlashcardHomeScreen extends StatelessWidget {
  const FlashcardHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flashcards'),
      ),
      body: const Center(
        child: Text('Flashcards - Coming Soon'),
      ),
    );
  }
}