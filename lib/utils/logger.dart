import 'package:flutter/foundation.dart';

class Logger {
  static void log(String message, {String tag = 'APP'}) {
    if (!kReleaseMode) {
      // Only print in debug/profile mode
      debugPrint('[$tag] $message');
    }
    // In release mode, this does nothing
  }

  static void error(String message, dynamic error, {String tag = 'APP'}) {
    if (!kReleaseMode) {
      debugPrint('[$tag] ERROR: $message');
      debugPrint('[$tag] Details: $error');
    }
    // In production, send this to Firebase Crashlytics instead
  }

  static void warn(String message, {String tag = 'APP'}) {
    if (!kReleaseMode) {
      debugPrint('[$tag] WARNING: $message');
    }
  }
}