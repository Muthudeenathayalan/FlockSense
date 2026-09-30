import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color background = Color(0xFFF4F7F2);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSoft = Color(0xFFEAF3E8);
  static const Color primary = Color(0xFF2E7D32);
  static const Color primaryDark = Color(0xFF173D24);
  static const Color primaryLight = Color(0xFFDDF0DD);
  static const Color textPrimary = Color(0xFF17231B);
  static const Color textSecondary = Color(0xFF647067);
  static const Color border = Color(0xFFDCE5DC);
  static const Color warning = Color(0xFFE49B25);
  static const Color danger = Color(0xFFD9534F);
  static const Color dangerLight = Color(0xFFFDECEA);

  static const Color onPrimary = Colors.white;
  static const Color surfaceVariant = surfaceSoft;
  static const Color cardBg = surface;
  static const Color textHint = textSecondary;
  static const Color divider = border;
  static const Color shadow = Color(0x1A173D24);
  static const Color shadowMd = Color(0x2A173D24);
  static const Color success = primary;
  static const Color error = danger;
  static const Color accent = warning;
  static const Color accentLight = Color(0xFFF8E1B9);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [surface, surfaceSoft],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [warning, Color(0xFFF2C46B)],
  );

  static const Color emerald = Color(0xFF2E7D32);
  static const Color gold = Color(0xFFF2C46B);

  static const LinearGradient emeraldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [emerald, Color(0xFF1B5E20)],
  );

  static const LinearGradient dangerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [danger, Color(0xFFB92D29)],
  );
}
