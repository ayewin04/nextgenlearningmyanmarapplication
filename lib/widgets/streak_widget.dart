// lib/widgets/streak_widget.dart
import 'package:flutter/material.dart';

class StreakWidget extends StatelessWidget {
  final int streak;
  final bool practicedToday;

  const StreakWidget({
    super.key,
    required this.streak,
    this.practicedToday = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.withOpacity(0.2),
            Colors.orange.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department, color: Colors.orange, size: 18),
          const SizedBox(width: 6),
          Text(
            '$streak',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            ' day${streak != 1 ? 's' : ''}',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 12,
            ),
          ),
          if (practicedToday) ...[
            const SizedBox(width: 6),
            const Icon(Icons.check_circle, color: Colors.green, size: 14),
          ],
        ],
      ),
    );
  }
}