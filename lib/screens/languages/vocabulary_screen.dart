// lib/screens/languages/vocabulary_screen.dart
import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../models/vocabulary_model.dart';  // ✅ Uses ExamVocabularyModel

class VocabularyScreen extends StatefulWidget {
  final String language;
  final String exam;
  final String level;

  const VocabularyScreen({
    super.key,
    required this.language,
    required this.exam,
    required this.level,
  });

  @override
  State<VocabularyScreen> createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends State<VocabularyScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<ExamVocabularyModel> _vocabularies = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadVocabulary();
  }

  Future<void> _loadVocabulary() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final vocab = await _firestoreService.getExamVocabularyByLevel(
        exam: widget.exam,
        level: widget.level,
      );
      setState(() {
        _vocabularies = vocab;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load vocabulary: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
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
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '📚 ${widget.exam} Vocabulary',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF42A5F5).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF42A5F5).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        widget.level,
                        style: const TextStyle(
                          color: Color(0xFF42A5F5),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF42A5F5),
                        ),
                      )
                    : _error != null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.error_outline, color: Colors.red, size: 48),
                                  const SizedBox(height: 8),
                                  Text(
                                    _error!,
                                    style: const TextStyle(color: Colors.white),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: _loadVocabulary,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF42A5F5),
                                    ),
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : _vocabularies.isEmpty
                            ? const Center(
                                child: Text(
                                  'No vocabulary available for this level',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _vocabularies.length,
                                itemBuilder: (context, index) {
                                  final vocab = _vocabularies[index];
                                  return _buildVocabularyCard(vocab);
                                },
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVocabularyCard(ExamVocabularyModel vocab) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade800.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade700.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vocab.getDisplayWord(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // Show pronunciation
                    if (vocab.getPronunciationDisplay().isNotEmpty)
                      Text(
                        vocab.getPronunciationDisplay(),
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    // Show Burmese word
                    if (vocab.burmeseWord.isNotEmpty)
                      Text(
                        '🇲🇲 ${vocab.burmeseWord}',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              if (vocab.partOfSpeech != null && vocab.partOfSpeech!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF42A5F5).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    vocab.partOfSpeech!,
                    style: const TextStyle(
                      color: Color(0xFF42A5F5),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            vocab.meaning,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          if (vocab.exampleSentence != null && vocab.exampleSentence!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '💡 ${vocab.exampleSentence}',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
            if (vocab.exampleTranslation != null && vocab.exampleTranslation!.isNotEmpty)
              Text(
                '📖 ${vocab.exampleTranslation}',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                ),
              ),
          ],
        ],
      ),
    );
  }
}