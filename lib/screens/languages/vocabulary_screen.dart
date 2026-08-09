import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';
import '../../services/audio_service.dart';
import '../../models/vocabulary_model.dart';

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
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  String? _error;
  String _searchQuery = '';
  
  // Pagination variables
  DocumentSnapshot? _lastDocument;
  static const int _pageSize = 50;

  @override
  void initState() {
    super.initState();
    _loadVocabulary();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadVocabulary({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _isLoading = true;
        _error = null;
        _vocabularies = [];
        _lastDocument = null;
        _hasMoreData = true;
        _isLoadingMore = false;
      });
    }

    try {
      print('🔍 Loading exam vocabulary for: ${widget.exam}, level: ${widget.level}');
      
      final result = await _firestoreService.getExamVocabularyByLevelPaginated(
        exam: widget.exam.toLowerCase(),
        level: widget.level,
        limit: _pageSize,
        startAfter: refresh ? null : _lastDocument,
      );
      
      final newVocabularies = result['data'] as List<Map<String, dynamic>>;
      _lastDocument = result['lastDocument'] as DocumentSnapshot?;
      _hasMoreData = result['hasMore'] as bool;
      
      final vocabList = newVocabularies.map((data) {
        return ExamVocabularyModel.fromMap(
          data['id'] ?? data['word'] ?? '',
          data,
        );
      }).toList();
      
      // Combine and remove duplicates by word, exam, and level
      if (refresh) {
        _vocabularies = _removeDuplicatesByWordExamLevel(vocabList);
      } else {
        final combined = [..._vocabularies, ...vocabList];
        _vocabularies = _removeDuplicatesByWordExamLevel(combined);
      }
      
      print('✅ Loaded ${_vocabularies.length} unique vocabulary words');
      
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      print('❌ Error loading vocabulary: $e');
      setState(() {
        _error = 'Failed to load vocabulary: $e';
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  /// Remove duplicates based on word, exam, and level combination
  List<ExamVocabularyModel> _removeDuplicatesByWordExamLevel(
    List<ExamVocabularyModel> vocabularies,
  ) {
    final seen = <String>{};
    final unique = <ExamVocabularyModel>[];
    
    for (final vocab in vocabularies) {
      // Create a unique key using word, exam, and level
      final key = _getUniqueKey(vocab);
      
      if (!seen.contains(key)) {
        seen.add(key);
        unique.add(vocab);
      }
    }
    
    return unique;
  }

  /// Generate a unique key from word, exam, and level
  String _getUniqueKey(ExamVocabularyModel vocab) {
    return '${vocab.word.toLowerCase()}_${vocab.exam.toLowerCase()}_${vocab.level}';
  }

  /// Optional: Check for duplicates and log them
  void _checkForDuplicates() {
    final wordCount = <String, int>{};
    for (final vocab in _vocabularies) {
      final key = _getUniqueKey(vocab);
      wordCount[key] = (wordCount[key] ?? 0) + 1;
    }
    
    final duplicates = wordCount.entries.where((entry) => entry.value > 1).toList();
    
    if (duplicates.isNotEmpty) {
      print('⚠️ Found ${duplicates.length} duplicate entries:');
      for (final duplicate in duplicates) {
        print('  - "${duplicate.key}" appears ${duplicate.value} times');
      }
    }
  }

  /// Alternative: Remove duplicates and keep the best version
  List<ExamVocabularyModel> _removeDuplicatesKeepBest(
    List<ExamVocabularyModel> vocabularies,
  ) {
    final bestMap = <String, ExamVocabularyModel>{};
    
    for (final vocab in vocabularies) {
      final key = _getUniqueKey(vocab);
      
      if (!bestMap.containsKey(key)) {
        bestMap[key] = vocab;
      } else {
        // Keep the version with more complete information
        final existing = bestMap[key]!;
        
        // Score each version based on completeness
        final existingScore = _calculateCompletenessScore(existing);
        final newScore = _calculateCompletenessScore(vocab);
        
        if (newScore > existingScore) {
          bestMap[key] = vocab;
        }
      }
    }
    
    return bestMap.values.toList();
  }

  /// Calculate completeness score for a vocabulary item (with null safety)
  int _calculateCompletenessScore(ExamVocabularyModel vocab) {
    int score = 0;
    
    // Use null-aware operators and default values
    if ((vocab.exampleSentence ?? '').isNotEmpty) score += 10;
    if ((vocab.exampleTranslation ?? '').isNotEmpty) score += 10;
    if ((vocab.exampleRomanization ?? '').isNotEmpty) score += 5;
    if ((vocab.pronunciation ?? '').isNotEmpty) score += 10;
    if ((vocab.romanization ?? '').isNotEmpty) score += 5;
    if (vocab.tags.isNotEmpty) score += 5;
    if ((vocab.partOfSpeech ?? '').isNotEmpty) score += 5;
    if ((vocab.burmeseWord ?? '').isNotEmpty) score += 10;
    if ((vocab.meaning ?? '').isNotEmpty) score += 5;
    
    return score;
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMoreData || _searchQuery.isNotEmpty) return;
    
    setState(() {
      _isLoadingMore = true;
    });
    
    await _loadVocabulary(refresh: false);
  }

  void _playAudio(String word) async {
    if (word.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔊 No audio available for this word'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    try {
      await AudioService.speak(word, language: widget.language);
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

  void _filterVocabulary(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  List<ExamVocabularyModel> _getFilteredVocabularies() {
    if (_searchQuery.isEmpty) return _vocabularies;
    return _vocabularies.where((vocab) {
      final word = vocab.word.toLowerCase();
      final meaning = (vocab.meaning ?? '').toLowerCase();
      final burmese = (vocab.burmeseWord ?? '').toLowerCase();
      final search = _searchQuery.toLowerCase();
      return word.contains(search) ||
          meaning.contains(search) ||
          burmese.contains(search);
    }).toList();
  }

  String _getExamDisplayName() {
    switch (widget.exam.toLowerCase()) {
      case 'ielts': return 'IELTS';
      case 'hsk': return 'HSK';
      case 'jlpt': return 'JLPT';
      case 'topik': return 'TOPIK';
      default: return widget.exam.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _getFilteredVocabularies();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          '📚 ${_getExamDisplayName()} Vocabulary',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => _loadVocabulary(refresh: true),
            tooltip: 'Refresh vocabulary',
          ),
          // Show total count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_vocabularies.length}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFFFD700).withOpacity(0.3),
              ),
            ),
            child: Text(
              widget.level,
              style: const TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              onChanged: _filterVocabulary,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: '🔍 Search words...',
                hintStyle: TextStyle(color: Colors.grey.shade500),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey.shade800.withOpacity(0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ),
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
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF42A5F5),
                ),
              )
            : _error != null
                ? _buildErrorWidget()
                : _vocabularies.isEmpty
                    ? _buildEmptyWidget()
                    : filteredList.isEmpty
                        ? Center(
                            child: Text(
                              'No results found for "$_searchQuery"',
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 16,
                              ),
                            ),
                          )
                        : NotificationListener<ScrollNotification>(
                            onNotification: (scrollInfo) {
                              if (!_isLoadingMore &&
                                  _hasMoreData &&
                                  _searchQuery.isEmpty &&
                                  scrollInfo.metrics.pixels >=
                                      scrollInfo.metrics.maxScrollExtent - 100) {
                                _loadMore();
                              }
                              return true;
                            },
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: filteredList.length + (_hasMoreData && _searchQuery.isEmpty ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == filteredList.length && _hasMoreData && _searchQuery.isEmpty) {
                                  return _buildLoadingMoreIndicator();
                                }
                                final vocab = filteredList[index];
                                return _buildVocabularyCard(vocab);
                              },
                            ),
                          ),
      ),
    );
  }

  Widget _buildLoadingMoreIndicator() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Column(
          children: [
            CircularProgressIndicator(
              color: Color(0xFF42A5F5),
            ),
            SizedBox(height: 8),
            Text(
              'Loading more words...',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
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
              onPressed: () => _loadVocabulary(refresh: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF42A5F5),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.school_outlined,
            size: 64,
            color: Colors.grey.shade600,
          ),
          const SizedBox(height: 16),
          Text(
            'No vocabulary available for ${widget.exam.toUpperCase()} - ${widget.level}',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Add vocabulary to the exam_vocabulary collection',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _loadVocabulary(refresh: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF42A5F5),
            ),
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildVocabularyCard(ExamVocabularyModel vocab) {
    final word = vocab.word;
    final meaning = vocab.meaning ?? '';
    final partOfSpeech = vocab.partOfSpeech ?? 'noun';
    final exampleSentence = vocab.exampleSentence ?? '';
    final exampleRomanization = vocab.exampleRomanization ?? '';
    final pronunciation = vocab.getPronunciationDisplay();
    final burmeseWord = vocab.burmeseWord ?? '';
    final romanization = vocab.romanization ?? '';
    final exampleTranslation = vocab.exampleTranslation ?? '';
    final tags = vocab.tags;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
          // Word with Audio Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          word,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (pronunciation.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            pronunciation,
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                    // Burmese translation
                    if (burmeseWord.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '🇲🇲 ',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            burmeseWord,
                            style: GoogleFonts.notoSansMyanmar(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      if (romanization.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 28),
                          child: Text(
                            romanization,
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF42A5F5).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.level,
                      style: const TextStyle(
                        color: Color(0xFF42A5F5),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  IconButton(
                    onPressed: () => _playAudio(word),
                    icon: const Icon(
                      Icons.volume_up,
                      color: Color(0xFF42A5F5),
                      size: 20,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 30,
                      minHeight: 30,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Meaning
          Text(
            meaning,
            style: TextStyle(
              color: Colors.grey.shade300,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          
          // Part of Speech and Tags
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  partOfSpeech,
                  style: TextStyle(
                    color: Colors.green.shade300,
                    fontSize: 11,
                  ),
                ),
              ),
              ...tags.map((tag) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    color: Colors.blue.shade300,
                    fontSize: 11,
                  ),
                ),
              )),
            ],
          ),
          
          // Example with romanization
          if (exampleSentence.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade900.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.grey.shade700.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Example in target language
                  Row(
                    children: [
                      const Text(
                        '💡 ',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          exampleSentence,
                          style: TextStyle(
                            color: Colors.grey.shade300,
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Example Romanization
                  if (exampleRomanization.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 24),
                      child: Text(
                        exampleRomanization,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                  // Burmese translation of example
                  if (exampleTranslation.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 24),
                      child: Row(
                        children: [
                          Text(
                            '🇲🇲 ',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              exampleTranslation,
                              style: GoogleFonts.notoSansMyanmar(
                                color: Colors.white60,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          
          // Audio hint
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.volume_up,
                color: Colors.grey.shade600,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                'Tap speaker to hear pronunciation',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}