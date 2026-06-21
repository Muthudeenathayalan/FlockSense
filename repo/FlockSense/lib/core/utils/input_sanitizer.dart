/// Input sanitization utilities for FlockSense
///
/// Provides functions to sanitize and validate user inputs before storing in Firestore

import 'package:flutter/foundation.dart';

class InputSanitizer {
  /// Sanitizes string input by removing dangerous characters and trimming whitespace
  static String sanitizeString(
    String input, {
    bool allowSpecialChars = false,
    bool allowNumbers = true,
    int maxLength = 200,
  }) {
    if (input.isEmpty) return '';

    String sanitized = input.trim();

    // Remove HTML/script tags
    sanitized = sanitized.replaceAll(RegExp(r'<[^>]*>'), '');

    // Remove SQL injection patterns
    sanitized = sanitized.replaceAll(RegExp('[;\'"\\\\]'), '');

    // If special characters not allowed, remove them
    if (!allowSpecialChars) {
      // Keep letters, numbers, spaces, hyphens, dots, underscores
      sanitized = sanitized.replaceAll(RegExp(r'[^\w\s\-\.]'), '');
    }

    // Truncate to max length
    if (sanitized.length > maxLength) {
      sanitized = sanitized.substring(0, maxLength);
    }

    debugPrint('[InputSanitizer] Sanitized "$input" to "$sanitized"');
    return sanitized;
  }

  /// Sanitizes email address
  static String sanitizeEmail(String email) {
    final trimmed = email.trim().toLowerCase();

    // Basic email validation
    if (!_isValidEmail(trimmed)) {
      debugPrint('[InputSanitizer] Invalid email: $email');
      return '';
    }

    return trimmed;
  }

  /// Sanitizes integer input
  static int sanitizeInteger(
    String input, {
    int defaultValue = 0,
    int maxValue = 999999,
  }) {
    final trimmed = input.trim();

    try {
      final value = int.parse(trimmed);

      if (value < 0) {
        debugPrint(
          '[InputSanitizer] Integer value is negative: $value, using default',
        );
        return defaultValue;
      }

      if (value > maxValue) {
        debugPrint(
          '[InputSanitizer] Integer value exceeds max: $value > $maxValue',
        );
        return maxValue;
      }

      return value;
    } catch (e) {
      debugPrint(
        '[InputSanitizer] Failed to parse integer: $input, using default',
      );
      return defaultValue;
    }
  }

  /// Sanitizes double/decimal input
  static double sanitizeDouble(
    String input, {
    double defaultValue = 0.0,
    double maxValue = 999999.99,
  }) {
    final trimmed = input.trim();

    try {
      final value = double.parse(trimmed);

      if (value < 0) {
        debugPrint(
          '[InputSanitizer] Double value is negative: $value, using default',
        );
        return defaultValue;
      }

      if (value > maxValue) {
        debugPrint(
          '[InputSanitizer] Double value exceeds max: $value > $maxValue',
        );
        return maxValue;
      }

      return double.parse(
        value.toStringAsFixed(2),
      ); // Round to 2 decimal places
    } catch (e) {
      debugPrint(
        '[InputSanitizer] Failed to parse double: $input, using default',
      );
      return defaultValue;
    }
  }

  /// Validates farm name
  static bool isValidFarmName(String name) {
    final sanitized = name.trim();
    return sanitized.isNotEmpty &&
        sanitized.length >= 2 &&
        sanitized.length <= 100;
  }

  /// Validates address
  static bool isValidAddress(String address) {
    final sanitized = address.trim();
    return sanitized.isNotEmpty &&
        sanitized.length >= 5 &&
        sanitized.length <= 200;
  }

  /// Validates bird capacity
  static bool isValidBirdCapacity(String capacity) {
    try {
      final value = int.parse(capacity.trim());
      return value > 0 && value <= 1000000;
    } catch (_) {
      return false;
    }
  }

  /// Validates notes/description
  static String sanitizeNotes(String notes, {int maxLength = 1000}) {
    return sanitizeString(notes, allowSpecialChars: true, maxLength: maxLength);
  }

  /// Email validation regex
  static bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// Sanitize all farm data
  static Map<String, dynamic> sanitizeFarmData({
    required String farmName,
    required String farmType,
    required String flockType,
    required String address,
    required String birdCapacity,
    String? district,
    String? state,
    String? lengthFt,
    String? widthFt,
    String? notes,
  }) {
    return {
      'farmName': sanitizeString(farmName, maxLength: 100),
      'farmType': sanitizeString(farmType, maxLength: 50),
      'flockType': sanitizeString(flockType, maxLength: 50),
      'address': sanitizeString(
        address,
        allowSpecialChars: true,
        maxLength: 200,
      ),
      'birdCapacity': sanitizeInteger(birdCapacity, maxValue: 1000000),
      'district': district?.isNotEmpty == true
          ? sanitizeString(district!, maxLength: 50)
          : null,
      'state': state?.isNotEmpty == true
          ? sanitizeString(state!, maxLength: 50)
          : null,
      'lengthFt': lengthFt?.isNotEmpty == true
          ? sanitizeDouble(lengthFt!, maxValue: 9999.99)
          : null,
      'widthFt': widthFt?.isNotEmpty == true
          ? sanitizeDouble(widthFt!, maxValue: 9999.99)
          : null,
      'notes': notes?.isNotEmpty == true ? sanitizeNotes(notes!) : null,
    };
  }
}
