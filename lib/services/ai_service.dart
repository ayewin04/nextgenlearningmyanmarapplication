import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/constants.dart';

class AIService {
  final String _apiKey;
  
  AIService({String? apiKey}) : _apiKey = apiKey ?? ''; // Load from env

  // Generate explanation for a question
  Future<String> getExplanation({
    required String question,
    required String? correctAnswer,
    required String? userAnswer,
    required String exam,
    required String level,
  }) async {
    try {
      final prompt = '''
        You are an expert ${exam} tutor. 
        Question: $question
        Correct Answer: $correctAnswer
        User's Answer: $userAnswer
        Level: $level
        
        Please provide:
        1. Why the correct answer is correct
        2. Why the user's answer is wrong (if it is)
        3. Key concepts to understand
        4. A tip for similar questions
        Keep it concise and encouraging.
      ''';

      final response = await _callOpenAI(prompt);
      return response;
    } catch (e) {
      throw Exception('Failed to get explanation: $e');
    }
  }

  // Grade writing essay
  Future<Map<String, dynamic>> gradeWriting({
    required String essay,
    required String exam,
    required String level,
    required String prompt,
  }) async {
    try {
      final systemPrompt = '''
        You are an official ${exam} examiner. Grade this essay based on:
        1. Task Achievement
        2. Coherence and Cohesion
        3. Lexical Resource
        4. Grammatical Range and Accuracy
        
        Provide a score (0-9 for IELTS, 0-100 for others) and detailed feedback.
        Return response as JSON: {"score": 6.5, "feedback": "...", "strengths": [...], "improvements": [...]}
      ''';

      final userPrompt = '''
        Exam: $exam
        Level: $level
        Prompt: $prompt
        Essay: $essay
      ''';

      final response = await _callOpenAI(userPrompt, systemPrompt: systemPrompt);
      return jsonDecode(response);
    } catch (e) {
      throw Exception('Failed to grade writing: $e');
    }
  }

  // Analyze speaking response
  Future<Map<String, dynamic>> analyzeSpeaking({
    required String transcript,
    required String exam,
    required String level,
    required String prompt,
  }) async {
    try {
      final systemPrompt = '''
        You are an ${exam} speaking examiner. Analyze this speaking response:
        1. Fluency and Coherence
        2. Lexical Resource
        3. Grammatical Range
        4. Pronunciation (based on transcript)
        
        Provide score and feedback as JSON.
      ''';

      final userPrompt = '''
        Exam: $exam
        Level: $level
        Prompt: $prompt
        Response: $transcript
      ''';

      final response = await _callOpenAI(userPrompt, systemPrompt: systemPrompt);
      return jsonDecode(response);
    } catch (e) {
      throw Exception('Failed to analyze speaking: $e');
    }
  }

  // Generate practice questions
  Future<List<Map<String, dynamic>>> generateQuestions({
    required String exam,
    required String level,
    required String category,
    int count = 5,
  }) async {
    try {
      final prompt = '''
        Generate $count ${exam} practice questions at $level level for $category.
        Format as JSON array with fields: questionText, options (if MCQ), correctAnswer, explanation.
        Make them realistic and exam-appropriate.
      ''';

      final response = await _callOpenAI(prompt);
      return List<Map<String, dynamic>>.from(jsonDecode(response));
    } catch (e) {
      throw Exception('Failed to generate questions: $e');
    }
  }

  // Vocabulary suggestion
  Future<List<Map<String, dynamic>>> getVocabularySuggestions({
    required String exam,
    required String level,
    required String context,
    int count = 10,
  }) async {
    try {
      final prompt = '''
        Suggest $count important vocabulary words for ${exam} at $level level.
        Context: $context
        Return as JSON: [{"word": "", "meaning": "", "example": "", "pronunciation": ""}]
      ''';

      final response = await _callOpenAI(prompt);
      return List<Map<String, dynamic>>.from(jsonDecode(response));
    } catch (e) {
      throw Exception('Failed to get vocabulary: $e');
    }
  }

  // Private: Call OpenAI API
  Future<String> _callOpenAI(String prompt, {String? systemPrompt}) async {
    if (_apiKey.isEmpty) {
      throw Exception('OpenAI API key not set');
    }

    try {
      final response = await http.post(
        Uri.parse(AppConstants.openAIEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4',
          'messages': [
            if (systemPrompt != null)
              {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': prompt},
          ],
          'temperature': 0.7,
          'max_tokens': 2000,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        throw Exception('OpenAI API error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to call OpenAI: $e');
    }
  }
}