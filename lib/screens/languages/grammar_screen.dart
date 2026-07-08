import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:html' as html;
import '../../services/firestore_service.dart';

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
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<Map<String, dynamic>> _grammar = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadGrammar();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadGrammar() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final grammar = await _firestoreService.getGrammarByLevel(
        exam: widget.exam.toLowerCase(),
        level: widget.level,
      );
      
      print('✅ Loaded ${grammar.length} grammar lessons for ${widget.exam} - ${widget.level}');
      
      setState(() {
        _grammar = grammar;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading grammar: $e');
      setState(() {
        _error = 'Failed to load grammar: $e';
        _isLoading = false;
      });
    }
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

    final bool isWeb = identical(0, 0.0) ? false : true;

    if (isWeb) {
      try {
        final synth = html.window.speechSynthesis;
        if (synth == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🔊 Speech synthesis not supported on this browser.'),
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }

        if (synth.speaking == true) {
          synth.cancel();
        }
        
        final utterance = html.SpeechSynthesisUtterance(text);
        
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🔊 Audio not available on this browser.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      try {
        final url =
            'https://api.voicerss.org/'
            '?key=58cd10774f4c4322a6dd8c114650d8a3'
            '&hl=${_getVoiceRssLanguageCode(widget.language)}'
            '&src=${Uri.encodeComponent(text)}'
            '&c=MP3';

        await _audioPlayer.play(UrlSource(url));

      } catch (e) {
        print('❌ [Android] Audio error: $e');
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

  String _getVoiceRssLanguageCode(String language) {
    const codes = {
      'english': 'en-us',
      'korean': 'ko-kr',
      'japanese': 'ja-jp',
      'chinese': 'zh-cn',
    };
    return codes[language] ?? 'en-us';
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
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredList.length,
                            itemBuilder: (context, index) {
                              final lesson = filteredList[index];
                              return _buildGrammarCard(lesson);
                            },
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
              onPressed: _loadGrammar,
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
                  // Title with Romanization
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