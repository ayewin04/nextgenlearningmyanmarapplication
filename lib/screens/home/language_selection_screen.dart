// lib/screens/home/language_selection_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import 'category_selection_screen.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  String? _selectedLanguage;

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

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
          child: Padding(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: 80,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choose the language you want to learn',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Select a language to start learning',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 20),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildLanguageCard(
                          context,
                          language: 'english',
                          displayName: 'English',
                          flag: '🇬🇧',
                          color: Colors.blue,
                          isSelected: _selectedLanguage == 'english',
                          onTap: () => setState(() => _selectedLanguage = 'english'),
                        ),
                        _buildLanguageCard(
                          context,
                          language: 'korean',
                          displayName: 'Korean',
                          flag: '🇰🇷',
                          color: Colors.green,
                          isSelected: _selectedLanguage == 'korean',
                          onTap: () => setState(() => _selectedLanguage = 'korean'),
                        ),
                        _buildLanguageCard(
                          context,
                          language: 'japanese',
                          displayName: 'Japanese',
                          flag: '🇯🇵',
                          color: Colors.purple,
                          isSelected: _selectedLanguage == 'japanese',
                          onTap: () => setState(() => _selectedLanguage = 'japanese'),
                        ),
                        _buildLanguageCard(
                          context,
                          language: 'chinese',
                          displayName: 'Chinese',
                          flag: '🇨🇳',
                          color: Colors.red,
                          isSelected: _selectedLanguage == 'chinese',
                          onTap: () => setState(() => _selectedLanguage = 'chinese'),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _selectedLanguage != null
                        ? () {
                            authService.updateUserProfile(
                              targetLanguages: [_selectedLanguage!],
                            );
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CategorySelectionScreen(
                                  selectedLanguage: _selectedLanguage!,
                                  languageFlag: _getLanguageFlag(_selectedLanguage!),
                                ),
                              ),
                            );
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF42A5F5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      disabledBackgroundColor: Colors.grey.shade700,
                    ),
                    child: const Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageCard(
    BuildContext context, {
    required String language,
    required String displayName,
    required String flag,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [color.withOpacity(0.3), color.withOpacity(0.1)],
                )
              : null,
          color: isSelected ? color.withOpacity(0.15) : Colors.grey.shade800.withOpacity(0.3),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 10),
            Text(
              displayName,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade300,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 12,
                ),
              ),
          ],
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