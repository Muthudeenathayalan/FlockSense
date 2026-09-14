import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flock_sense/config/api_config.dart';
import 'package:flock_sense/features/ai/data/models/ai_message_model.dart';
import 'package:flock_sense/features/ai/data/services/gemini_service.dart';

class _AllowRealHttpOverrides extends HttpOverrides {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _AllowRealHttpOverrides();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('GeminiService Tests', () {
    test('ApiConfig has pre-configured Gemini API key', () {
      expect(ApiConfig.geminiApiKey.isNotEmpty, isTrue);
      expect(ApiConfig.geminiApiKey.startsWith('AQ.'), isTrue);
    });

    test('getStoredApiKey returns pre-configured key when no custom override', () async {
      final key = await GeminiService.getStoredApiKey();
      expect(key, equals(ApiConfig.geminiApiKey));
    });

    test('Live connection test with configured key', () async {
      final isValid = await GeminiService.testApiKey();
      // Verifies the live Google Generative Language API endpoint responds with HTTP 200
      expect(isValid, isTrue);
    });

    test('Chatbot response generation with live Gemini 3.6 Flash', () async {
      final response = await GeminiService.generateResponse(
        prompt: 'Say "FlockSense AI is ready!" in exactly those words.',
        contextSnapshot: 'System: You are FlockSense AI Advisor.',
      );

      expect(response.isNotEmpty, isTrue);
      expect(response.toLowerCase().contains('flocksense'), isTrue);
    });

    test('Chatbot multi-turn conversational memory remembers prior turns', () async {
      final history = [
        AiMessageModel(
          id: '1',
          conversationId: 'c1',
          sender: AiMessageSender.user,
          content: 'My flock is Cobb 500 placed in Shed 2.',
          timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
        ),
        AiMessageModel(
          id: '2',
          conversationId: 'c1',
          sender: AiMessageSender.ai,
          content: 'Understood. Cobb 500 in Shed 2 has excellent feed conversion potential.',
          timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
        ),
      ];

      final response = await GeminiService.generateResponse(
        prompt: 'Which breed and shed did I mention earlier? Answer in one short sentence.',
        contextSnapshot: 'System: You are FlockSense AI Advisor.',
        conversationHistory: history,
      );

      expect(response.isNotEmpty, isTrue);
      expect(response.toLowerCase().contains('cobb'), isTrue);
      expect(response.toLowerCase().contains('2') || response.toLowerCase().contains('two'), isTrue);
    });
  });
}
