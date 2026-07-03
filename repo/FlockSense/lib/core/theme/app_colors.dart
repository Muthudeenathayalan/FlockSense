import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Brand palette ─────────────────────────────────────────────────────────
  static const Color primary        = Color(0xFF0A5C38);   // deep forest green
  static const Color primaryLight   = Color(0xFF1B8C57);
  static const Color primaryDark    = Color(0xFF063D26);
  static const Color accent         = Color(0xFFD4A017);   // warm gold
  static const Color accentLight    = Color(0xFFF0C945);

  // ── Surfaces ──────────────────────────────────────────────────────────────
  static const Color surface        = Colors.white;
  static const Color surfaceVariant = Color(0xFFF2F7F4);
  static const Color background     = Color(0xFFEDF5F0);
  static const Color cardBg         = Color(0xFFFFFFFF);

  // ── Text ──────────────────────────────────────────────────────────────────
  static const Color textPrimary    = Color(0xFF0D1F18);
  static const Color textSecondary  = Color(0xFF4A6358);
  static const Color textHint       = Color(0xFF8FA99B);

  // ── System ────────────────────────────────────────────────────────────────
  static const Color onPrimary      = Colors.white;
  static const Color error          = Color(0xFFB71C1C);
  static const Color success        = Color(0xFF1B5E20);
  static const Color warning        = Color(0xFFF57F17);
  static const Color border         = Color(0xFFD6E8DC);
  static const Color divider        = Color(0xFFEAF0EC);
  static const Color shadow         = Color(0x18000000);
  static const Color shadowMd       = Color(0x28000000);

  // ── Gradients ─────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0A5C38), Color(0xFF1B8C57)],
  );
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF8FFF9), Color(0xFFEDF5F0)],
  );
  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFD4A017), Color(0xFFF0C945)],
  );
}
