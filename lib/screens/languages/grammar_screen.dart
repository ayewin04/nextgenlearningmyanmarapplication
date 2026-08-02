import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';
import '../../services/audio_service.dart';

class GrammarScreen extends StatefulWidget {
  final String language;
  final String exam;
  final String level;

  const GrammarScreen({
    super.key,
    required this.language,
    required this.exam,
    required this.level,
  });

  @override
  State<GrammarScreen> createState() => _GrammarScreenState();
}

class _GrammarScreenState extends State<GrammarScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Map<String, dynamic>> _grammar = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _error;
  String _searchQuery = '';
  
  // Pagination
  final int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _loadGrammar();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadGrammar({bool loadMore = false}) async {
    if (loadMore && (_isLoadingMore || !_hasMore)) return;

    setState(() {
      if (loadMore) {
        _isLoadingMore = true;
      } else {
        _isLoading = true;
        _error = null;
        _grammar = [];
        _hasMore = true;
        _firestoreService.resetGrammarPagination(); // Reset pagination on new load
      }
    });

    try {
      // Get the last document reference for pagination
      DocumentSnapshot? startAfter;
      if (loadMore) {
        startAfter = _firestoreService.getLastGrammarDoc();
        print('🔍 Loading more after: ${startAfter?.id}');
      }
      
      final grammar = await _firestoreService.getGrammarByLevelWithPagination(
        exam: widget.exam.toLowerCase(),
        level: widget.level,
        limit: _pageSize,
        startAfter: startAfter,
      );
      
      print('✅ Loaded ${grammar.length} grammar lessons for ${widget.exam} - ${widget.level}');
      
      setState(() {
        if (loadMore) {
          _grammar.addAll(grammar);
        } else {
          _grammar = grammar;
        }
        
        // If we got fewer than pageSize, no more data
        _hasMore = grammar.length == _pageSize;
        _isLoading = false;
        _isLoadingMore = false;
      });
      
      // Debug: Show what we loaded
      if (grammar.isNotEmpty) {
        print('📄 First: ${grammar.first['title']}');
        print('📄 Last: ${grammar.last['title']}');
        print('📄 Total so far: ${_grammar.length}');
      }
    } catch (e) {
      print('❌ Error loading grammar: $e');
      setState(() {
        _error = 'Failed to load grammar: $e';
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  void _filterGrammar(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  List<Map<String, dynamic>> get _filteredGrammar {
    if (_searchQuery.isEmpty) return _grammar;
    return _grammar.where((lesson) {
      final title = (lesson['title'] ?? '').toLowerCase();
      final description = (lesson['description'] ?? '').toLowerCase();
      final rule = (lesson['rule'] ?? '').toLowerCase();
      final search = _searchQuery.toLowerCase();
      return title.contains(search) ||
          description.contains(search) ||
          rule.contains(search);
    }).toList();
  }

  void _playAudio(String text) async {
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔊 No audio available for this text'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    try {
      await AudioService.speak(text, language: widget.language);
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

  @override
  Widget build(BuildContext context) {
    final filteredList = _filteredGrammar;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          '📝 ${widget.exam.toUpperCase()} Grammar',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
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
              onChanged: _filterGrammar,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: '🔍 Search grammar...',
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
                : _grammar.isEmpty
                    ? _buildEmptyWidget()
                    : Column(
                        children: [
                          // Show count
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '📚 ${_grammar.length} lessons',
                                  style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 12,
                                  ),
                                ),
                                if (_isLoadingMore)
                                  const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF42A5F5),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: filteredList.length + (_hasMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == filteredList.length) {
                                  return _buildLoadMoreButton();
                                }
                                final lesson = filteredList[index];
                                return _buildGrammarCard(lesson);
                              },
                            ),
                          ),
                        ],
                      ),
      ),
    );
  }

  Widget _buildLoadMoreButton() {
    if (_isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF42A5F5),
          ),
        ),
      );
    }

    if (!_hasMore && _grammar.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(
            '✅ All ${_grammar.length} lessons loaded',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: ElevatedButton(
          onPressed: () => _loadGrammar(loadMore: true),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A237E),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: const Color(0xFF42A5F5).withOpacity(0.3),
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.expand_more, size: 18),
              const SizedBox(width: 8),
              Text(
                'Load More (${_grammar.length}+)',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
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
              onPressed: () => _loadGrammar(loadMore: false),
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
          const Icon(
            Icons.school,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'No grammar lessons available',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            'Add grammar to the grammar collection',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrammarCard(Map<String, dynamic> lesson) {
    final title = lesson['title'] ?? '';
    final titleRomanization = lesson['titleRomanization'] ?? '';
    final description = lesson['description'] ?? '';
    final rule = lesson['rule'] ?? '';
    final ruleRomanization = lesson['ruleRomanization'] ?? '';
    final examples = lesson['examples'] as List? ?? [];
    final burmeseTitle = lesson['burmeseTitle'] ?? '';
    final burmeseDescription = lesson['burmeseDescription'] ?? '';
    final burmeseRule = lesson['burmeseRule'] ?? '';
    final burmeseExamples = lesson['burmeseExamples'] as List? ?? [];
    final exampleRomanizations = lesson['exampleRomanizations'] as List? ?? [];

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
          // Title with Audio Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (titleRomanization.isNotEmpty)
                      Text(
                        titleRomanization,
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    if (burmeseTitle.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '🇲🇲 $burmeseTitle',
                          style: GoogleFonts.notoSansMyanmar(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _playAudio(title),
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
          const SizedBox(height: 4),
          
          // Description
          Text(
            description,
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 13,
            ),
          ),
          if (burmeseDescription.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '🇲🇲 $burmeseDescription',
                style: GoogleFonts.notoSansMyanmar(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                ),
              ),
            ),
          const SizedBox(height: 8),
          
          // Rule
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade900.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rule,
                  style: const TextStyle(
                    color: Color(0xFF42A5F5),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (ruleRomanization.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      ruleRomanization,
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                if (burmeseRule.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '🇲🇲 $burmeseRule',
                      style: GoogleFonts.notoSansMyanmar(
                        color: Colors.grey.shade400,
                        fontSize: 13,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Examples
          if (examples.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              '📖 Examples',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...examples.asMap().entries.map((entry) {
              final index = entry.key;
              final example = entry.value;
              final burmeseExample = burmeseExamples.length > index 
                  ? burmeseExamples[index] 
                  : '';
              final romanization = exampleRomanizations.length > index 
                  ? exampleRomanizations[index] 
                  : '';

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
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
                    // Example text with audio
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF42A5F5).withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      color: const Color(0xFF42A5F5),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  example,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => _playAudio(example),
                          icon: const Icon(
                            Icons.volume_up,
                            color: Color(0xFF42A5F5),
                            size: 16,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 30,
                            minHeight: 30,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                    
                    // Example Romanization
                    if (romanization.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.only(left: 32),
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
                    
                    // Burmese Example Translation
                    if (burmeseExample.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.only(left: 32),
                        child: Text(
                          '🇲🇲 $burmeseExample',
                          style: GoogleFonts.notoSansMyanmar(
                            color: Colors.grey.shade400,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
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