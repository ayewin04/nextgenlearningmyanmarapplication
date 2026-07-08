import 'package:flutter/material.dart';
import '../models/vocabulary_model.dart';

class FlashcardWidget extends StatefulWidget {
  final VocabularyModel vocab;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;

  const FlashcardWidget({
    super.key,
    required this.vocab,
    this.onSwipeLeft,
    this.onSwipeRight,
  });

  @override
  State<FlashcardWidget> createState() => _FlashcardWidgetState();
}

class _FlashcardWidgetState extends State<FlashcardWidget> {
  bool _isFlipped = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isFlipped = !_isFlipped;
        });
      },
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue.shade50,
                Colors.purple.shade50,
              ],
            ),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _isFlipped
                ? _buildBackSide(context)
                : _buildFrontSide(context),
          ),
        ),
      ),
    );
  }

  Widget _buildFrontSide(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.vocab.pronunciation != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '🔊 ${widget.vocab.pronunciation}',
              style: const TextStyle(fontSize: 14),
            ),
          ),
        const SizedBox(height: 20),
        Text(
          widget.vocab.word,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          widget.vocab.meaning,
          style: TextStyle(
            fontSize: 18,
            color: Colors.grey.shade700,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Tap to flip',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBackSide(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          '💡 Example',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          widget.vocab.exampleSentence ?? 'No example available',
          style: const TextStyle(
            fontSize: 18,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
        if (widget.vocab.exampleTranslation != null) ...[
          const SizedBox(height: 8),
          Text(
            widget.vocab.exampleTranslation!,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Tap to flip back',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ),
      ],
    );
  }
}