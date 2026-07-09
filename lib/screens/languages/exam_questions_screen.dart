import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/firestore_service.dart';
import '../../services/audio_service.dart';  // ✅ Use AudioService
import '../../models/question_model.dart';

class ExamQuestionsScreen extends StatefulWidget {
  final String language;
  final String exam;
  final String level;

  const ExamQuestionsScreen({
    super.key,
    required this.language,
    required this.exam,
    required this.level,
  });

  @override
  State<ExamQuestionsScreen> createState() => _ExamQuestionsScreenState();
}

class _ExamQuestionsScreenState extends State<ExamQuestionsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  // Remove: final AudioPlayer _audioPlayer = AudioPlayer();
  List<QuestionModel> _questions = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  
  // Quiz state
  int? _selectedAnswerIndex;
  bool _showAnswer = false;
  int _currentQuestionIndex = 0;
  int _correctCount = 0;
  int _incorrectCount = 0;
  bool _isQuizMode = false;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  @override
  void dispose() {
    // Remove: _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final questions = await _firestoreService.getExamQuestionsByLevel(
        exam: widget.exam.toLowerCase(),
        level: widget.level,
      );
      
      print('✅ Loaded ${questions.length} questions for ${widget.exam} - ${widget.level}');
      
      setState(() {
        _questions = questions;
        _isLoading = false;
        _resetQuiz();
      });
    } catch (e) {
      print('❌ Error loading questions: $e');
      setState(() {
        _error = 'Failed to load questions: $e';
        _isLoading = false;
      });
    }
  }

  void _resetQuiz() {
    setState(() {
      _currentQuestionIndex = 0;
      _selectedAnswerIndex = null;
      _showAnswer = false;
      _correctCount = 0;
      _incorrectCount = 0;
      _isQuizMode = false;
    });
  }

  void _startQuiz() {
    if (_questions.isEmpty) return;
    setState(() {
      _isQuizMode = true;
      _currentQuestionIndex = 0;
      _selectedAnswerIndex = null;
      _showAnswer = false;
      _correctCount = 0;
      _incorrectCount = 0;
    });
  }

  void _selectAnswer(int index) {
    if (_showAnswer) return;
    
    setState(() {
      _selectedAnswerIndex = index;
      _showAnswer = true;
      
      final question = _questions[_currentQuestionIndex];
      if (question.correctAnswerIndex == index) {
        _correctCount++;
      } else {
        _incorrectCount++;
      }
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswerIndex = null;
        _showAnswer = false;
      });
    } else {
      _showQuizResults();
    }
  }

  void _showQuizResults() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A237E),
        title: const Text(
          '🎉 Quiz Complete!',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${_questions.length} Questions',
              style: TextStyle(color: Colors.grey.shade400),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    Text(
                      '$_correctCount',
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Correct',
                      style: TextStyle(color: Colors.green),
                    ),
                  ],
                ),
                const SizedBox(width: 32),
                Column(
                  children: [
                    Text(
                      '$_incorrectCount',
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Incorrect',
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF42A5F5).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Score: ${(_correctCount / _questions.length * 100).round()}%',
                style: const TextStyle(
                  color: Color(0xFF42A5F5),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _isQuizMode = false;
              });
            },
            child: const Text(
              'Back to List',
              style: TextStyle(color: Color(0xFF42A5F5)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _resetQuiz();
              _startQuiz();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF42A5F5),
            ),
            child: const Text('Retry Quiz'),
          ),
        ],
      ),
    );
  }

  // ✅ Updated to use AudioService
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

  void _filterQuestions(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  List<QuestionModel> get _filteredQuestions {
    if (_searchQuery.isEmpty) return _questions;
    return _questions.where((q) {
      final question = q.questionText.toLowerCase();
      final category = q.category.toLowerCase();
      final search = _searchQuery.toLowerCase();
      return question.contains(search) || category.contains(search);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredQuestions = _filteredQuestions;
    final currentQuestion = _isQuizMode && _questions.isNotEmpty
        ? _questions[_currentQuestionIndex]
        : null;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          '📖 ${widget.exam.toUpperCase()} Practice',
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
        bottom: !_isQuizMode
            ? PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextField(
                    onChanged: _filterQuestions,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: '🔍 Search questions...',
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
              )
            : null,
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
                : _questions.isEmpty
                    ? _buildEmptyWidget()
                    : _isQuizMode && currentQuestion != null
                        ? _buildQuizWidget(currentQuestion)
                        : _buildListWidget(filteredQuestions),
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
              onPressed: _loadQuestions,
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
            Icons.quiz_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'No practice questions available',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            'Add questions to the ${widget.exam}_questions collection',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListWidget(List<QuestionModel> questions) {
    return Column(
      children: [
        if (questions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _startQuiz,
                icon: const Icon(Icons.play_arrow),
                label: Text('Start Quiz (${questions.length} questions)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF42A5F5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        Expanded(
          child: questions.isEmpty
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
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: questions.length,
                  itemBuilder: (context, index) {
                    final question = questions[index];
                    return _buildQuestionCard(question);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildQuizWidget(QuestionModel question) {
    final options = question.options ?? [];
    final totalQuestions = _questions.length;
    final progress = (_currentQuestionIndex + 1) / totalQuestions;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question ${_currentQuestionIndex + 1}/$totalQuestions',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 14,
                ),
              ),
              Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '$_correctCount',
                    style: TextStyle(color: Colors.green),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.cancel, color: Colors.red, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '$_incorrectCount',
                    style: TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade800,
            color: const Color(0xFF42A5F5),
            minHeight: 4,
            borderRadius: BorderRadius.circular(2),
          ),
          const SizedBox(height: 16),
          
          // Question
          Container(
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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF42A5F5).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        question.category,
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${question.points ?? 10} pts',
                        style: TextStyle(
                          color: Colors.orange.shade300,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => _playAudio(question.questionText),
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
                const SizedBox(height: 8),
                Text(
                  question.questionText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                
                if (question.burmeseQuestion != null && question.burmeseQuestion!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    '🇲🇲 ${question.burmeseQuestion}',
                    style: GoogleFonts.notoSansMyanmar(
                      color: Colors.white70,
                      fontSize: 15,
                    ),
                  ),
                  if (question.burmeseQuestionRomanization != null && 
                      question.burmeseQuestionRomanization!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 28),
                      child: Text(
                        question.burmeseQuestionRomanization!,
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
          
          const SizedBox(height: 16),
          
          // Options
          Expanded(
            child: ListView.builder(
              itemCount: options.length,
              itemBuilder: (context, index) {
                final option = options[index];
                final isSelected = _selectedAnswerIndex == index;
                final isCorrect = question.correctAnswerIndex == index;
                final isWrong = isSelected && !isCorrect;
                
                Color? backgroundColor;
                Color? borderColor;
                
                if (_showAnswer) {
                  if (isCorrect) {
                    backgroundColor = Colors.green.withOpacity(0.2);
                    borderColor = Colors.green;
                  } else if (isWrong) {
                    backgroundColor = Colors.red.withOpacity(0.2);
                    borderColor = Colors.red;
                  }
                } else if (isSelected) {
                  backgroundColor = const Color(0xFF42A5F5).withOpacity(0.15);
                  borderColor = const Color(0xFF42A5F5);
                }
                
                return GestureDetector(
                  onTap: () => _selectAnswer(index),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: backgroundColor ?? Colors.grey.shade900.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: borderColor ?? Colors.grey.shade700.withOpacity(0.3),
                        width: borderColor != null ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? const Color(0xFF42A5F5)
                                : Colors.grey.shade700,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              String.fromCharCode(65 + index),
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.grey.shade400,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            option,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        if (_showAnswer && isCorrect)
                          const Icon(Icons.check_circle, color: Colors.green),
                        if (_showAnswer && isWrong)
                          const Icon(Icons.cancel, color: Colors.red),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Next Button
          if (_showAnswer)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _nextQuestion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF42A5F5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _currentQuestionIndex < _questions.length - 1
                      ? 'Next Question →'
                      : 'See Results 🎯',
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(QuestionModel question) {
    final options = question.options ?? [];

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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF42A5F5).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  question.category,
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${question.points ?? 10} pts',
                  style: TextStyle(
                    color: Colors.orange.shade300,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => _playAudio(question.questionText),
                icon: const Icon(
                  Icons.volume_up,
                  color: Color(0xFF42A5F5),
                  size: 18,
                ),
                constraints: const BoxConstraints(
                  minWidth: 30,
                  minHeight: 30,
                ),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            question.questionText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          
          if (question.burmeseQuestion != null && question.burmeseQuestion!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '🇲🇲 ${question.burmeseQuestion}',
              style: GoogleFonts.notoSansMyanmar(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            if (question.burmeseQuestionRomanization != null && 
                question.burmeseQuestionRomanization!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 28),
                child: Text(
                  question.burmeseQuestionRomanization!,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
          
          const SizedBox(height: 12),
          if (options.isNotEmpty)
            ...options.map((option) {
              return Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade900.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '• $option',
                  style: TextStyle(
                    color: Colors.grey.shade300,
                    fontSize: 14,
                  ),
                ),
              );
            }),
          
          if (question.correctAnswer != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.green.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Correct Answer: ${question.correctAnswer}',
                    style: TextStyle(
                      color: Colors.green.shade300,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}