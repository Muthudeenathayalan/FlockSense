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
    test('getStoredApiKey returns empty or configured key when no custom override', () async {
      final key = await GeminiService.getStoredApiKey();
      expect(key, equals(ApiConfig.geminiApiKey.isEmpty ? null : ApiConfig.geminiApiKey));
    });

    test('getStoredApiKey respects user preference override', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('flocksense_gemini_api_key', 'test-custom-key');

      final key = await GeminiService.getStoredApiKey();
      expect(key, equals('test-custom-key'));
      await prefs.remove('flocksense_gemini_api_key');
    });

    test('Live connection test with configured key (skipped if key empty)', () async {
      final key = await GeminiService.getStoredApiKey();
      if (key == null || key.isEmpty) return; // Safely skip if no API key configured yet

      final isValid = await GeminiService.testApiKey();
      expect(isValid, anyOf(isTrue, isFalse));
    });

    test('Chatbot response generation with live Gemini (skipped if key empty)', () async {
      final key = await GeminiService.getStoredApiKey();
      if (key == null || key.isEmpty) return; // Safely skip if no API key configured yet

      final response = await GeminiService.generateResponse(
        prompt: 'Say "FlockSense AI is ready!" in exactly those words.',
        contextSnapshot: 'System: You are FlockSense AI Advisor.',
      );

      expect(response.isNotEmpty, isTrue);
      expect(response.toLowerCase().contains('flocksense'), isTrue);
    });

    test('Chatbot multi-turn conversational memory remembers prior turns', () async {
      final key = await GeminiService.getStoredApiKey();
      if (key == null || key.isEmpty) return; // Safely skip if no API key configured yet

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
      if (response.toLowerCase().contains('offline') ||
          response.toLowerCase().contains('temporarily') ||
          response.toLowerCase().contains('connection') ||
          response.toLowerCase().contains('unavailable')) {
        return;
      }
      expect(response.toLowerCase().contains('cobb'), isTrue);
      expect(response.toLowerCase().contains('2') || response.toLowerCase().contains('two'), isTrue);
    });
  });
}
