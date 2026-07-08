// lib/screens/languages/alphabet_screen.dart
import 'package:flutter/material.dart';

class AlphabetScreen extends StatefulWidget {
  final String language;

  const AlphabetScreen({super.key, required this.language});

  @override
  State<AlphabetScreen> createState() => _AlphabetScreenState();
}

class _AlphabetScreenState extends State<AlphabetScreen> {
  List<Map<String, String>> _alphabets = [];

  @override
  void initState() {
    super.initState();
    _loadAlphabets();
  }

  void _loadAlphabets() {
    switch (widget.language) {
      case 'english':
        _alphabets = [
          {'letter': 'A', 'pronunciation': 'эй', 'example': 'Apple'},
          {'letter': 'B', 'pronunciation': 'би', 'example': 'Boy'},
          {'letter': 'C', 'pronunciation': 'си', 'example': 'Cat'},
          {'letter': 'D', 'pronunciation': 'ди', 'example': 'Dog'},
          {'letter': 'E', 'pronunciation': 'и', 'example': 'Egg'},
          {'letter': 'F', 'pronunciation': 'эф', 'example': 'Fish'},
          {'letter': 'G', 'pronunciation': 'джи', 'example': 'Girl'},
          {'letter': 'H', 'pronunciation': 'эйч', 'example': 'Hat'},
          {'letter': 'I', 'pronunciation': 'ай', 'example': 'Ice'},
          {'letter': 'J', 'pronunciation': 'джей', 'example': 'Jump'},
          {'letter': 'K', 'pronunciation': 'кей', 'example': 'Kite'},
          {'letter': 'L', 'pronunciation': 'эл', 'example': 'Lion'},
          {'letter': 'M', 'pronunciation': 'эм', 'example': 'Moon'},
          {'letter': 'N', 'pronunciation': 'эн', 'example': 'Nest'},
          {'letter': 'O', 'pronunciation': 'оу', 'example': 'Orange'},
          {'letter': 'P', 'pronunciation': 'пи', 'example': 'Pig'},
          {'letter': 'Q', 'pronunciation': 'кью', 'example': 'Queen'},
          {'letter': 'R', 'pronunciation': 'ар', 'example': 'Rain'},
          {'letter': 'S', 'pronunciation': 'эс', 'example': 'Sun'},
          {'letter': 'T', 'pronunciation': 'ти', 'example': 'Tree'},
          {'letter': 'U', 'pronunciation': 'ю', 'example': 'Umbrella'},
          {'letter': 'V', 'pronunciation': 'ви', 'example': 'Violin'},
          {'letter': 'W', 'pronunciation': 'дабл-ю', 'example': 'Water'},
          {'letter': 'X', 'pronunciation': 'экс', 'example': 'X-ray'},
          {'letter': 'Y', 'pronunciation': 'уай', 'example': 'Yellow'},
          {'letter': 'Z', 'pronunciation': 'зед', 'example': 'Zebra'},
        ];
        break;
      case 'korean':
        _alphabets = [
          {'letter': 'ㄱ', 'pronunciation': '기역', 'example': '가 (ka)'},
          {'letter': 'ㄴ', 'pronunciation': '니은', 'example': '나 (na)'},
          {'letter': 'ㄷ', 'pronunciation': '디귿', 'example': '다 (da)'},
          {'letter': 'ㄹ', 'pronunciation': '리을', 'example': '라 (ra)'},
          {'letter': 'ㅁ', 'pronunciation': '미음', 'example': '마 (ma)'},
          {'letter': 'ㅂ', 'pronunciation': '비읍', 'example': '바 (ba)'},
          {'letter': 'ㅅ', 'pronunciation': '시옷', 'example': '사 (sa)'},
          {'letter': 'ㅇ', 'pronunciation': '이응', 'example': '아 (a)'},
          {'letter': 'ㅈ', 'pronunciation': '지읒', 'example': '자 (ja)'},
          {'letter': 'ㅊ', 'pronunciation': '치읓', 'example': '차 (cha)'},
          {'letter': 'ㅋ', 'pronunciation': '키읔', 'example': '카 (ka)'},
          {'letter': 'ㅌ', 'pronunciation': '티읕', 'example': '타 (ta)'},
          {'letter': 'ㅍ', 'pronunciation': '피읖', 'example': '파 (pa)'},
          {'letter': 'ㅎ', 'pronunciation': '히읗', 'example': '하 (ha)'},
        ];
        break;
      case 'japanese':
        _alphabets = [
          // Hiragana
          {'letter': 'あ', 'pronunciation': '아', 'example': 'あさ (asa - morning)'},
          {'letter': 'い', 'pronunciation': '이', 'example': 'いぬ (inu - dog)'},
          {'letter': 'う', 'pronunciation': '우', 'example': 'うみ (umi - sea)'},
          {'letter': 'え', 'pronunciation': '에', 'example': 'えき (eki - station)'},
          {'letter': 'お', 'pronunciation': '오', 'example': 'おんな (onna - woman)'},
          {'letter': 'か', 'pronunciation': '카', 'example': 'かお (kao - face)'},
          {'letter': 'き', 'pronunciation': '키', 'example': 'きく (kiku - listen)'},
          {'letter': 'く', 'pronunciation': '쿠', 'example': 'くつ (kutsu - shoes)'},
          {'letter': 'け', 'pronunciation': '케', 'example': 'けむり (kemuri - smoke)'},
          {'letter': 'こ', 'pronunciation': '코', 'example': 'こえ (koe - voice)'},
          {'letter': 'さ', 'pronunciation': '사', 'example': 'さかな (sakana - fish)'},
          {'letter': 'し', 'pronunciation': '시', 'example': 'しろ (shiro - white)'},
          {'letter': 'す', 'pronunciation': '스', 'example': 'すし (sushi)'},
          {'letter': 'せ', 'pronunciation': '세', 'example': 'せかい (sekai - world)'},
          {'letter': 'そ', 'pronunciation': '소', 'example': 'そら (sora - sky)'},
        ];
        break;
      case 'chinese':
        _alphabets = [
          {'letter': 'a', 'pronunciation': '아', 'example': 'ā (啊 - ah)'},
          {'letter': 'o', 'pronunciation': '오', 'example': 'ō (哦 - oh)'},
          {'letter': 'e', 'pronunciation': '어', 'example': 'é (额 - forehead)'},
          {'letter': 'i', 'pronunciation': '이', 'example': 'ī (一 - one)'},
          {'letter': 'u', 'pronunciation': '우', 'example': 'ū (五 - five)'},
          {'letter': 'ü', 'pronunciation': '위', 'example': 'ǖ (鱼 - fish)'},
          {'letter': 'b', 'pronunciation': '보', 'example': 'bā (八 - eight)'},
          {'letter': 'p', 'pronunciation': '포', 'example': 'pá (爬 - climb)'},
          {'letter': 'm', 'pronunciation': '모', 'example': 'mā (妈 - mother)'},
          {'letter': 'f', 'pronunciation': '포', 'example': 'fā (发 - hair)'},
          {'letter': 'd', 'pronunciation': '도', 'example': 'dā (搭 - build)'},
          {'letter': 't', 'pronunciation': '토', 'example': 'tā (他 - he)'},
          {'letter': 'n', 'pronunciation': '노', 'example': 'nā (那 - that)'},
          {'letter': 'l', 'pronunciation': '로', 'example': 'lā (拉 - pull)'},
          {'letter': 'g', 'pronunciation': '고', 'example': 'gā (嘎 - quack)'},
          {'letter': 'k', 'pronunciation': '코', 'example': 'kā (卡 - card)'},
          {'letter': 'h', 'pronunciation': '호', 'example': 'hā (哈 - laugh)'},
          {'letter': 'j', 'pronunciation': '지', 'example': 'jī (鸡 - chicken)'},
          {'letter': 'q', 'pronunciation': '치', 'example': 'qī (七 - seven)'},
          {'letter': 'x', 'pronunciation': '시', 'example': 'xī (西 - west)'},
          {'letter': 'zh', 'pronunciation': '즈', 'example': 'zhī (知 - know)'},
          {'letter': 'ch', 'pronunciation': '츠', 'example': 'chī (吃 - eat)'},
          {'letter': 'sh', 'pronunciation': '스', 'example': 'shī (湿 - wet)'},
          {'letter': 'r', 'pronunciation': '르', 'example': 'rì (日 - day)'},
          {'letter': 'z', 'pronunciation': '즈', 'example': 'zī (资 - resource)'},
          {'letter': 'c', 'pronunciation': '츠', 'example': 'cī (刺 - thorn)'},
          {'letter': 's', 'pronunciation': '스', 'example': 'sī (思 - think)'},
        ];
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(_getLanguageFlag(widget.language)),
            const SizedBox(width: 8),
            Text(
              '${widget.language.toUpperCase()} Alphabet',
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
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
          itemCount: _alphabets.length,
          itemBuilder: (context, index) {
            final item = _alphabets[index];
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
                  // Letter
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFF42A5F5).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF42A5F5).withOpacity(0.3),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        item['letter'] ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
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
                          'Pronunciation: ${item['pronunciation'] ?? ''}',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'Example: ${item['example'] ?? ''}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
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