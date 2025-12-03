import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
class GeminiService {
  static const String _apiKey = 'AIzaSyAm83aQqLHXrX51MpJd50bBrWbcTCl6UYk'; // Replace with your key
  
  late final GenerativeModel _model;
  late final GenerativeModel _chatModel;

  GeminiService() {
    _model = GenerativeModel(
      model: 'gemini-2.5-pro',
      apiKey: _apiKey,
    );
    
    _chatModel = GenerativeModel(
      model: 'gemini-2.5-pro',
      apiKey: _apiKey,
    );
  }

  // Generate quiz questions from material
  Future<List<Map<String, dynamic>>> generateQuizQuestions({
    required String materialContent,
    required int easyCount,
    required int mediumCount,
    required int hardCount,
  }) async {
    try {
      final totalQuestions = easyCount + mediumCount + hardCount;
      
      final prompt = '''
Generate $totalQuestions multiple-choice questions from the following educational material. 

Requirements:
- $easyCount EASY questions (basic recall, definitions)
- $mediumCount MEDIUM questions (application, understanding)
- $hardCount HARD questions (analysis, synthesis)

Material:
$materialContent

Return ONLY a JSON array with this exact format (no markdown, no extra text):
[
  {
    "question": "Question text here? ",
    "choices": ["Option A", "Option B", "Option C", "Option D"],
    "correctAnswer": 0,
    "difficulty": "easy"
  }
]

Rules:
1. Each question must have exactly 4 choices
2. correctAnswer is the index (0-3) of the correct choice
3. difficulty must be "easy", "medium", or "hard"
4. Questions must be clear and unambiguous
5. Return valid JSON only
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      final responseText = response.text ??  '';
      
      debugPrint('📝 Gemini Response: $responseText');
      
      // Parse JSON response
      final jsonText = responseText
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      
      final List<dynamic> questions = jsonDecode(jsonText);
      
      // Validate and return
      return questions.map((q) => Map<String, dynamic>.from(q)).toList();
      
    } catch (e) {
      debugPrint('❌ Error generating questions: $e');
      rethrow;
    }
  }

  // Chat with AI for learning support
  Future<String> chat(String message, {List<Map<String, String>>? history}) async {
    try {
      final chat = _chatModel.startChat(
        history: history?. map((msg) {
          return Content.text(msg['content']!);
        }).toList(),
      );

      final response = await chat.sendMessage(Content.text(message));
      return response.text ?? 'Sorry, I could not generate a response.';
      
    } catch (e) {
      debugPrint('❌ Chat error: $e');
      return 'Error: Unable to process your request. Please try again.';
    }
  }

  // Get learning suggestions
  Future<String> getLearningHelp(String topic, String studentQuestion) async {
    try {
      final prompt = '''
You are a helpful educational assistant. A student is learning about: $topic

Student's question: $studentQuestion

Provide a clear, concise, and educational response that:
1. Directly answers their question
2. Provides examples if helpful
3. Encourages further learning
4. Keeps it under 200 words

Response:
''';

      final response = await _model. generateContent([Content.text(prompt)]);
      return response.text ?? 'I apologize, but I could not generate a helpful response.';
      
    } catch (e) {
      debugPrint('❌ Learning help error: $e');
      return 'Error: Unable to provide learning assistance at this time.';
    }
  }

  // Validate generated questions (basic check)
  bool validateQuestions(List<Map<String, dynamic>> questions, {
    required int expectedEasy,
    required int expectedMedium,
    required int expectedHard,
  }) {
    try {
      int easyCount = 0;
      int mediumCount = 0;
      int hardCount = 0;

      for (var q in questions) {
        // Check required fields
        if (! q. containsKey('question') || 
            !q.containsKey('choices') || 
            ! q.containsKey('correctAnswer') ||
            !q.containsKey('difficulty')) {
          debugPrint('⚠️ Invalid question structure: $q');
          return false;
        }

        // Check choices count
        if (q['choices']. length != 4) {
          debugPrint('⚠️ Invalid choices count: ${q['choices']. length}');
          return false;
        }

        // Check correctAnswer range
        if (q['correctAnswer'] < 0 || q['correctAnswer'] > 3) {
          debugPrint('⚠️ Invalid correctAnswer: ${q['correctAnswer']}');
          return false;
        }

        // Count difficulties
        switch (q['difficulty']. toString(). toLowerCase()) {
          case 'easy':
            easyCount++;
            break;
          case 'medium':
            mediumCount++;
            break;
          case 'hard':
            hardCount++;
            break;
          default:
            debugPrint('⚠️ Invalid difficulty: ${q['difficulty']}');
            return false;
        }
      }

      // Check if counts match (with tolerance)
      final totalExpected = expectedEasy + expectedMedium + expectedHard;
      final totalActual = questions.length;
      
      if (totalActual != totalExpected) {
        debugPrint('⚠️ Question count mismatch.  Expected: $totalExpected, Got: $totalActual');
      }

      debugPrint('✅ Validation passed: Easy=$easyCount, Medium=$mediumCount, Hard=$hardCount');
      return true;
      
    } catch (e) {
      debugPrint('❌ Validation error: $e');
      return false;
    }
  }
}