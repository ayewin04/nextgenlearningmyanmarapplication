import 'package:flutter/material.dart';
import 'vocabulary_screen.dart';
import 'grammar_screen.dart';
import 'exam_questions_screen.dart';

class LevelSelectionScreen extends StatefulWidget {
  final String language;
  final String exam;
  final String module; // 'vocabulary', 'grammar', 'exam_questions'
  final String moduleIcon;
  final String moduleName;

  const LevelSelectionScreen({
    super.key,
    required this.language,
    required this.exam,
    required this.module,
    required this.moduleIcon,
    required this.moduleName,
  });

  @override
  State<LevelSelectionScreen> createState() => _LevelSelectionScreenState();
}

class _LevelSelectionScreenState extends State<LevelSelectionScreen> {
  String? _selectedLevel;

  // Get levels based on exam
  List<Map<String, String>> get _levels {
    switch (widget.exam) {
      case 'IELTS':
        return [
          {'id': 'Band 6', 'name': 'Band 6', 'description': 'Competent user'},
          {'id': 'Band 7', 'name': 'Band 7', 'description': 'Good user'},
          {'id': 'Band 8', 'name': 'Band 8', 'description': 'Very good user'},
          {'id': 'Band 9', 'name': 'Band 9', 'description': 'Expert user'},
        ];
      case 'HSK':
        return [
          {'id': 'HSK 1', 'name': 'HSK 1', 'description': 'Beginner (150 words)'},
          {'id': 'HSK 2', 'name': 'HSK 2', 'description': 'Elementary (300 words)'},
          {'id': 'HSK 3', 'name': 'HSK 3', 'description': 'Intermediate (600 words)'},
          {'id': 'HSK 4', 'name': 'HSK 4', 'description': 'Upper Intermediate (1200 words)'},
          {'id': 'HSK 5', 'name': 'HSK 5', 'description': 'Advanced (2500 words)'},
          {'id': 'HSK 6', 'name': 'HSK 6', 'description': 'Proficient (5000+ words)'},
        ];
      case 'JLPT':
        return [
          {'id': 'N5', 'name': 'N5', 'description': 'Beginner (Basic Japanese)'},
          {'id': 'N4', 'name': 'N4', 'description': 'Elementary (Basic Japanese advanced)'},
          {'id': 'N3', 'name': 'N3', 'description': 'Intermediate (Intermediate Japanese)'},
          {'id': 'N2', 'name': 'N2', 'description': 'Upper Intermediate (Business Japanese)'},
          {'id': 'N1', 'name': 'N1', 'description': 'Advanced (Advanced Japanese)'},
        ];
      case 'TOPIK':
        return [
          {'id': 'TOPIK I-1', 'name': 'TOPIK I-1', 'description': 'Beginner (Level 1)'},
          {'id': 'TOPIK I-2', 'name': 'TOPIK I-2', 'description': 'Elementary (Level 2)'},
          {'id': 'TOPIK II-1', 'name': 'TOPIK II-1', 'description': 'Intermediate (Level 3)'},
          {'id': 'TOPIK II-2', 'name': 'TOPIK II-2', 'description': 'Upper Intermediate (Level 4)'},
          {'id': 'TOPIK II-3', 'name': 'TOPIK II-3', 'description': 'Advanced (Level 5)'},
          {'id': 'TOPIK II-4', 'name': 'TOPIK II-4', 'description': 'Proficient (Level 6)'},
        ];
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
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
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back Button
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${widget.moduleIcon} ${widget.moduleName}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF42A5F5).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF42A5F5).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        widget.exam,
                        style: const TextStyle(
                          color: Color(0xFF42A5F5),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Title
                const Text(
                  'Select Your Level',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose the level you want to practice',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),

                // Level Cards
                Expanded(
                  child: ListView.builder(
                    itemCount: _levels.length,
                    itemBuilder: (context, index) {
                      final level = _levels[index];
                      final isSelected = _selectedLevel == level['id'];
                      final color = _getLevelColor(index, _levels.length);

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedLevel = level['id'];
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? LinearGradient(
                                    colors: [
                                      color.withOpacity(0.3),
                                      color.withOpacity(0.1),
                                    ],
                                  )
                                : null,
                            color: isSelected
                                ? color.withOpacity(0.15)
                                : Colors.grey.shade800.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? color : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Level Badge
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [color, color.withOpacity(0.7)],
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    level['id']!,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
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
                                      level['name']!,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      level['description']!,
                                      style: TextStyle(
                                        color: Colors.grey.shade400,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Continue Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _selectedLevel != null
                        ? () {
                            _navigateToContent();
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF42A5F5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      disabledBackgroundColor: Colors.grey.shade700,
                    ),
                    child: const Text(
                      'Start Learning',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getLevelColor(int index, int total) {
    final colors = [
      const Color(0xFF4CAF50),  // Green
      const Color(0xFF8BC34A),  // Light Green
      const Color(0xFFFFC107),  // Amber
      const Color(0xFFFF9800),  // Orange
      const Color(0xFFF44336),  // Red
      const Color(0xFF9C27B0),  // Purple
    ];
    return colors[index % colors.length];
  }

  void _navigateToContent() {
    // Navigate to the appropriate content screen
    switch (widget.module) {
      case 'vocabulary':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VocabularyScreen(
              language: widget.language,
              exam: widget.exam.toLowerCase(), // Convert to lowercase for Firestore query
              level: _selectedLevel!,
            ),
          ),
        );
        break;
      case 'grammar':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GrammarScreen(
              language: widget.language,
              exam: widget.exam.toLowerCase(), // Convert to lowercase for Firestore query
              level: _selectedLevel!,
            ),
          ),
        );
        break;
      case 'exam_questions':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ExamQuestionsScreen(
              language: widget.language,
              exam: widget.exam.toLowerCase(), // Convert to lowercase for Firestore query
              level: _selectedLevel!,
            ),
          ),
        );
        break;
    }
  }
}