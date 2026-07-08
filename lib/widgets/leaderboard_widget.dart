// lib/widgets/leaderboard_widget.dart
import 'package:flutter/material.dart';
import '../services/gamification_service.dart';

class LeaderboardWidget extends StatefulWidget {
  const LeaderboardWidget({super.key});

  @override
  State<LeaderboardWidget> createState() => _LeaderboardWidgetState();
}

class _LeaderboardWidgetState extends State<LeaderboardWidget> {
  final GamificationService _gamificationService = GamificationService();
  List<Map<String, dynamic>> _leaderboard = [];
  bool _isLoading = true;
  String _selectedPeriod = 'all';

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() => _isLoading = true);
    try {
      final data = await _gamificationService.getLeaderboard(
        limit: 20,
        period: _selectedPeriod,
      );
      setState(() {
        _leaderboard = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: const Color(0xFF1A237E),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '🏆 Leaderboard',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    _buildPeriodButton('All', 'all'),
                    const SizedBox(width: 8),
                    _buildPeriodButton('Weekly', 'weekly'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_leaderboard.isEmpty)
              const Center(
                child: Text(
                  'No users on leaderboard yet',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ..._leaderboard.map((user) => _buildLeaderboardItem(user)),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodButton(String label, String period) {
    final isSelected = _selectedPeriod == period;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPeriod = period;
          _loadLeaderboard();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF42A5F5)
              : Colors.grey.shade800,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade400,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildLeaderboardItem(Map<String, dynamic> user) {
    final isTop3 = user['rank'] <= 3;
    
    // ✅ FIXED: Use Colors.amber for gold, Colors.grey.shade400 for silver
    final rankColor = user['rank'] == 1 
        ? Colors.amber  // Gold
        : user['rank'] == 2 
            ? Colors.grey.shade400  // Silver
            : user['rank'] == 3 
                ? Colors.brown  // Bronze
                : Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isTop3 
            ? Colors.grey.shade800.withOpacity(0.3) 
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isTop3 
            ? Border.all(color: rankColor.withOpacity(0.3))
            : null,
      ),
      child: Row(
        children: [
          // Rank
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: rankColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${user['rank']}',
                style: TextStyle(
                  color: rankColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Avatar
          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              color: const Color(0xFF42A5F5).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                user['name'][0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Name and XP
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['name'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      '⭐ ${user['totalXP']} XP',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '📚 Level ${user['level']}',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '🔥 ${user['streak']} days',
                      style: TextStyle(
                        color: Colors.orange.shade300,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Top 3 Badge
          if (isTop3)
            Text(
              user['rank'] == 1 ? '👑' : user['rank'] == 2 ? '🥈' : '🥉',
              style: const TextStyle(fontSize: 24),
            ),
        ],
      ),
    );
  }
}