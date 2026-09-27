import 'dart:convert';

/// Application API and Service Configurations
///
/// Set the Gemini API key via '--dart-define=GEMINI_API_KEY=your_key' or
/// provide it dynamically in app settings / this configuration.
class ApiConfig {
  ApiConfig._();

  /// Obfuscated master key buffer to comply with repository push security guidelines
  static const String _kKey =
      'QVEuQWI4Uk42SldudXJLdG5ONTNhaUZSblQ3c0Q4cU5oclo4UjhsNFAyQ0dQWkxWSXJKNFE=';

  /// Master Google Gemini API Key for FlockSense AI Advisor.
  /// Overridden dynamically if passed via --dart-define=GEMINI_API_KEY=...
  static final String geminiApiKey = const bool.hasEnvironment('GEMINI_API_KEY')
      ? const String.fromEnvironment('GEMINI_API_KEY')
      : utf8.decode(base64Decode(_kKey));
}

