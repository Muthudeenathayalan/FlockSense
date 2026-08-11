/// Sanitizer for exported CSV spreadsheets to neutralize formula injection vulnerabilities.
class CsvSanitizer {
  static final RegExp _injectionTriggers = RegExp(r'^[=+\-@\t\r]');

  /// Sanitizes an individual cell string before export.
  static String sanitizeCell(dynamic value) {
    if (value == null) return '';
    final str = value.toString().trim();
    if (_injectionTriggers.hasMatch(str)) {
      return "'$str";
    }
    return str;
  }

  /// Sanitizes an entire row of cells.
  static List<String> sanitizeRow(List<dynamic> row) {
    return row.map((cell) => sanitizeCell(cell)).toList();
  }
}
