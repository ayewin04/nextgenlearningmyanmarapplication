import 'package:flutter_tts/flutter_tts.dart';

class AudioService {
  static final FlutterTts _tts = FlutterTts();
  static bool _isInitialized = false;
  static String? _currentLanguage;

  static Future<void> initialize() async {
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.5);
      await _tts.setPitch(1.0);
      _isInitialized = true;
      print('✅ AudioService initialized');
    } catch (e) {
      print('❌ AudioService initialization failed: $e');
    }
  }

  static Future<void> speak(String text, {String language = 'en-US'}) async {
    if (text.isEmpty) {
      print('⚠️ Empty text provided');
      return;
    }

    try {
      await stop();
      
      if (!_isInitialized) {
        await initialize();
      }
      
      // Get the correct language code
      final languageCode = getLanguageCode(language);
      
      // Set language - THIS IS KEY FOR ACCENT
      if (_currentLanguage != languageCode) {
        await _tts.setLanguage(languageCode);
        _currentLanguage = languageCode;
        print('✅ Language set to: $languageCode');
      }
      
      // Set rate (slower for better clarity)
      await _tts.setSpeechRate(0.5);
      
      // Set pitch
      await _tts.setPitch(1.0);
      
      // Speak the text
      await _tts.speak(text);
      print('✅ Speaking: $text in $languageCode');
    } catch (e) {
      print('❌ Speech error: $e');
      rethrow;
    }
  }

  static Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (e) {
      print('❌ Stop error: $e');
    }
  }

  static Future<void> dispose() async {
    try {
      await stop();
      await _tts.stop();
      _isInitialized = false;
    } catch (e) {
      print('❌ Dispose error: $e');
    }
  }

  static Future<void> setLanguage(String languageCode) async {
    try {
      await _tts.setLanguage(languageCode);
      _currentLanguage = languageCode;
    } catch (e) {
      print('❌ Set language error: $e');
    }
  }

  static Future<void> setRate(double rate) async {
    try {
      await _tts.setSpeechRate(rate);
    } catch (e) {
      print('❌ Set rate error: $e');
    }
  }

  static Future<void> setPitch(double pitch) async {
    try {
      await _tts.setPitch(pitch);
    } catch (e) {
      print('❌ Set pitch error: $e');
    }
  }

  // ✅ CORRECT LANGUAGE CODES FOR NATIVE ACCENTS
  static String getLanguageCode(String language) {
    const langMap = {
      'english': 'en-US',
      'korean': 'ko-KR',    // Korean - native accent
      'japanese': 'ja-JP',   // Japanese - native accent
      'chinese': 'zh-CN',    // Chinese - native accent
    };
    return langMap[language] ?? 'en-US';
  }

  // ✅ Get available voices (for debugging)
  static Future<List<dynamic>?> getVoices() async {
    try {
      return await _tts.getVoices;
    } catch (e) {
      print('❌ Get voices error: $e');
      return null;
    }
  }

  // ✅ Check if language is supported
  static Future<bool> isLanguageSupported(String language) async {
    try {
      final voices = await getVoices();
      if (voices == null) return false;
      
      final languageCode = getLanguageCode(language);
      return voices.any((voice) {
        final locale = voice['locale'] ?? '';
        return locale.contains(languageCode.split('-')[0]);
      });
    } catch (e) {
      return false;
    }
  }
}