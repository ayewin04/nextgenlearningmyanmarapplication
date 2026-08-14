import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../services/gamification_service.dart';
import '../../services/audio_service.dart';
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

  Future<void> _saveCurrentIndex() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.user;
    
    if (user == null) return;

    try {
      await _firestoreService.saveLastWordIndex(
        userId: user.uid,
        language: widget.language,
        category: widget.category,
        index: _currentIndex,
      );
    } catch (e) {
      print('Error saving current index: $e');
    }
  }

  void _nextCard() {
    if (!mounted) return;
    
    if (_currentIndex < _filteredVocabularies.length - 1) {
      setState(() {
        _currentIndex++;
        _learnedCount++;
        _saveProgress();
        _saveCurrentIndex();
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
        _saveCurrentIndex();
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

  Future<void> _saveProgress() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.user;
      if (user == null) return;

      final vocab = _filteredVocabularies[_currentIndex];
      
      final gamificationService = GamificationService();
      
      final updatedUser = await gamificationService.updateProgress(
        userId: user.uid,
        language: widget.language,
        category: widget.category,
        wordId: vocab.id,
      );
      
      authService.updateUserModel(updatedUser);
      
      await _firestoreService.saveUserProgress(
        userId: user.uid,
        exam: widget.language,
        questionId: 'word_$_currentIndex',
        isCorrect: true,
        points: 10,
      );
      
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
        language: widget.language,
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

    try {
      await AudioService.speak(
        wordInLanguage,
        language: widget.language,
      );
      print('✅ Audio played successfully');
    } catch (e) {
      print('❌ Audio error: $e');
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

  String _getLanguageFlag(String language) {
    const flags = {
      'english': '🇬🇧',
      'korean': '🇰🇷',
      'japanese': '🇯🇵',
      'chinese': '🇨🇳',
    };
    return flags[language] ?? '🌍';
  }

  @override
  Widget build(BuildContext context) {
    final vocab = _filteredVocabularies.isNotEmpty 
        ? _filteredVocabularies[_currentIndex] 
        : null;

    // Get screen size for responsive design
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;
    final isTablet = screenSize.width > 600;

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
              // Header - ULTRA RESPONSIVE VERSION
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 8 : 12,
                  vertical: isSmallScreen ? 6 : 8,
                ),
                child: Row(
                  children: [
                    // Back button
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(
                        Icons.arrow_back, 
                        color: Colors.white,
                        size: isSmallScreen ? 20 : 24,
                      ),
                      onPressed: () {
                        _saveCurrentIndex();
                        Navigator.pop(context);
                      },
                    ),
                    SizedBox(width: isSmallScreen ? 2 : 4),
                    // Left content - takes available space
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${_getLanguageFlag(widget.language)} ${widget.language.toUpperCase()}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isSmallScreen ? 12 : (isTablet ? 16 : 14),
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          Text(
                            '📚 $_learnedCount words learned',
                            style: TextStyle(
                              color: Colors.green.shade300,
                              fontSize: isSmallScreen ? 9 : (isTablet ? 13 : 11),
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                    // Right content - wrapped in Flexible
                    Flexible(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Audio button - hide on very small screens if needed
                          if (!isSmallScreen || screenSize.width > 320)
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: Icon(
                                Icons.volume_up, 
                                color: Colors.white, 
                                size: isSmallScreen ? 18 : (isTablet ? 24 : 20),
                              ),
                              onPressed: _playAudio,
                            ),
                          // Favourite button
                          if (vocab != null && (!isSmallScreen || screenSize.width > 340))
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: Icon(
                                vocab.isFavourite ? Icons.favorite : Icons.favorite_border,
                                color: vocab.isFavourite ? Colors.red : Colors.white,
                                size: isSmallScreen ? 18 : (isTablet ? 24 : 20),
                              ),
                              onPressed: _toggleFavourite,
                            ),
                          // Counter
                          Container(
                            margin: EdgeInsets.only(
                              left: isSmallScreen ? 2 : 4,
                            ),
                            child: Text(
                              '${_currentIndex + 1}/${_filteredVocabularies.length}',
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: isSmallScreen ? 10 : (isTablet ? 14 : 12),
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Search Bar - Responsive
              Container(
                margin: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 12 : 20,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade800.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade700),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: TextField(
                    onChanged: _filterVocabulary,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isSmallScreen ? 12 : 14,
                    ),
                    decoration: InputDecoration(
                      hintText: isSmallScreen ? '🔍 Search...' : '🔍 Search words...',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: isSmallScreen ? 12 : 14,
                      ),
                      prefixIcon: Icon(
                        Icons.search, 
                        color: Colors.grey,
                        size: isSmallScreen ? 18 : 24,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 12 : 16,
                        vertical: isSmallScreen ? 8 : 12,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: isSmallScreen ? 8 : 12),

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
                                  style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: isSmallScreen ? 14 : 16,
                                  ),
                                ),
                              )
                            : Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isSmallScreen ? 8 : 16,
                                ),
                                child: SingleChildScrollView(
                                  controller: _scrollController,
                                  child: _buildVocabularyCard(
                                    isSmallScreen: isSmallScreen,
                                    isTablet: isTablet,
                                  ),
                                ),
                              ),
              ),

              // Navigation Buttons - Responsive
              if (!_isLoading && _filteredVocabularies.isNotEmpty)
                Padding(
                  padding: EdgeInsets.all(isSmallScreen ? 8 : 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        onPressed: _currentIndex > 0 ? _previousCard : null,
                        icon: Icon(
                          Icons.arrow_back_ios,
                          color: _currentIndex > 0 ? Colors.white : Colors.grey.shade600,
                          size: isSmallScreen ? 18 : 24,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 12 : 20,
                          vertical: isSmallScreen ? 4 : 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF42A5F5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_currentIndex + 1}/${_filteredVocabularies.length}',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: isSmallScreen ? 11 : 13,
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
                          size: isSmallScreen ? 18 : 24,
                        ),
                      ),
                    ],
                  ),
                ),

              // Progress Bar - Responsive
              if (!_isLoading && _filteredVocabularies.isNotEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 16 : 24,
                  ),
                  child: LinearProgressIndicator(
                    value: (_currentIndex + 1) / _filteredVocabularies.length,
                    backgroundColor: Colors.grey.shade800,
                    color: const Color(0xFF42A5F5),
                    minHeight: isSmallScreen ? 3 : 4,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              SizedBox(height: isSmallScreen ? 8 : 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVocabularyCard({
    required bool isSmallScreen,
    required bool isTablet,
  }) {
    final vocab = _filteredVocabularies[_currentIndex];
    final translation = vocab.getTranslation(widget.language);
    final romanization = vocab.getRomanization(widget.language);
    final example = vocab.getExample(widget.language);
    final exampleRomanization = vocab.getExampleRomanization(widget.language);
    final exampleTranslation = vocab.getExampleTranslation(widget.language);

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isTablet ? 32 : 24),
      ),
      color: const Color(0xFF1A237E),
      child: Container(
        padding: EdgeInsets.all(isSmallScreen ? 16 : (isTablet ? 32 : 24)),
        width: double.infinity,
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '📖 Burmese',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: isSmallScreen ? 10 : (isTablet ? 14 : 12),
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: isSmallScreen ? 2 : 4),
              Text(
                vocab.burmeseWord,
                style: GoogleFonts.notoSansMyanmar(
                  color: Colors.white,
                  fontSize: isSmallScreen ? 28 : (isTablet ? 50 : 40),
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isSmallScreen ? 2 : 4),
              Text(
                vocab.romanization,
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: isSmallScreen ? 12 : (isTablet ? 18 : 16),
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isSmallScreen ? 12 : 16),
              const Divider(color: Colors.grey, thickness: 0.5),
              SizedBox(height: isSmallScreen ? 8 : 12),
              Text(
                '🌍 ${widget.language.toUpperCase()} Translation',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: isSmallScreen ? 10 : (isTablet ? 14 : 12),
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: isSmallScreen ? 2 : 4),
              Text(
                translation,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isSmallScreen ? 20 : (isTablet ? 34 : 28),
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              if (romanization.isNotEmpty) ...[
                SizedBox(height: isSmallScreen ? 2 : 4),
                Text(
                  romanization,
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: isSmallScreen ? 12 : (isTablet ? 16 : 14),
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              SizedBox(height: isSmallScreen ? 12 : 16),
              const Divider(color: Colors.grey, thickness: 0.5),
              SizedBox(height: isSmallScreen ? 8 : 12),
              // Tags - Responsive Wrap
              Wrap(
                spacing: isSmallScreen ? 4 : 8,
                runSpacing: isSmallScreen ? 4 : 8,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 8 : 12,
                      vertical: isSmallScreen ? 2 : 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF42A5F5).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF42A5F5).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      '📌 ${vocab.partOfSpeech}',
                      style: TextStyle(
                        color: const Color(0xFF42A5F5),
                        fontSize: isSmallScreen ? 10 : (isTablet ? 14 : 12),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 8 : 12,
                      vertical: isSmallScreen ? 2 : 4,
                    ),
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
                        fontSize: isSmallScreen ? 10 : (isTablet ? 14 : 12),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (vocab.tags.isNotEmpty)
                    ...vocab.tags.map((tag) => Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 6 : 12,
                        vertical: isSmallScreen ? 2 : 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '#$tag',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: isSmallScreen ? 9 : (isTablet ? 13 : 11),
                        ),
                      ),
                    )),
                ],
              ),
              SizedBox(height: isSmallScreen ? 12 : 16),
              const Divider(color: Colors.grey, thickness: 0.5),
              if (example.isNotEmpty) ...[
                SizedBox(height: isSmallScreen ? 8 : 12),
                Text(
                  '💡 Example',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: isSmallScreen ? 10 : (isTablet ? 14 : 12),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 2 : 4),
                Text(
                  example,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isSmallScreen ? 14 : (isTablet ? 22 : 18),
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (exampleRomanization.isNotEmpty) ...[
                  SizedBox(height: isSmallScreen ? 2 : 4),
                  Text(
                    exampleRomanization,
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: isSmallScreen ? 12 : (isTablet ? 16 : 14),
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                if (exampleTranslation.isNotEmpty) ...[
                  SizedBox(height: isSmallScreen ? 2 : 4),
                  Text(
                    exampleTranslation,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: isSmallScreen ? 12 : (isTablet ? 16 : 14),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                SizedBox(height: isSmallScreen ? 8 : 12),
              ],
              const Divider(color: Colors.grey, thickness: 0.5),
              SizedBox(height: isSmallScreen ? 8 : 12),
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    Text(
                      '📍 Where to use',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: isSmallScreen ? 10 : (isTablet ? 14 : 12),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 2 : 4),
                    Text(
                      _getUsageDescription(vocab),
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: isSmallScreen ? 12 : (isTablet ? 16 : 14),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              SizedBox(height: isSmallScreen ? 8 : 12),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 8 : 12,
                  vertical: isSmallScreen ? 2 : 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.volume_up, 
                      color: Colors.green, 
                      size: isSmallScreen ? 12 : 16,
                    ),
                    SizedBox(width: isSmallScreen ? 2 : 4),
                    Text(
                      isSmallScreen ? '🔊 Tap to hear' : '🔊 Tap speaker to hear pronunciation',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: isSmallScreen ? 9 : (isTablet ? 13 : 11),
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
}