// lib/screens/daily_challenge/daily_challenge_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../services/auth_service.dart';
import '../../services/daily_challenge_service.dart';
import '../../models/daily_challenge_model.dart';

class DailyChallengeScreen extends StatefulWidget {
  final DailyChallengeModel? challenge;

  const DailyChallengeScreen({super.key, this.challenge});

  @override
  State<DailyChallengeScreen> createState() => _DailyChallengeScreenState();
}

class _DailyChallengeScreenState extends State<DailyChallengeScreen>
    with SingleTickerProviderStateMixin {
  final DailyChallengeService _service = DailyChallengeService();
  DailyChallengeModel? _challenge;
  bool _isLoading = true;
  String? _error;
  int _currentQuestionIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _loadChallenge();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadChallenge() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.userModel;

      if (user == null) {
        throw Exception('User not logged in');
      }

      String exam;
      if (widget.challenge != null) {
        exam = widget.challenge!.exam;
      } else {
        exam = user.targetLanguages.isNotEmpty 
            ? user.targetLanguages.first 
            : 'IELTS';
      }

      final challenge = await _service.generateDailyChallenge(
        userId: user.uid,
        exam: exam,
      );

      setState(() {
        _challenge = challenge;
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      setState(() {
        _error = 'Failed to load challenge: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              _challenge?.exam ?? 'Challenge',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(width: 8),
            Text(
              _getLanguageFlag(_challenge?.exam ?? ''),
              style: const TextStyle(fontSize: 20),
            ),
          ],
        ),
        backgroundColor: _getLanguageColor(_challenge?.exam ?? ''),
        foregroundColor: Colors.white,
        elevation: 0,
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
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Color(0xFF42A5F5),
            ),
            SizedBox(height: 16),
            Text(
              'Preparing your challenge...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
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
                onPressed: _loadChallenge,
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

    if (_challenge == null) {
      return const Center(
        child: Text(
          'No challenge available',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    if (_challenge!.isCompleted) {
      return _buildResults();
    }

    return _buildQuestions();
  }

  Widget _buildQuestions() {
    if (_currentQuestionIndex >= _challenge!.questions.length) {
      return _buildResults();
    }

    final question = _challenge!.questions[_currentQuestionIndex];
    final progress = (_currentQuestionIndex / _challenge!.questions.length * 100);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Question ${_currentQuestionIndex + 1}/${_challenge!.questions.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${progress.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: Color(0xFF42A5F5),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress / 100,
                  backgroundColor: Colors.grey.shade800,
                  color: const Color(0xFF42A5F5),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Language Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getLanguageColor(_challenge!.exam).withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _getLanguageColor(_challenge!.exam).withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getLanguageFlag(_challenge!.exam),
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _challenge!.exam,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      question.level,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Question
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                question.questionText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Options
            ...question.options.map((option) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                child: _buildOptionButton(option, question),
              );
            }),

            const Spacer(),

            // Question indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ...List.generate(_challenge!.questions.length, (index) {
                  final isAnswered = _challenge!.questions[index].isAnswered;
                  return Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == _currentQuestionIndex
                          ? const Color(0xFF42A5F5)
                          : isAnswered
                              ? Colors.green
                              : Colors.grey.shade600,
                    ),
                  );
                }),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionButton(String option, DailyChallengeQuestion question) {
    bool isSelected = question.selectedAnswer == option;
    bool isCorrect = option == question.correctAnswer;

    Color? buttonColor;
    Color? textColor;
    IconData? icon;

    if (question.isAnswered) {
      if (isCorrect) {
        buttonColor = Colors.green.withOpacity(0.2);
        textColor = Colors.green;
        icon = Icons.check_circle;
      } else if (isSelected && !isCorrect) {
        buttonColor = Colors.red.withOpacity(0.2);
        textColor = Colors.red;
        icon = Icons.cancel;
      } else {
        buttonColor = Colors.grey.shade800.withOpacity(0.5);
        textColor = Colors.grey;
      }
    } else {
      buttonColor = isSelected 
          ? Colors.white.withOpacity(0.1)
          : Colors.grey.shade800.withOpacity(0.3);
      textColor = Colors.white;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: buttonColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected && !question.isAnswered
              ? const Color(0xFF42A5F5)
              : isCorrect && question.isAnswered
                  ? Colors.green
                  : isSelected && question.isAnswered && !isCorrect
                      ? Colors.red
                      : Colors.transparent,
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: question.isAnswered ? null : () => _submitAnswer(option),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            child: Row(
              children: [
                if (icon != null)
                  Icon(icon, color: textColor, size: 20),
                if (icon != null) const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    option,
                    style: TextStyle(
                      color: textColor ?? Colors.grey.shade300,
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
                if (!question.isAnswered)
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected 
                            ? const Color(0xFF42A5F5)
                            : Colors.grey.shade600,
                      ),
                      color: isSelected 
                          ? const Color(0xFF42A5F5)
                          : Colors.transparent,
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            size: 12,
                            color: Colors.white,
                          )
                        : null,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitAnswer(String answer) async {
    if (_challenge == null) return;

    try {
      final updated = await _service.submitAnswer(
        challengeId: _challenge!.id,
        questionIndex: _currentQuestionIndex,
        answer: answer,
      );

      setState(() {
        _challenge = updated;
      });

      if (!updated.isCompleted) {
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            setState(() {
              _currentQuestionIndex++;
            });
            _animationController.reset();
            _animationController.forward();
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildResults() {
    final challenge = _challenge!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700).withOpacity(0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.emoji_events,
              color: Colors.white,
              size: 60,
            ),
          ),
          const SizedBox(height: 24),

          Text(
            '${challenge.completionPercentage.toStringAsFixed(0)}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${challenge.correctAnswers}/${challenge.totalQuestions} correct',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.star,
                color: Color(0xFFFFD700),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '+${challenge.xpEarned} XP earned',
                style: const TextStyle(
                  color: Color(0xFFFFD700),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.local_fire_department,
                color: Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '${challenge.languageStreak} day streak 🔥',
                style: TextStyle(
                  color: Colors.orange.shade400,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          const Divider(color: Colors.grey),
          const SizedBox(height: 24),

          const Text(
            '📊 Performance',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Score summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildResultStat('✅', '${challenge.correctAnswers}', 'Correct'),
                _buildResultStat('❌', '${challenge.totalQuestions - challenge.correctAnswers}', 'Incorrect'),
                _buildResultStat('⭐', '${challenge.xpEarned}', 'XP Earned'),
              ],
            ),
          ),

          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF42A5F5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Back to Challenges',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildResultStat(String icon, String value, String label) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  String _getLanguageFlag(String language) {
    return AppConstants.languageFlags[language] ?? '🌍';
  }

  Color _getLanguageColor(String language) {
    return AppConstants.languageColors[language] ?? Colors.grey;
  }
}