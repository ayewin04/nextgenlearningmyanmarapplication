import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/firestore_service.dart';
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
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<ExamVocabularyModel> _vocabularies = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadVocabulary();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadVocabulary() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('🔍 Loading exam vocabulary for: ${widget.exam}, level: ${widget.level}');
      
      // Get data from Firestore
      final vocabData = await _firestoreService.getExamVocabularyByLevel(
        exam: widget.exam.toLowerCase(),
        level: widget.level,
        limit: 100,
      );
      
      // Convert to ExamVocabularyModel
      _vocabularies = vocabData.map((data) {
        return ExamVocabularyModel.fromMap(
          data['id'] ?? data['word'] ?? '',
          data,
        );
      }).toList();
      
      print('✅ Loaded ${_vocabularies.length} vocabulary words');
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading vocabulary: $e');
      setState(() {
        _error = 'Failed to load vocabulary: $e';
        _isLoading = false;
      });
    }
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

  final langMap = {
    'english': 'en-us',
    'korean': 'ko-kr',
    'japanese': 'ja-jp',
    'chinese': 'zh-cn',
  };

  try {
    final url =
        'https://api.voicerss.org/'
        '?key=58cd10774f4c4322a6dd8c114650d8a3'
        '&hl=${langMap[widget.language] ?? 'en-us'}'
        '&src=${Uri.encodeComponent(word)}'
        '&c=MP3';

    await _audioPlayer.play(UrlSource(url));
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

void _playAudioMobile(String text) async {
  try {
    final langMap = {
      'english': 'en-us',
      'korean': 'ko-kr',
      'japanese': 'ja-jp',
      'chinese': 'zh-cn',
    };
    final url =
        'https://api.voicerss.org/'
        '?key=58cd10774f4c4322a6dd8c114650d8a3'
        '&hl=${langMap[widget.language] ?? 'en-us'}'
        '&src=${Uri.encodeComponent(text)}'
        '&c=MP3';

    await _audioPlayer.play(UrlSource(url));
  } catch (e) {
    print('❌ Mobile audio error: $e');
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

  String _getVoiceRssLanguageCode(String language) {
    const codes = {
      'english': 'en-us',
      'korean': 'ko-kr',
      'japanese': 'ja-jp',
      'chinese': 'zh-cn',
    };
    return codes[language] ?? 'en-us';
  }

  void _filterVocabulary(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  List<ExamVocabularyModel> get _filteredVocabularies {
    if (_searchQuery.isEmpty) return _vocabularies;
    return _vocabularies.where((vocab) {
      final word = vocab.word.toLowerCase();
      final meaning = vocab.meaning.toLowerCase();
      final burmese = vocab.burmeseWord.toLowerCase();
      final search = _searchQuery.toLowerCase();
      return word.contains(search) ||
          meaning.contains(search) ||
          burmese.contains(search);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _filteredVocabularies;

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
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredList.length,
                            itemBuilder: (context, index) {
                              final vocab = filteredList[index];
                              return _buildVocabularyCard(vocab);
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
              onPressed: _loadVocabulary,
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
        ],
      ),
    );
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

Widget _buildVocabularyCard(ExamVocabularyModel vocab) {
  final word = vocab.word;
  final meaning = vocab.meaning;
  final partOfSpeech = vocab.partOfSpeech ?? 'noun';
  final exampleSentence = vocab.exampleSentence ?? '';
  final exampleRomanization = vocab.exampleRomanization ?? ''; // ✅ This is the key
  final pronunciation = vocab.getPronunciationDisplay();
  final burmeseWord = vocab.burmeseWord;
  final romanization = vocab.romanization;
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
                // Example in target language (Korean, Japanese, Chinese)
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
                // ✅ Example Romanization (Korean/Japanese/Chinese romanization)
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