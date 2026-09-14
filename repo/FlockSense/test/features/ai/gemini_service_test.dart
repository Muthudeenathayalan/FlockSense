import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flock_sense/config/api_config.dart';
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
  });
}
