import 'package:flutter_test/flutter_test.dart';
import 'package:flock_sense/core/utils/input_sanitizer.dart';

void main() {
  group('InputSanitizer Tests', () {
    test('strips HTML and script tags from input strings', () {
      const malicious = '<script>alert("hack")</script>Shed North';
      final clean = InputSanitizer.sanitizeString(malicious);
      expect(clean, contains('Shed North'));
      expect(clean, isNot(contains('<script>')));
    });

    test('sanitizes integers with bounds and defaults', () {
      expect(InputSanitizer.sanitizeInteger('5000'), 5000);
      expect(InputSanitizer.sanitizeInteger('-10', defaultValue: 0), 0);
      expect(InputSanitizer.sanitizeInteger('not-a-number', defaultValue: 100), 100);
    });

    test('sanitizes doubles with decimal precision', () {
      expect(InputSanitizer.sanitizeDouble('24.567'), 24.57);
      expect(InputSanitizer.sanitizeDouble('-5.0', defaultValue: 0.0), 0.0);
    });

    test('validates farm name and capacity boundaries', () {
      expect(InputSanitizer.isValidFarmName('Green Valley Farm'), isTrue);
      expect(InputSanitizer.isValidFarmName('A'), isFalse);
      expect(InputSanitizer.isValidBirdCapacity('15000'), isTrue);
      expect(InputSanitizer.isValidBirdCapacity('-500'), isFalse);
    });
  });
}
