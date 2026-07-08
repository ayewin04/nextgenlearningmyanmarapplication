// lib/screens/languages/language_learning_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';  // ✅ ADD THIS
import '../../services/auth_service.dart';  // ✅ ADD THIS
import 'language_exam_screen.dart';
import 'vocabulary_screen.dart';
import 'grammar_screen.dart';
import 'alphabet_screen.dart';
import 'kanji_screen.dart';

class LanguageLearningScreen extends StatefulWidget {
  const LanguageLearningScreen({super.key});

  @override
  State<LanguageLearningScreen> createState() => _LanguageLearningScreenState();
}

class _LanguageLearningScreenState extends State<LanguageLearningScreen> {
  String? _selectedLanguage;

  // Exam types for each language
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

  // Language modules
  static const Map<String, List<Map<String, dynamic>>> modules = {
    'english': [
      {'icon': '📚', 'name': 'Vocabulary', 'route': 'vocabulary'},
      {'icon': '📝', 'name': 'Grammar', 'route': 'grammar'},
      {'icon': '📖', 'name': 'IELTS Prep', 'route': 'exam'},
      {'icon': '🔤', 'name': 'Alphabet', 'route': 'alphabet'},
    ],
    'korean': [
      {'icon': '📚', 'name': 'Vocabulary', 'route': 'vocabulary'},
      {'icon': '📝', 'name': 'Grammar', 'route': 'grammar'},
      {'icon': '📖', 'name': 'TOPIK Prep', 'route': 'exam'},
      {'icon': '🔤', 'name': 'Hangul', 'route': 'alphabet'},
    ],
    'japanese': [
      {'icon': '📚', 'name': 'Vocabulary', 'route': 'vocabulary'},
      {'icon': '📝', 'name': 'Grammar', 'route': 'grammar'},
      {'icon': '📖', 'name': 'JLPT Prep', 'route': 'exam'},
      {'icon': '🈴', 'name': 'Kanji', 'route': 'kanji'},
      {'icon': '🔤', 'name': 'Hiragana/Katakana', 'route': 'alphabet'},
    ],
    'chinese': [
      {'icon': '📚', 'name': 'Vocabulary', 'route': 'vocabulary'},
      {'icon': '📝', 'name': 'Grammar', 'route': 'grammar'},
      {'icon': '📖', 'name': 'HSK Prep', 'route': 'exam'},
      {'icon': '🔤', 'name': 'Pinyin', 'route': 'alphabet'},
    ],
  };

  @override
  Widget build(BuildContext context) {
    // ✅ FIXED: Use Provider correctly
    final userLanguages = Provider.of<AuthService>(context, listen: true)
        .userModel
        ?.targetLanguages ?? [];

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
                'Select a language to start learning',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),

              // Language Selection Tabs
              if (userLanguages.isNotEmpty)
                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: userLanguages.length,
                    itemBuilder: (context, index) {
                      final lang = userLanguages[index];
                      final info = examInfo[lang] ?? {};
                      final isSelected = _selectedLanguage == lang;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedLanguage = lang;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF42A5F5).withOpacity(0.2)
                                : Colors.grey.shade800.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF42A5F5)
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                info['flag'] ?? '🌍',
                                style: const TextStyle(fontSize: 20),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                lang.toUpperCase(),
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.grey.shade400,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 20),

              // Modules Grid
              Expanded(
                child: _selectedLanguage == null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.school,
                              size: 64,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Select a language to begin',
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
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
            builder: (context) => VocabularyScreen(
              language: language,
              exam: exam,
            ),
          ),
        );
        break;
      case 'grammar':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GrammarScreen(
              language: language,
              exam: exam,
            ),
          ),
        );
        break;
      case 'exam':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LanguageExamScreen(
              language: language,
              exam: exam,
            ),
          ),
        );
        break;
      case 'alphabet':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AlphabetScreen(
              language: language,
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