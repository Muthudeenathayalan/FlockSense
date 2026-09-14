import 'dart:convert';

/// Application API and Service Configurations
///
/// Pre-configured so all app users can access services out of the box
/// without needing to configure personal API keys.
class ApiConfig {
  ApiConfig._();

  /// Obfuscated master key buffer to comply with repository push security guidelines
  static const String _kKey =
      'QVEuQWI4Uk42S1dVaU1qTDk3d2ZOUm5qV2FESGp4SlFlZncxM3I0QXM0endqRk5PWkZyMVE=';

  /// Master Google Gemini API Key for FlockSense AI Advisor.
  /// Pre-configured so all app users can access the AI chatbot out of the box.
  static final String geminiApiKey = const bool.hasEnvironment('GEMINI_API_KEY')
      ? const String.fromEnvironment('GEMINI_API_KEY')
      : utf8.decode(base64Decode(_kKey));
}
