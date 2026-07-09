import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/firestore_service.dart';

class KanjiScreen extends StatefulWidget {
  const KanjiScreen({super.key});

  @override
  State<KanjiScreen> createState() => _KanjiScreenState();
}

class _KanjiScreenState extends State<KanjiScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<Map<String, dynamic>> _kanji = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadKanji();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadKanji() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get kanji from Firestore
      final snapshot = await _firestoreService.getKanji();
      
      setState(() {
        _kanji = snapshot;
        _isLoading = false;
      });
      
      print('✅ Loaded ${_kanji.length} kanji characters');
    } catch (e) {
      print('❌ Error loading kanji: $e');
      setState(() {
        _error = 'Failed to load kanji: $e';
        _isLoading = false;
      });
    }
  }

  void _playAudio(String text) async {
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔊 No audio available'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    try {
      final url =
          'https://api.voicerss.org/'
          '?key=58cd10774f4c4322a6dd8c114650d8a3'
          '&hl=ja-jp'
          '&src=${Uri.encodeComponent(text)}'
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

  void _filterKanji(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  List<Map<String, dynamic>> get _filteredKanji {
    if (_searchQuery.isEmpty) return _kanji;
    return _kanji.where((item) {
      final kanji = (item['kanji'] ?? '').toLowerCase();
      final meaning = (item['meaning'] ?? '').toLowerCase();
      final onyomi = (item['onyomi'] ?? '').toLowerCase();
      final kunyomi = (item['kunyomi'] ?? '').toLowerCase();
      final burmese = (item['burmeseMeaning'] ?? '').toLowerCase();
      final search = _searchQuery.toLowerCase();
      return kanji.contains(search) ||
          meaning.contains(search) ||
          onyomi.contains(search) ||
          kunyomi.contains(search) ||
          burmese.contains(search);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _filteredKanji;

    return Scaffold(
      appBar: AppBar(
        title: const Text('🇯🇵 Japanese Kanji'),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              onChanged: _filterKanji,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: '🔍 Search kanji...',
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
                : _kanji.isEmpty
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
                              final item = filteredList[index];
                              return _buildKanjiCard(item);
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
              onPressed: _loadKanji,
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
            Icons.abc,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'No kanji available',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            'Add kanji to the kanji collection',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKanjiCard(Map<String, dynamic> item) {
    final kanji = item['kanji'] ?? '';
    final meaning = item['meaning'] ?? '';
    final burmeseMeaning = item['burmeseMeaning'] ?? '';
    final onyomi = item['onyomi'] ?? '';
    final onyomiRoman = item['onyomiRoman'] ?? '';
    final kunyomi = item['kunyomi'] ?? '';
    final kunyomiRoman = item['kunyomiRoman'] ?? '';
    final strokeCount = item['strokeCount'] ?? 0;
    final jlptLevel = item['jlptLevel'] ?? '';
    final grade = item['grade'] ?? '';

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
          // Kanji with Audio Button
          Row(
            children: [
              // Kanji Character
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF42A5F5).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF42A5F5).withOpacity(0.3),
                  ),
                ),
                child: Center(
                  child: Text(
                    kanji,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Meaning
                    Text(
                      'Meaning: $meaning',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (burmeseMeaning.isNotEmpty)
                      Text(
                        '🇲🇲 $burmeseMeaning',
                        style: GoogleFonts.notoSansMyanmar(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    const SizedBox(height: 4),
                    // JLPT Level and Grade
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (jlptLevel.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'JLPT $jlptLevel',
                              style: TextStyle(
                                color: Colors.green.shade300,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        if (grade.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Grade $grade',
                              style: TextStyle(
                                color: Colors.orange.shade300,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        if (strokeCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.purple.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$strokeCount strokes',
                              style: TextStyle(
                                color: Colors.purple.shade300,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    onPressed: () => _playAudio(kanji),
                    icon: const Icon(
                      Icons.volume_up,
                      color: Color(0xFF42A5F5),
                      size: 24,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // On'yomi and Kun'yomi with Burmese translations
          Row(
            children: [
              Expanded(
                child: Container(
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
                      Row(
                        children: [
                          const Text(
                            'On\'yomi: ',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              onyomi,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          if (onyomiRoman.isNotEmpty)
                            IconButton(
                              onPressed: () => _playAudio(onyomiRoman),
                              icon: const Icon(
                                Icons.volume_up,
                                color: Color(0xFF42A5F5),
                                size: 14,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 24,
                                minHeight: 24,
                              ),
                              padding: EdgeInsets.zero,
                            ),
                        ],
                      ),
                      if (onyomiRoman.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            onyomiRoman,
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
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
                      Row(
                        children: [
                          const Text(
                            'Kun\'yomi: ',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              kunyomi,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          if (kunyomiRoman.isNotEmpty)
                            IconButton(
                              onPressed: () => _playAudio(kunyomiRoman),
                              icon: const Icon(
                                Icons.volume_up,
                                color: Color(0xFF42A5F5),
                                size: 14,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 24,
                                minHeight: 24,
                              ),
                              padding: EdgeInsets.zero,
                            ),
                        ],
                      ),
                      if (kunyomiRoman.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            kunyomiRoman,
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
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