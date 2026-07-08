// lib/widgets/xp_progress_widget.dart
import 'package:flutter/material.dart';
import '../services/gamification_service.dart';

class XPProgressWidget extends StatelessWidget {
  final int currentXP;
  final int level;

  const XPProgressWidget({
    super.key,
    required this.currentXP,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    final xpForCurrentLevel = (level - 1) * GamificationService.XP_PER_LEVEL;
    final xpForNextLevel = level * GamificationService.XP_PER_LEVEL;
    final progress = (currentXP - xpForCurrentLevel) / 
        (xpForNextLevel - xpForCurrentLevel);
    final clampedProgress = progress.clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF42A5F5).withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.star, color: Color(0xFFFFD700), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Level $level',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Text(
                '$currentXP XP',
                style: const TextStyle(
                  color: Color(0xFFFFD700),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: clampedProgress,
            backgroundColor: Colors.grey.shade800,
            color: const Color(0xFF42A5F5),
            minHeight: 6,
            borderRadius: BorderRadius.circular(4),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$xpForCurrentLevel XP',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 9,
                ),
              ),
              Text(
                '$xpForNextLevel XP',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}