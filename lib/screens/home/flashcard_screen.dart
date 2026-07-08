// lib/screens/home/flashcard_screen.dart
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:html' as html;
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../services/gamification_service.dart';
import '../../models/vocabulary_model.dart';

class FlashcardsScreen extends StatefulWidget {
  final String language;
  final String category;
  final int startIndex;

  const FlashcardsScreen({
    super.key,
    required this.language,
    required this.category,
    this.startIndex = 0,
  });

  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<VocabularyModel> _vocabularies = [];
  List<VocabularyModel> _filteredVocabularies = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  String? _error;
  int _learnedCount = 0;
  String _searchQuery = '';
  
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTop = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.startIndex;
    _loadVocabulary();
    _loadProgress();
    
    _scrollController.addListener(() {
      if (mounted) {
        setState(() {
          _showScrollToTop = _scrollController.offset > 200;
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadVocabulary() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final vocab = await _firestoreService.getVocabularyByCategory(
        category: widget.category,
        language: widget.language,
        limit: 100,
      );
      
      if (mounted) {
        setState(() {
          _vocabularies = vocab;
          _filteredVocabularies = vocab;
          if (_currentIndex >= _vocabularies.length) {
            _currentIndex = 0;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load vocabulary: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadProgress() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.user;
      if (user != null) {
        final progress = await _firestoreService.getUserProgress(
          userId: user.uid,
          exam: widget.language,
        );
        if (mounted && progress != null) {
          setState(() {
            _learnedCount = progress['wordsLearned'] ?? 0;
          });
        }
      }
    } catch (e) {
      print('Error loading progress: $e');
    }
  }

  void _filterVocabulary(String query) {
    if (!mounted) return;
    
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredVocabularies = _vocabularies;
      } else {
        _filteredVocabularies = _vocabularies.where((vocab) {
          final word = vocab.getTranslation(widget.language).toLowerCase();
          final burmese = vocab.burmeseWord.toLowerCase();
          final romanization = vocab.romanization.toLowerCase();
          final search = query.toLowerCase();
          return word.contains(search) ||
              burmese.contains(search) ||
              romanization.contains(search);
        }).toList();
      }
      if (_filteredVocabularies.isNotEmpty) {
        _currentIndex = 0;
      }
    });
  }

  void _nextCard() {
    if (!mounted) return;
    
    if (_currentIndex < _filteredVocabularies.length - 1) {
      setState(() {
        _currentIndex++;
        _learnedCount++;
        _saveProgress();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 You\'ve completed all flashcards!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _previousCard() {
    if (!mounted) return;
    
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
    );
  }

  // ✅ UPDATED: Save progress with immediate XP update
 // In flashcard_screen.dart - Update _saveProgress method

Future<void> _saveProgress() async {
  try {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.user;
    if (user == null) return;

    final vocab = _filteredVocabularies[_currentIndex];
    
    final gamificationService = GamificationService();
    
    // ✅ This will only award XP if word is NOT already learned
    final updatedUser = await gamificationService.updateProgress(
      userId: user.uid,
      language: widget.language,
      category: widget.category,
      wordId: vocab.id,
    );
    
    // ✅ Update the user model with new data
    authService.updateUserModel(updatedUser);
    
    await _firestoreService.saveUserProgress(
      userId: user.uid,
      exam: widget.language,
      questionId: 'word_$_currentIndex',
      isCorrect: true,
      points: 10,
    );
    
    // ✅ Only show XP snackbar if XP was actually awarded
    // The updateProgress method returns the updated user, so we can check if XP changed
    if (updatedUser.totalXP > (authService.userModel?.totalXP ?? 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.star, color: Color(0xFFFFD700), size: 18),
              SizedBox(width: 8),
              Text('+10 XP earned! 🎉'),
            ],
          ),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.green,
        ),
      );
    }
    
  } catch (e) {
    print('Error saving progress: $e');
  }
}

  Future<void> _toggleFavourite() async {
    final vocab = _filteredVocabularies[_currentIndex];
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.user;
    
    if (user == null) return;

    try {
      final newFavouriteStatus = !vocab.isFavourite;
      
      if (mounted) {
        setState(() {
          vocab.isFavourite = newFavouriteStatus;
          _vocabularies[_currentIndex].isFavourite = newFavouriteStatus;
          _filteredVocabularies[_currentIndex].isFavourite = newFavouriteStatus;
        });
      }

      await _firestoreService.toggleFavourite(
        userId: user.uid,
        wordId: vocab.id,
        isFavourite: newFavouriteStatus,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newFavouriteStatus ? '⭐ Added to favourites!' : '⭐ Removed from favourites',
            ),
            duration: const Duration(seconds: 1),
            backgroundColor: newFavouriteStatus ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          vocab.isFavourite = !vocab.isFavourite;
          _vocabularies[_currentIndex].isFavourite = !vocab.isFavourite;
          _filteredVocabularies[_currentIndex].isFavourite = !vocab.isFavourite;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Failed to update favourites'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _playAudio() async {
    final vocab = _filteredVocabularies[_currentIndex];
    final wordInLanguage = vocab.getTranslation(widget.language);

    if (wordInLanguage.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🔊 No audio available for this word'),
            duration: Duration(seconds: 1),
          ),
        );
      }
      return;
    }

    final bool isWeb = identical(0, 0.0) ? false : true;

    if (isWeb) {
      try {
        final synth = html.window.speechSynthesis;
        if (synth == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('🔊 Speech synthesis not supported on this browser.'),
                duration: Duration(seconds: 2),
              ),
            );
          }
          return;
        }

