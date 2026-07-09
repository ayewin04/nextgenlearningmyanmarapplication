import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../services/auth_service.dart';
import 'level_selection_screen.dart';
import 'alphabet_screen.dart';
import 'kanji_screen.dart';

class LanguageLearningScreen extends StatefulWidget {
  const LanguageLearningScreen({super.key});

  @override
  State<LanguageLearningScreen> createState() => _LanguageLearningScreenState();
}

class _LanguageLearningScreenState extends State<LanguageLearningScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedLanguage;
  bool _showAlphabet = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isInitialized = false;

  static const Map<String, Map<String, String>> examInfo = {
    'english': {
      'exam': 'IELTS',
      'flag': '🇬🇧',
      'color': '#E53935',
    },
    'korean': {
      'exam': 'TOPIK',
      'flag': '🇰🇷',
      'color': '#1565C0',
    },
    'japanese': {
      'exam': 'JLPT',
      'flag': '🇯🇵',
      'color': '#C62828',
    },
    'chinese': {
      'exam': 'HSK',
      'flag': '🇨🇳',
      'color': '#D32F2F',
    },
  };

  static const Map<String, List<Map<String, dynamic>>> modules = {
    'english': [
      {'icon': '📚', 'name': 'Vocabulary', 'route': 'vocabulary'},
      {'icon': '📝', 'name': 'Grammar', 'route': 'grammar'},
      {'icon': '📖', 'name': 'Exam Prep', 'route': 'exam_questions'},
    ],
    'korean': [
      {'icon': '📚', 'name': 'Vocabulary', 'route': 'vocabulary'},
      {'icon': '📝', 'name': 'Grammar', 'route': 'grammar'},
      {'icon': '📖', 'name': 'Exam Prep', 'route': 'exam_questions'},
    ],
    'japanese': [
      {'icon': '📚', 'name': 'Vocabulary', 'route': 'vocabulary'},
      {'icon': '📝', 'name': 'Grammar', 'route': 'grammar'},
      {'icon': '📖', 'name': 'Exam Prep', 'route': 'exam_questions'},
      {'icon': '🈴', 'name': 'Kanji', 'route': 'kanji'},
    ],
    'chinese': [
      {'icon': '📚', 'name': 'Vocabulary', 'route': 'vocabulary'},
      {'icon': '📝', 'name': 'Grammar', 'route': 'grammar'},
      {'icon': '📖', 'name': 'Exam Prep', 'route': 'exam_questions'},
    ],
  };

  // ===== ENGLISH ALPHABET (A-Z) =====
  static const List<Map<String, dynamic>> englishAlphabet = [
    {'letter': 'A', 'burmese': 'အေ', 'romanization': 'ay'},
    {'letter': 'B', 'burmese': 'ဘီ', 'romanization': 'bee'},
    {'letter': 'C', 'burmese': 'စီ', 'romanization': 'see'},
    {'letter': 'D', 'burmese': 'ဒီ', 'romanization': 'dee'},
    {'letter': 'E', 'burmese': 'အီး', 'romanization': 'ee'},
    {'letter': 'F', 'burmese': 'အက်ဖ်', 'romanization': 'eff'},
    {'letter': 'G', 'burmese': 'ဂျီ', 'romanization': 'jee'},
    {'letter': 'H', 'burmese': 'အိတ်ချ်', 'romanization': 'aich'},
    {'letter': 'I', 'burmese': 'အိုင်', 'romanization': 'eye'},
    {'letter': 'J', 'burmese': 'ဂျေ', 'romanization': 'jay'},
    {'letter': 'K', 'burmese': 'ကေး', 'romanization': 'kay'},
    {'letter': 'L', 'burmese': 'အယ်လ်', 'romanization': 'el'},
    {'letter': 'M', 'burmese': 'အမ်', 'romanization': 'em'},
    {'letter': 'N', 'burmese': 'အင်', 'romanization': 'en'},
    {'letter': 'O', 'burmese': 'အို', 'romanization': 'oh'},
    {'letter': 'P', 'burmese': 'ပီ', 'romanization': 'pee'},
    {'letter': 'Q', 'burmese': 'ကြူး', 'romanization': 'kyuu'},
    {'letter': 'R', 'burmese': 'အား', 'romanization': 'ar'},
    {'letter': 'S', 'burmese': 'အက်စ်', 'romanization': 'ess'},
    {'letter': 'T', 'burmese': 'တီ', 'romanization': 'tee'},
    {'letter': 'U', 'burmese': 'ယူ', 'romanization': 'yoo'},
    {'letter': 'V', 'burmese': 'ဗွီ', 'romanization': 'vee'},
    {'letter': 'W', 'burmese': 'ဒဗ္ဗလျူ', 'romanization': 'dubba loo'},
    {'letter': 'X', 'burmese': 'အိတ်စ်', 'romanization': 'ex'},
    {'letter': 'Y', 'burmese': 'ဝိုင်', 'romanization': 'why'},
    {'letter': 'Z', 'burmese': 'ဇက်', 'romanization': 'zet'},
  ];

  // ===== ENGLISH VOWELS =====
  static const List<Map<String, dynamic>> englishVowels = [
    {'letter': 'A', 'burmese': 'အေ', 'romanization': 'ay'},
    {'letter': 'E', 'burmese': 'အီး', 'romanization': 'ee'},
    {'letter': 'I', 'burmese': 'အိုင်', 'romanization': 'eye'},
    {'letter': 'O', 'burmese': 'အို', 'romanization': 'oh'},
    {'letter': 'U', 'burmese': 'ယူ', 'romanization': 'yoo'},
  ];

  // ===== KOREAN HANGUL - COMPLETE =====

  // 1. Basic Consonants (14)
  static const List<Map<String, dynamic>> koreanConsonants = [
    {'letter': 'ㄱ', 'burmese': 'ဂီယော့', 'romanization': 'giyeok'},
    {'letter': 'ㄴ', 'burmese': 'နီယွန်', 'romanization': 'nieun'},
    {'letter': 'ㄷ', 'burmese': 'ဒီဂုတ်', 'romanization': 'digeut'},
    {'letter': 'ㄹ', 'burmese': 'ရီအူလ်', 'romanization': 'rieul'},
    {'letter': 'ㅁ', 'burmese': 'မီအူမ်', 'romanization': 'mieum'},
    {'letter': 'ㅂ', 'burmese': 'ဘီအူပ်', 'romanization': 'bieup'},
    {'letter': 'ㅅ', 'burmese': 'စီအုတ်', 'romanization': 'siot'},
    {'letter': 'ㅇ', 'burmese': 'အီအုန်', 'romanization': 'ieung'},
    {'letter': 'ㅈ', 'burmese': 'ဂျီအူတ်', 'romanization': 'jieut'},
    {'letter': 'ㅊ', 'burmese': 'ချီအူတ်', 'romanization': 'chieut'},
    {'letter': 'ㅋ', 'burmese': 'ခီအူခ်', 'romanization': 'kieuk'},
    {'letter': 'ㅌ', 'burmese': 'ထီအူတ်', 'romanization': 'tieut'},
    {'letter': 'ㅍ', 'burmese': 'ဖီအူပ်', 'romanization': 'pieup'},
    {'letter': 'ㅎ', 'burmese': 'ဟီအူတ်', 'romanization': 'hieut'},
  ];

  // 2. Double Consonants (5)
  static const List<Map<String, dynamic>> koreanDoubleConsonants = [
    {'letter': 'ㄲ', 'burmese': 'ဆန်းဂီယော့', 'romanization': 'ssang giyeok'},
    {'letter': 'ㄸ', 'burmese': 'ဆန်းဒီဂုတ်', 'romanization': 'ssang digeut'},
    {'letter': 'ㅃ', 'burmese': 'ဆန်းဘီအူပ်', 'romanization': 'ssang bieup'},
    {'letter': 'ㅆ', 'burmese': 'ဆန်းစီအုတ်', 'romanization': 'ssang siot'},
    {'letter': 'ㅉ', 'burmese': 'ဆန်းဂျီအူတ်', 'romanization': 'ssang jieut'},
  ];

  // 3. Basic Vowels (10)
  static const List<Map<String, dynamic>> koreanVowels = [
    {'letter': 'ㅏ', 'burmese': 'အ', 'romanization': 'a'},
    {'letter': 'ㅑ', 'burmese': 'ယ', 'romanization': 'ya'},
    {'letter': 'ㅓ', 'burmese': 'အော', 'romanization': 'eo'},
    {'letter': 'ㅕ', 'burmese': 'ယော', 'romanization': 'yeo'},
    {'letter': 'ㅗ', 'burmese': 'အို', 'romanization': 'o'},
    {'letter': 'ㅛ', 'burmese': 'ယို', 'romanization': 'yo'},
    {'letter': 'ㅜ', 'burmese': 'အူ', 'romanization': 'u'},
    {'letter': 'ㅠ', 'burmese': 'ယူ', 'romanization': 'yu'},
    {'letter': 'ㅡ', 'burmese': 'အွ', 'romanization': 'eu'},
    {'letter': 'ㅣ', 'burmese': 'အီ', 'romanization': 'i'},
  ];

  // 4. Compound Vowels (11) - Diphthongs
  static const List<Map<String, dynamic>> koreanCompoundVowels = [
    {'letter': 'ㅐ', 'burmese': 'အဲ', 'romanization': 'ae'},
    {'letter': 'ㅒ', 'burmese': 'ယဲ', 'romanization': 'yae'},
    {'letter': 'ㅔ', 'burmese': 'အေ', 'romanization': 'e'},
    {'letter': 'ㅖ', 'burmese': 'ယေ', 'romanization': 'ye'},
    {'letter': 'ㅘ', 'burmese': 'ဝါ', 'romanization': 'wa'},
    {'letter': 'ㅙ', 'burmese': 'ဝဲ', 'romanization': 'wae'},
    {'letter': 'ㅚ', 'burmese': 'အိုအေ', 'romanization': 'oe'},
    {'letter': 'ㅝ', 'burmese': 'ဝေါ', 'romanization': 'wo'},
    {'letter': 'ㅞ', 'burmese': 'ဝေ', 'romanization': 'we'},
    {'letter': 'ㅟ', 'burmese': 'ဝီ', 'romanization': 'wi'},
    {'letter': 'ㅢ', 'burmese': 'အီ', 'romanization': 'ui'},
  ];

  // 5. Batchim (Final Consonants) - 7 Representative Sounds
  static const List<Map<String, dynamic>> koreanBatchim = [
    {'letter': 'ㄱ', 'burmese': 'ခ', 'romanization': 'k'},
    {'letter': 'ㄴ', 'burmese': 'န်', 'romanization': 'n'},
    {'letter': 'ㄷ', 'burmese': 'တ်', 'romanization': 't'},
    {'letter': 'ㄹ', 'burmese': 'လ်', 'romanization': 'l'},
    {'letter': 'ㅁ', 'burmese': 'မ်', 'romanization': 'm'},
    {'letter': 'ㅂ', 'burmese': 'ပ်', 'romanization': 'p'},
    {'letter': 'ㅇ', 'burmese': 'င်', 'romanization': 'ng'},
  ];

  // 6. Complex Batchim (11)
  static const List<Map<String, dynamic>> koreanComplexBatchim = [
    {'letter': 'ㄳ', 'burmese': 'ဂ်စ်', 'romanization': 'gs'},
    {'letter': 'ㄵ', 'burmese': 'န်ဇ်', 'romanization': 'nj'},
    {'letter': 'ㄶ', 'burmese': 'န်ဟ်', 'romanization': 'nh'},
    {'letter': 'ㄺ', 'burmese': 'လ်ဂ်', 'romanization': 'lg'},
    {'letter': 'ㄻ', 'burmese': 'လ်မ်', 'romanization': 'lm'},
    {'letter': 'ㄼ', 'burmese': 'လ်ဘ်', 'romanization': 'lb'},
    {'letter': 'ㄽ', 'burmese': 'လ်စ်', 'romanization': 'ls'},
    {'letter': 'ㄾ', 'burmese': 'လ်ထ်', 'romanization': 'lt'},
    {'letter': 'ㄿ', 'burmese': 'လ်ဖ်', 'romanization': 'lp'},
    {'letter': 'ㅀ', 'burmese': 'လ်ဟ်', 'romanization': 'lh'},
    {'letter': 'ㅄ', 'burmese': 'ဗ်စ်', 'romanization': 'bs'},
  ];

  // ===== JAPANESE HIRAGANA (Full) =====
  static const List<Map<String, dynamic>> japaneseAlphabet = [
    {'letter': 'あ', 'burmese': 'အ', 'romanization': 'a'},
    {'letter': 'い', 'burmese': 'အိ', 'romanization': 'i'},
    {'letter': 'う', 'burmese': 'အူ', 'romanization': 'u'},
    {'letter': 'え', 'burmese': 'အေ', 'romanization': 'e'},
    {'letter': 'お', 'burmese': 'အို', 'romanization': 'o'},
    {'letter': 'か', 'burmese': 'က', 'romanization': 'ka'},
    {'letter': 'き', 'burmese': 'ခိ', 'romanization': 'ki'},
    {'letter': 'く', 'burmese': 'ခု', 'romanization': 'ku'},
    {'letter': 'け', 'burmese': 'ခေ', 'romanization': 'ke'},
    {'letter': 'こ', 'burmese': 'ကို', 'romanization': 'ko'},
    {'letter': 'さ', 'burmese': 'ဆ', 'romanization': 'sa'},
    {'letter': 'し', 'burmese': 'ရှိ', 'romanization': 'shi'},
    {'letter': 'す', 'burmese': 'စု', 'romanization': 'su'},
    {'letter': 'せ', 'burmese': 'စေ', 'romanization': 'se'},
    {'letter': 'そ', 'burmese': 'စို', 'romanization': 'so'},
    {'letter': 'た', 'burmese': 'တ', 'romanization': 'ta'},
    {'letter': 'ち', 'burmese': 'ချိ', 'romanization': 'chi'},
    {'letter': 'つ', 'burmese': 'ဆု', 'romanization': 'tsu'},
    {'letter': 'て', 'burmese': 'တေ', 'romanization': 'te'},
    {'letter': 'と', 'burmese': 'တို', 'romanization': 'to'},
    {'letter': 'な', 'burmese': 'န', 'romanization': 'na'},
    {'letter': 'に', 'burmese': 'နိ', 'romanization': 'ni'},
    {'letter': 'ぬ', 'burmese': 'နု', 'romanization': 'nu'},
    {'letter': 'ね', 'burmese': 'နေ', 'romanization': 'ne'},
    {'letter': 'の', 'burmese': 'နို', 'romanization': 'no'},
    {'letter': 'は', 'burmese': 'ဟ', 'romanization': 'ha'},
    {'letter': 'ひ', 'burmese': 'ဟိ', 'romanization': 'hi'},
    {'letter': 'ふ', 'burmese': 'ဖု', 'romanization': 'fu'},
    {'letter': 'へ', 'burmese': 'ဟေ', 'romanization': 'he'},
    {'letter': 'ほ', 'burmese': 'ဟို', 'romanization': 'ho'},
    {'letter': 'ま', 'burmese': 'မ', 'romanization': 'ma'},
    {'letter': 'み', 'burmese': 'မိ', 'romanization': 'mi'},
    {'letter': 'む', 'burmese': 'မု', 'romanization': 'mu'},
    {'letter': 'め', 'burmese': 'မေ', 'romanization': 'me'},
    {'letter': 'も', 'burmese': 'မို', 'romanization': 'mo'},
    {'letter': 'や', 'burmese': 'ယ', 'romanization': 'ya'},
    {'letter': 'ゆ', 'burmese': 'ယု', 'romanization': 'yu'},
    {'letter': 'よ', 'burmese': 'ယို', 'romanization': 'yo'},
    {'letter': 'ら', 'burmese': 'ရ', 'romanization': 'ra'},
    {'letter': 'り', 'burmese': 'ရိ', 'romanization': 'ri'},
    {'letter': 'る', 'burmese': 'ရု', 'romanization': 'ru'},
    {'letter': 'れ', 'burmese': 'ရေ', 'romanization': 're'},
    {'letter': 'ろ', 'burmese': 'ရို', 'romanization': 'ro'},
    {'letter': 'わ', 'burmese': 'ဝ', 'romanization': 'wa'},
    {'letter': 'を', 'burmese': 'အို', 'romanization': 'wo'},
    {'letter': 'ん', 'burmese': 'အွန်', 'romanization': 'n'},
  ];

  // ===== JAPANESE VOWELS =====
  static const List<Map<String, dynamic>> japaneseVowels = [
    {'letter': 'あ', 'burmese': 'အ', 'romanization': 'a'},
    {'letter': 'い', 'burmese': 'အိ', 'romanization': 'i'},
    {'letter': 'う', 'burmese': 'အူ', 'romanization': 'u'},
    {'letter': 'え', 'burmese': 'အေ', 'romanization': 'e'},
    {'letter': 'お', 'burmese': 'အို', 'romanization': 'o'},
  ];

  // ===== CHINESE PINYIN =====
  static const List<Map<String, dynamic>> chineseAlphabet = [
    {'letter': 'a', 'burmese': 'အ', 'romanization': 'a'},
    {'letter': 'o', 'burmese': 'အို', 'romanization': 'o'},
    {'letter': 'e', 'burmese': 'အေ', 'romanization': 'e'},
    {'letter': 'i', 'burmese': 'အိ', 'romanization': 'i'},
    {'letter': 'u', 'burmese': 'အူ', 'romanization': 'u'},
    {'letter': 'ü', 'burmese': 'အွီ', 'romanization': 'ü'},
    {'letter': 'b', 'burmese': 'ဘ', 'romanization': 'b'},
    {'letter': 'p', 'burmese': 'ဖ', 'romanization': 'p'},
    {'letter': 'm', 'burmese': 'မ', 'romanization': 'm'},
    {'letter': 'f', 'burmese': 'ဖ', 'romanization': 'f'},
    {'letter': 'd', 'burmese': 'ဒ', 'romanization': 'd'},
    {'letter': 't', 'burmese': 'ထ', 'romanization': 't'},
    {'letter': 'n', 'burmese': 'န', 'romanization': 'n'},
    {'letter': 'l', 'burmese': 'လ', 'romanization': 'l'},
    {'letter': 'g', 'burmese': 'ဂ', 'romanization': 'g'},
    {'letter': 'k', 'burmese': 'ခ', 'romanization': 'k'},
    {'letter': 'h', 'burmese': 'ဟ', 'romanization': 'h'},
    {'letter': 'j', 'burmese': 'ဂျ', 'romanization': 'j'},
    {'letter': 'q', 'burmese': 'ချ', 'romanization': 'q'},
    {'letter': 'x', 'burmese': 'ရှ', 'romanization': 'x'},
    {'letter': 'zh', 'burmese': 'ဂျ', 'romanization': 'zh'},
    {'letter': 'ch', 'burmese': 'ချ', 'romanization': 'ch'},
    {'letter': 'sh', 'burmese': 'ရှ', 'romanization': 'sh'},
    {'letter': 'r', 'burmese': 'ရ', 'romanization': 'r'},
    {'letter': 'z', 'burmese': 'ဇ', 'romanization': 'z'},
    {'letter': 'c', 'burmese': 'ဆ', 'romanization': 'c'},
    {'letter': 's', 'burmese': 'စ', 'romanization': 's'},
  ];

  // ===== CHINESE VOWELS =====
  static const List<Map<String, dynamic>> chineseVowels = [
    {'letter': 'a', 'burmese': 'အ', 'romanization': 'a'},
    {'letter': 'o', 'burmese': 'အို', 'romanization': 'o'},
    {'letter': 'e', 'burmese': 'အေ', 'romanization': 'e'},
    {'letter': 'i', 'burmese': 'အိ', 'romanization': 'i'},
    {'letter': 'u', 'burmese': 'အူ', 'romanization': 'u'},
    {'letter': 'ü', 'burmese': 'အွီ', 'romanization': 'ü'},
  ];

  @override
  void initState() {
    super.initState();
    
    // ✅ Initialize animation controller first
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _isInitialized = true;
    
    // ✅ Load language after animation is initialized
    _loadSelectedLanguage();
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ✅ Only reload if initialized
    if (_isInitialized) {
      _loadSelectedLanguage();
    }
  }

  void _loadSelectedLanguage() {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.userModel;
      if (user != null && user.targetLanguages.isNotEmpty) {
        final newLanguage = user.targetLanguages.first;
        if (_selectedLanguage != newLanguage) {
          setState(() {
            _selectedLanguage = newLanguage;
          });
          // ✅ Only animate if controller is initialized
          if (_isInitialized) {
            _animationController.reset();
            _animationController.forward();
          }
        }
      }
    } catch (e) {
      print('Error loading selected language: $e');
    }
  }

  List<Map<String, dynamic>> _getAlphabetData() {
    switch (_selectedLanguage) {
      case 'english': return englishAlphabet;
      case 'korean': return koreanConsonants;
      case 'japanese': return japaneseAlphabet;
      case 'chinese': return chineseAlphabet;
      default: return [];
    }
  }

  List<Map<String, dynamic>> _getVowelData() {
    switch (_selectedLanguage) {
      case 'english': return englishVowels;
      case 'korean': return koreanVowels;
      case 'japanese': return japaneseVowels;
      case 'chinese': return chineseVowels;
      default: return [];
    }
  }

  List<Map<String, dynamic>> _getAdditionalKoreanData() {
    switch (_selectedLanguage) {
      case 'korean':
        return [
          ...koreanDoubleConsonants,
          ...koreanCompoundVowels,
          ...koreanBatchim,
          ...koreanComplexBatchim,
        ];
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.userModel;

    if (_selectedLanguage == null && user != null && user.targetLanguages.isNotEmpty) {
      _selectedLanguage = user.targetLanguages.first;
    }

    return Container(
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '📚 Your Learning Center',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _selectedLanguage != null
                    ? 'Learning ${_selectedLanguage!.toUpperCase()}'
                    : 'No language selected',
                style: TextStyle(
                  color: _selectedLanguage != null
                      ? Colors.grey.shade400
                      : Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),

              if (_selectedLanguage != null)
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildAlphabetSection(),
                ),
              const SizedBox(height: 16),

              if (_selectedLanguage == null)
                Expanded(
                  child: Center(
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
                          'No language selected',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Go to Home tab and tap "Start Learning"',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF42A5F5),
                          ),
                          child: const Text('Go Back'),
                        ),
                      ],
                    ),
                  ),
                ),

              if (_selectedLanguage != null)
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: modules[_selectedLanguage]?.length ?? 0,
                    itemBuilder: (context, index) {
                      final module = modules[_selectedLanguage]![index];
                      return _buildModuleCard(
                        context,
                        icon: module['icon'],
                        name: module['name'],
                        onTap: () {
                          _navigateToModule(
                            context,
                            _selectedLanguage!,
                            module['route'],
                          );
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlphabetSection() {
    final alphabet = _getAlphabetData();
    final vowels = _getVowelData();
    final additionalKorean = _getAdditionalKoreanData();
    final exam = examInfo[_selectedLanguage]?['exam'] ?? '';

    final isKorean = _selectedLanguage == 'korean';
    final allLetters = isKorean ? [...alphabet, ...vowels, ...additionalKorean] : [...alphabet, ...vowels];
    final totalLetters = allLetters.length;

    return Container(
      constraints: BoxConstraints(
        maxHeight: 220,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade800.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade700.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      '🔤 Alphabet & Vowels',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF42A5F5).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        exam,
                        style: const TextStyle(
                          color: Color(0xFF42A5F5),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$totalLetters letters',
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 8,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _showAlphabet = !_showAlphabet;
                        });
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF42A5F5),
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                      ),
                      child: Text(
                        _showAlphabet ? 'Hide' : 'Show',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (_showAlphabet)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Consonants Section (for Korean, show basic + double consonants)
                    if (_selectedLanguage == 'korean') ...[
                      Text(
                        '📖 Basic Consonants',
                        style: TextStyle(
                          color: Colors.blue.shade300,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        height: 48,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: koreanConsonants.length,
                          itemBuilder: (context, index) {
                            final letter = koreanConsonants[index];
                            return _buildAlphabetCard(
                              letter: letter['letter'],
                              burmese: letter['burmese'],
                              romanization: letter['romanization'],
                              type: 'consonant',
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 6),

                      Text(
                        '📖 Double Consonants',
                        style: TextStyle(
                          color: Colors.blue.shade300,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        height: 48,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: koreanDoubleConsonants.length,
                          itemBuilder: (context, index) {
                            final letter = koreanDoubleConsonants[index];
                            return _buildAlphabetCard(
                              letter: letter['letter'],
                              burmese: letter['burmese'],
                              romanization: letter['romanization'],
                              type: 'consonant',
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],

                    // Alphabet Section (for non-Korean, show all)
                    if (_selectedLanguage != 'korean') ...[
                      Text(
                        '🔤 Alphabet',
                        style: TextStyle(
                          color: Colors.blue.shade300,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        height: 48,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: alphabet.length,
                          itemBuilder: (context, index) {
                            final letter = alphabet[index];
                            return _buildAlphabetCard(
                              letter: letter['letter'],
                              burmese: letter['burmese'],
                              romanization: letter['romanization'],
                              type: 'alphabet',
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],

                    // Vowels Section
                    Text(
                      '📖 Vowels',
                      style: TextStyle(
                        color: Colors.purple.shade300,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      height: 48,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: vowels.length,
                        itemBuilder: (context, index) {
                          final vowel = vowels[index];
                          return _buildAlphabetCard(
                            letter: vowel['letter'],
                            burmese: vowel['burmese'],
                            romanization: vowel['romanization'],
                            type: 'vowel',
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Korean Compound Vowels
                    if (_selectedLanguage == 'korean') ...[
                      Text(
                        '📖 Compound Vowels',
                        style: TextStyle(
                          color: Colors.purple.shade300,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        height: 48,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: koreanCompoundVowels.length,
                          itemBuilder: (context, index) {
                            final letter = koreanCompoundVowels[index];
                            return _buildAlphabetCard(
                              letter: letter['letter'],
                              burmese: letter['burmese'],
                              romanization: letter['romanization'],
                              type: 'vowel',
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Korean Batchim (Final Consonants)
                      Text(
                        '📖 Batchim (Final Consonants)',
                        style: TextStyle(
                          color: Colors.orange.shade300,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        height: 48,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: koreanBatchim.length,
                          itemBuilder: (context, index) {
                            final letter = koreanBatchim[index];
                            return _buildAlphabetCard(
                              letter: letter['letter'],
                              burmese: letter['burmese'],
                              romanization: letter['romanization'],
                              type: 'batchim',
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Korean Complex Batchim
                      Text(
                        '📖 Complex Batchim',
                        style: TextStyle(
                          color: Colors.orange.shade300,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        height: 48,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: koreanComplexBatchim.length,
                          itemBuilder: (context, index) {
                            final letter = koreanComplexBatchim[index];
                            return _buildAlphabetCard(
                              letter: letter['letter'],
                              burmese: letter['burmese'],
                              romanization: letter['romanization'],
                              type: 'batchim',
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAlphabetCard({
    required String letter,
    required String burmese,
    required String romanization,
    required String type,
  }) {
    Color? color;
    if (type == 'vowel') {
      color = Colors.purple.shade300;
    } else if (type == 'batchim') {
      color = Colors.orange.shade300;
    } else {
      color = Colors.blue.shade300;
    }

    return Container(
      width: 50,
      margin: const EdgeInsets.only(right: 3),
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 3),
      decoration: BoxDecoration(
        color: type == 'vowel'
            ? Colors.purple.withOpacity(0.15)
            : type == 'batchim'
                ? Colors.orange.withOpacity(0.15)
                : Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: type == 'vowel'
              ? Colors.purple.withOpacity(0.3)
              : type == 'batchim'
                  ? Colors.orange.withOpacity(0.3)
                  : Colors.blue.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            letter,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            burmese,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 7,
            ),
          ),
          Text(
            romanization,
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 6,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleCard(
    BuildContext context, {
    required String icon,
    required String name,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.grey.shade800.withOpacity(0.3),
              Colors.grey.shade900.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.grey.shade700.withOpacity(0.3),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF42A5F5).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Start Learning',
                style: TextStyle(
                  color: Color(0xFF42A5F5),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToModule(BuildContext context, String language, String route) {
    final exam = examInfo[language]?['exam'] ?? '';

    switch (route) {
      case 'vocabulary':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LevelSelectionScreen(
              language: language,
              exam: exam,
              module: 'vocabulary',
              moduleIcon: '📚',
              moduleName: 'Vocabulary',
            ),
          ),
        );
        break;
      case 'grammar':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LevelSelectionScreen(
              language: language,
              exam: exam,
              module: 'grammar',
              moduleIcon: '📝',
              moduleName: 'Grammar',
            ),
          ),
        );
        break;
      case 'exam_questions':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LevelSelectionScreen(
              language: language,
              exam: exam,
              module: 'exam_questions',
              moduleIcon: '📖',
              moduleName: 'Exam Prep',
            ),
          ),
        );
        break;
      case 'kanji':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const KanjiScreen(),
          ),
        );
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Coming soon: $route'),
            backgroundColor: Colors.orange,
          ),
        );
    }
  }
}