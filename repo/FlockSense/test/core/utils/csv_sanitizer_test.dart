import 'package:flutter_test/flutter_test.dart';
import 'package:flock_sense/core/utils/csv_sanitizer.dart';

void main() {
  group('CsvSanitizer Tests', () {
    test('neutralizes formula injection characters', () {
      expect(CsvSanitizer.sanitizeCell('=cmd|/c calc'), "'+cmd|/c calc".replaceFirst('+', '='));
      expect(CsvSanitizer.sanitizeCell('+123'), "'+123");
      expect(CsvSanitizer.sanitizeCell('-50.5'), "'-50.5");
      expect(CsvSanitizer.sanitizeCell('@test'), "'@test");
    });

    test('preserves clean values unaltered', () {
      expect(CsvSanitizer.sanitizeCell('Shed 1'), 'Shed 1');
      expect(CsvSanitizer.sanitizeCell(500), '500');
      expect(CsvSanitizer.sanitizeCell(null), '');
    });

    test('sanitizes complete rows correctly', () {
      final row = ['Flock A', '=SUM(B1:B5)', 1200, '-5'];
      final sanitized = CsvSanitizer.sanitizeRow(row);
      expect(sanitized, ['Flock A', "'=SUM(B1:B5)", '1200', "'-5"]);
    });
  });
}