        if (synth.speaking == true) {
          synth.cancel();
        }
        
        final utterance = html.SpeechSynthesisUtterance(wordInLanguage);
        
        final langMap = {
          'english': 'en-US',
          'korean': 'ko-KR',
          'japanese': 'ja-JP',
          'chinese': 'zh-CN',
        };
        utterance.lang = langMap[widget.language] ?? 'en-US';
        utterance.rate = 1.0;
        utterance.pitch = 1.0;
        utterance.volume = 1.0;
        
        synth.speak(utterance);
        
      } catch (e) {
        print('❌ [Web] Audio error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🔊 Audio not available on this browser.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } else {
      try {
        final url =
            'https://api.voicerss.org/'
            '?key=58cd10774f4c4322a6dd8c114650d8a3'
            '&hl=${_getVoiceRssLanguageCode(widget.language)}'
            '&src=${Uri.encodeComponent(wordInLanguage)}'
            '&c=MP3';

        await _audioPlayer.play(UrlSource(url));

      } catch (e) {
        print('❌ [Android] Audio error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🔊 Audio not available. Please try again.'),
              duration: Duration(seconds: 2),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    }
  }

  String _getVoiceRssLanguageCode(String language) {
    const codes = {
      'english': 'en-us',
      'korean': 'ko-kr',
      'japanese': 'ja-jp',
      'chinese': 'zh-cn',
    };
    return codes[language] ?? 'en-us';
  }

  @override
  Widget build(BuildContext context) {
    final vocab = _filteredVocabularies.isNotEmpty 
        ? _filteredVocabularies[_currentIndex] 
        : null;

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
        child: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                            const SizedBox(width: 4),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_getLanguageFlag(widget.language)} ${widget.language.toUpperCase()}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '📚 $_learnedCount words learned',
                                  style: TextStyle(
                                    color: Colors.green.shade300,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.volume_up, color: Colors.white),
                              onPressed: _playAudio,
                            ),
                            if (vocab != null)
                              IconButton(
                                icon: Icon(
                                  vocab.isFavourite ? Icons.favorite : Icons.favorite_border,
                                  color: vocab.isFavourite ? Colors.red : Colors.white,
                                ),
                                onPressed: _toggleFavourite,
                              ),
                            Text(
                              '${_currentIndex + 1}/${_filteredVocabularies.length}',
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Search Bar
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade700),
                    ),
                    child: TextField(
                      onChanged: _filterVocabulary,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: '🔍 Search words...',
                        hintStyle: TextStyle(color: Colors.grey.shade500),
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Flashcard
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
                            : _filteredVocabularies.isEmpty
                                ? Center(
                                    child: Text(
                                      _searchQuery.isEmpty
                                          ? 'No vocabulary available'
                                          : 'No results found',
                                      style: TextStyle(color: Colors.grey.shade400),
                                    ),
                                  )
                                : Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: SingleChildScrollView(
                                      controller: _scrollController,
                                      child: _buildVocabularyCard(),
                                    ),
                                  ),
                  ),

                  // Navigation Buttons
                  if (!_isLoading && _filteredVocabularies.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            onPressed: _currentIndex > 0 ? _previousCard : null,
                            icon: Icon(
                              Icons.arrow_back_ios,
                              color: _currentIndex > 0 ? Colors.white : Colors.grey.shade600,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF42A5F5),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_currentIndex + 1}/${_filteredVocabularies.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _currentIndex < _filteredVocabularies.length - 1
                                ? _nextCard
                                : null,
                            icon: Icon(
                              Icons.arrow_forward_ios,
                              color: _currentIndex < _filteredVocabularies.length - 1
                                  ? Colors.white
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Progress Bar
                  if (!_isLoading && _filteredVocabularies.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: LinearProgressIndicator(
                        value: (_currentIndex + 1) / _filteredVocabularies.length,
                        backgroundColor: Colors.grey.shade800,
                        color: const Color(0xFF42A5F5),
                        minHeight: 4,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            
            // Scroll to Top Button
            if (_showScrollToTop)
              Positioned(
                bottom: 100,
                right: 20,
                child: GestureDetector(
                  onTap: _scrollToTop,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF42A5F5), Color(0xFF1A237E)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF42A5F5).withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_upward,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVocabularyCard() {
    final vocab = _filteredVocabularies[_currentIndex];
    final translation = vocab.getTranslation(widget.language);
    final romanization = vocab.getRomanization(widget.language);
    final example = vocab.getExample(widget.language);
    final exampleRomanization = vocab.getExampleRomanization(widget.language);
    final exampleTranslation = vocab.getExampleTranslation(widget.language);

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      color: const Color(0xFF1A237E),
      child: Container(
        padding: const EdgeInsets.all(24),
        width: double.infinity,
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '📖 Burmese',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                vocab.burmeseWord,
                style: GoogleFonts.notoSansMyanmar(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                vocab.romanization,
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.grey, thickness: 0.5),
              const SizedBox(height: 12),
              Text(
                '🌍 ${widget.language.toUpperCase()} Translation',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                translation,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              if (romanization.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  romanization,
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 16),
              const Divider(color: Colors.grey, thickness: 0.5),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF42A5F5).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF42A5F5).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      '📌 ${vocab.partOfSpeech}',
                      style: const TextStyle(
                        color: Color(0xFF42A5F5),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(vocab.category).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getCategoryColor(vocab.category).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      '📂 ${vocab.category}',
                      style: TextStyle(
                        color: _getCategoryColor(vocab.category),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (vocab.tags.isNotEmpty)
                    ...vocab.tags.map((tag) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '#$tag',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                      ),
                    )),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.grey, thickness: 0.5),
              if (example.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  '💡 Example',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  example,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (exampleRomanization.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    exampleRomanization,
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                if (exampleTranslation.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    exampleTranslation,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 12),
              ],
              const Divider(color: Colors.grey, thickness: 0.5),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    const Text(
                      '📍 Where to use',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getUsageDescription(vocab),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.volume_up, color: Colors.green, size: 16),
                    const SizedBox(width: 4),
                    const Text(
                      '🔊 Tap speaker to hear pronunciation',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getUsageDescription(VocabularyModel vocab) {
    const descriptions = {
      'noun': 'Used to name people, places, things, or ideas',
      'verb': 'Used to describe actions, occurrences, or states of being',
      'adjective': 'Used to describe or modify nouns',
      'adverb': 'Used to modify verbs, adjectives, or other adverbs',
      'pronoun': 'Used to replace a noun in a sentence',
      'preposition': 'Used to show relationships between nouns and other words',
      'conjunction': 'Used to connect words, phrases, or clauses',
      'interjection': 'Used to express emotion or sudden exclamation',
      'phrase': 'Common expression used in everyday conversation',
    };
    return descriptions[vocab.partOfSpeech.toLowerCase()] ?? 'Common word used in daily conversation';
  }

  Color _getCategoryColor(String category) {
    const colors = {
      'daily': Color(0xFFFF6B6B),
      'conversation': Color(0xFF4ECDC4),
      'food': Color(0xFFFFA07A),
      'home': Color(0xFF6C63FF),
      'work': Color(0xFF4CAF50),
    };
    return colors[category] ?? Colors.grey;
  }

  String _getLanguageFlag(String language) {
    const flags = {
      'english': '🇬🇧',
      'korean': '🇰🇷',
      'japanese': '🇯🇵',
      'chinese': '🇨🇳',
    };
    return flags[language] ?? '🌍';
  }
}