// lib/screens/languages/kanji_screen.dart
import 'package:flutter/material.dart';

class KanjiScreen extends StatelessWidget {
  const KanjiScreen({super.key});

  final List<Map<String, String>> _kanji = const [
    {'kanji': '日', 'meaning': 'Day/Sun', 'onyomi': 'にち, じつ', 'kunyomi': 'ひ, か'},
    {'kanji': '月', 'meaning': 'Month/Moon', 'onyomi': 'げつ, がつ', 'kunyomi': 'つき'},
    {'kanji': '火', 'meaning': 'Fire', 'onyomi': 'か', 'kunyomi': 'ひ'},
    {'kanji': '水', 'meaning': 'Water', 'onyomi': 'すい', 'kunyomi': 'みず'},
    {'kanji': '木', 'meaning': 'Tree', 'onyomi': 'もく, ぼく', 'kunyomi': 'き'},
    {'kanji': '金', 'meaning': 'Gold/Money', 'onyomi': 'きん', 'kunyomi': 'かね'},
    {'kanji': '土', 'meaning': 'Earth', 'onyomi': 'ど', 'kunyomi': 'つち'},
    {'kanji': '人', 'meaning': 'Person', 'onyomi': 'じん, にん', 'kunyomi': 'ひと'},
    {'kanji': '大', 'meaning': 'Big', 'onyomi': 'だい', 'kunyomi': 'おお'},
    {'kanji': '小', 'meaning': 'Small', 'onyomi': 'しょう', 'kunyomi': 'ちいさ'},
    {'kanji': '中', 'meaning': 'Middle', 'onyomi': 'ちゅう', 'kunyomi': 'なか'},
    {'kanji': '上', 'meaning': 'Up', 'onyomi': 'じょう', 'kunyomi': 'うえ'},
    {'kanji': '下', 'meaning': 'Down', 'onyomi': 'か', 'kunyomi': 'した'},
    {'kanji': '左', 'meaning': 'Left', 'onyomi': 'さ', 'kunyomi': 'ひだり'},
    {'kanji': '右', 'meaning': 'Right', 'onyomi': 'う', 'kunyomi': 'みぎ'},
    {'kanji': '山', 'meaning': 'Mountain', 'onyomi': 'さん', 'kunyomi': 'やま'},
    {'kanji': '川', 'meaning': 'River', 'onyomi': 'せん', 'kunyomi': 'かわ'},
    {'kanji': '田', 'meaning': 'Rice Field', 'onyomi': 'でん', 'kunyomi': 'た'},
    {'kanji': '口', 'meaning': 'Mouth', 'onyomi': 'こう', 'kunyomi': 'くち'},
    {'kanji': '目', 'meaning': 'Eye', 'onyomi': 'もく', 'kunyomi': 'め'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🇯🇵 Japanese Kanji'),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
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
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _kanji.length,
          itemBuilder: (context, index) {
            final item = _kanji[index];
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
              child: Row(
                children: [
                  // Kanji
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: const Color(0xFF42A5F5).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF42A5F5).withOpacity(0.3),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        item['kanji'] ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
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
                        Text(
                          'Meaning: ${item['meaning'] ?? ''}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // ✅ FIXED: Escaped apostrophes
                        Text(
                          'On\'yomi: ${item['onyomi'] ?? ''}',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'Kun\'yomi: ${item['kunyomi'] ?? ''}',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}