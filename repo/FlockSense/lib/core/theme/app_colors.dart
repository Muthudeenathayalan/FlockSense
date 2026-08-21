import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Core Brand Palette ──────────────────────────────────────────────────
  static const Color background = Color(0xFFF4F7F2);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSoft = Color(0xFFEAF3E8);
  static const Color primary = Color(0xFF2E7D32);
  static const Color primaryDark = Color(0xFF173D24);
  static const Color primaryLight = Color(0xFFDDF0DD);

  // ── Dark Mode Tokens ────────────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF0F1711);
  static const Color darkSurface = Color(0xFF18231B);
  static const Color darkSurfaceSoft = Color(0xFF213025);
  static const Color darkBorder = Color(0xFF2E4033);
  static const Color darkTextPrimary = Color(0xFFF0F5F1);
  static const Color darkTextSecondary = Color(0xFF9EAD9F);

  // ── Extended Accent Tokens ──────────────────────────────────────────────
  static const Color emerald = Color(0xFF10B981); // healthy / good
  static const Color emeraldLight = Color(0xFFD1FAE5);
  static const Color gold = Color(0xFFD4A017); // metrics / FCR
  static const Color goldLight = Color(0xFFFEF3C7);
  static const Color dangerLight = Color(0xFFFEF2F2); // mortality bg
  static const Color indigo = Color(0xFF4F46E5); // reports accent
  static const Color indigoLight = Color(0xFFEDE9FE);
  static const Color ocean = Color(0xFF0284C7); // water / feed
  static const Color oceanLight = Color(0xFFE0F2FE);

  // ── Text & Content Tokens ───────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF17231B);
  static const Color textSecondary = Color(0xFF647067);
  static const Color textHint = textSecondary;
  static const Color textDisabled = Color(0xFFA0ACA2);

  // ── Borders & Shadows ───────────────────────────────────────────────────
  static const Color border = Color(0xFFDCE5DC);
  static const Color divider = border;
  static const Color shadow = Color(0x1A173D24);
  static const Color shadowMd = Color(0x2A173D24);

  // ── Semantic Status Colors ──────────────────────────────────────────────
  static const Color warning = Color(0xFFE49B25);
  static const Color danger = Color(0xFFD9534F);
  static const Color success = primary;
  static const Color error = danger;
  static const Color accent = warning;
  static const Color accentLight = Color(0xFFF8E1B9);
  static const Color info = ocean;

  // ── Aliases for backwards compatibility ─────────────────────────────────
  static const Color onPrimary = Colors.white;
  static const Color surfaceVariant = surfaceSoft;
  static const Color cardBg = surface;

  // ── Standard Gradients ──────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );

  static const LinearGradient farmGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF00897B)],
  );

  static const LinearGradient emeraldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF059669), Color(0xFF10B981)],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFD4A017), Color(0xFFF2C46B)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [surface, surfaceSoft],
  );

  static const LinearGradient dangerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFD9534F), Color(0xFFEF5350)],
  );
}

