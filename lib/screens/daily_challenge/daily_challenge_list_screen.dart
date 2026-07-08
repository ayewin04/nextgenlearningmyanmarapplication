// lib/screens/daily_challenge/daily_challenge_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../services/auth_service.dart';
import '../../services/daily_challenge_service.dart';
import '../../models/daily_challenge_model.dart';
import 'daily_challenge_screen.dart';

class DailyChallengeListScreen extends StatefulWidget {
  const DailyChallengeListScreen({super.key});

  @override
  State<DailyChallengeListScreen> createState() => _DailyChallengeListScreenState();
}

class _DailyChallengeListScreenState extends State<DailyChallengeListScreen> {
  final DailyChallengeService _service = DailyChallengeService();
  List<DailyChallengeModel> _challenges = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadChallenges();
  }

  Future<void> _loadChallenges() async {
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

      final languages = user.targetLanguages.isNotEmpty 
          ? user.targetLanguages 
          : ['IELTS'];

      final challenges = await _service.getAllDailyChallenges(
        userId: user.uid,
        languages: languages,
      );

      setState(() {
        _challenges = challenges;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load challenges: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Challenges'),
        backgroundColor: const Color(0xFF0D47A1),
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
        child: CircularProgressIndicator(
          color: Color(0xFF42A5F5),
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
              Text(_error!, style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadChallenges,
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

    if (_challenges.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'No languages selected. Go to Profile to add languages.',
            style: TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadChallenges,
      color: const Color(0xFF42A5F5),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _challenges.length,
        itemBuilder: (context, index) {
          final challenge = _challenges[index];
          return _buildChallengeCard(challenge);
        },
      ),
    );
  }

  Widget _buildChallengeCard(DailyChallengeModel challenge) {
    final isCompleted = challenge.isCompleted;
    final isStarted = challenge.answeredQuestions > 0;
    final flag = _getLanguageFlag(challenge.exam);
    final color = _getLanguageColor(challenge.exam);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isCompleted
              ? [Colors.green.shade900, Colors.green.shade700]
              : [color.withOpacity(0.3), color.withOpacity(0.1)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCompleted ? Colors.green : color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(flag, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      challenge.exam,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${challenge.totalQuestions} questions',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (isCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '✅ Done',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Progress
          if (isStarted && !isCompleted)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progress',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '${challenge.answeredQuestions}/${challenge.totalQuestions}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: challenge.answeredQuestions / challenge.totalQuestions,
                  backgroundColor: Colors.grey.shade800,
                  color: const Color(0xFF42A5F5),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),

          // Results if completed
          if (isCompleted)
            Row(
              children: [
                const Icon(
                  Icons.star,
                  color: Color(0xFFFFD700),
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '+${challenge.xpEarned} XP',
                  style: const TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(
                  Icons.local_fire_department,
                  color: Colors.orange,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '${challenge.languageStreak} day streak',
                  style: TextStyle(
                    color: Colors.orange.shade400,
                    fontSize: 14,
                  ),
                ),
              ],
            ),

          const SizedBox(height: 12),

          // Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (isCompleted) {
                  // Show results
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DailyChallengeScreen(
                        challenge: challenge,
                      ),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isCompleted ? Colors.grey.shade700 : const Color(0xFF42A5F5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                isCompleted 
                    ? 'Completed! 🎉' 
                    : isStarted 
                        ? 'Continue' 
                        : 'Start Challenge',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getLanguageFlag(String language) {
    return AppConstants.languageFlags[language] ?? '🌍';
  }

  Color _getLanguageColor(String language) {
    return AppConstants.languageColors[language] ?? Colors.grey;
  }
}