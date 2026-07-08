import 'package:intl/intl.dart';

class Helpers {
  // Format date
  static String formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }

  static String formatDateTime(DateTime date) {
    return DateFormat('MMM d, yyyy HH:mm').format(date);
  }

  static String formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} years ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else if (difference.inDays > 7) {
      return '${(difference.inDays / 7).floor()} weeks ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  // Truncate text
  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) {
      return text;
    }
    return '${text.substring(0, maxLength)}...';
  }

  // Get initials
  static String getInitials(String name) {
    if (name.isEmpty) return '?';
    
    final parts = name.trim().split(' ');
    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    }
    
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  // Random color generator
  static Color getRandomColor() {
    final List<Color> colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.pink,
      Colors.teal,
      Colors.cyan,
    ];
    return colors[DateTime.now().millisecondsSinceEpoch % colors.length];
  }

  // Spaced repetition algorithm (SM-2)
  static Map<String, dynamic> calculateNextReview({
    required int quality,
    required int repetitions,
    required int interval,
    required double easeFactor,
  }) {
    // quality: 0-5 (0 = forgot, 5 = perfect)
    if (quality < 3) {
      return {
        'repetitions': 0,
        'interval': 1,
        'easeFactor': easeFactor,
      };
    }

    int newRepetitions = repetitions + 1;
    int newInterval;
    double newEaseFactor = easeFactor + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));

    if (newEaseFactor < 1.3) {
      newEaseFactor = 1.3;
    }

    if (newRepetitions == 1) {
      newInterval = 1;
    } else if (newRepetitions == 2) {
      newInterval = 6;
    } else {
      newInterval = (interval * newEaseFactor).round();
    }

    if (newInterval > 365) {
      newInterval = 365;
    }

    return {
      'repetitions': newRepetitions,
      'interval': newInterval,
      'easeFactor': newEaseFactor,
    };
  }

  // Calculate XP for level
  static int getXPForLevel(int level) {
    if (level <= 1) return 0;
    // Level 1: 0 XP, Level 2: 100 XP, Level 3: 300 XP, etc.
    return level * (level - 1) * 50;
  }

  // Shuffle list
  static List<T> shuffleList<T>(List<T> list) {
    final shuffled = List<T>.from(list);
    shuffled.shuffle();
    return shuffled;
  }

  // Validate URL
  static bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && uri.hasAuthority;
    } catch (e) {
      return false;
    }
  }
}