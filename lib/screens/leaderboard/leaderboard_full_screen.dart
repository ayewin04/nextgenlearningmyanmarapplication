// lib/screens/leaderboard/leaderboard_full_screen.dart
import 'package:flutter/material.dart';
import '../../widgets/leaderboard_widget.dart';

class LeaderboardFullScreen extends StatelessWidget {
  const LeaderboardFullScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          '🏆 Top 10 Learners',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
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
        child: const SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              SizedBox(height: 8),
              Text(
                '🌟 Top Language Learners',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'The most dedicated learners on Wedawon',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                ),
              ),
              SizedBox(height: 16),
              LeaderboardWidget(),
              SizedBox(height: 20),
              
              // Stats info
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star, color: Color(0xFFFFD700), size: 14),
                  SizedBox(width: 4),
                  Text(
                    'XP = Experience Points',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 11,
                    ),
                  ),
                  SizedBox(width: 16),
                  Icon(Icons.local_fire_department, color: Colors.orange, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'Streak = Days in a row',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}