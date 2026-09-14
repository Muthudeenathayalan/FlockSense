import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Core Brand Palette ──────────────────────────────────────────────────
  static const Color background   = Color(0xFFF8FAFC); // clean modern neutral off-white background
  static const Color surface      = Color(0xFFFFFFFF); // pure white cards
  static const Color surfaceSoft  = Color(0xFFDCFCE7); // soft green tint
  static const Color primary      = Color(0xFF16A34A); // vibrant green
  static const Color primaryDeep  = Color(0xFF14522A); // rich deep forest green
  static const Color primaryDark  = Color(0xFF104422); // toned-down dark forest green
  static const Color primaryLight = Color(0xFFDCFCE7); // soft green chip bg

  // ── Text & Content Tokens ───────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF0F172A); // dark slate
  static const Color textSecondary = Color(0xFF64748B); // cool grey
  static const Color textMuted     = Color(0xFF94A3B8); // muted grey
  static const Color textDisabled  = Color(0xFFCBD5E1);
  static const Color textHint      = textSecondary;

  // ── Borders & Shadows ────────────────────────────────────────────────────
  static const Color border      = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFF1F5F9);
  static const Color divider     = border;
  static const Color shadow      = Color(0x060F172A);
  static const Color shadowMd    = Color(0x140F172A);

  // ── Semantic Status Colors ──────────────────────────────────────────────
  static const Color warning  = Color(0xFFF59E0B); // amber
  static const Color danger   = Color(0xFFEF4444); // red
  static const Color info     = Color(0xFF2563EB); // blue
  static const Color success  = primary;
  static const Color error    = danger;
  static const Color accent   = warning;

  // ── Soft Tints ──────────────────────────────────────────────────────────
  static const Color greenTint  = Color(0xFFDCFCE7);
  static const Color blueTint   = Color(0xFFDBEAFE);
  static const Color amberTint  = Color(0xFFFEF3C7);
  static const Color redTint    = Color(0xFFFEE2E2);
  static const Color indigoTint = Color(0xFFEEF2FF);

  // ── Aliases (backwards-compat for feature screens) ───────────────────────
  static const Color onPrimary     = Colors.white;
  static const Color cardBg        = surface;
  static const Color surfaceVariant = surfaceSoft;
  static const Color accentLight   = amberTint;
  static const Color dangerLight   = redTint;
  static const Color emeraldLight  = greenTint;
  static const Color goldLight     = amberTint;
  static const Color oceanLight    = blueTint;
  static const Color indigoLight   = indigoTint;

  // ── Named accent aliases used by feature screens ─────────────────────────
  static const Color emerald = Color(0xFF10B981);
  static const Color gold    = Color(0xFFF59E0B);
  static const Color ocean   = Color(0xFF2563EB);
  static const Color indigo  = Color(0xFF6366F1);

  // ── Dark Mode Tokens ─────────────────────────────────────────────────────
  static const Color darkBackground    = Color(0xFF0A1F0F);
  static const Color darkSurface       = Color(0xFF122318);
  static const Color darkSurfaceSoft   = Color(0xFF1A3323);
  static const Color darkBorder        = Color(0xFF274D35);
  static const Color darkTextPrimary   = Color(0xFFF0FAF4);
  static const Color darkTextSecondary = Color(0xFF86A893);

  // ── Standard Gradients ──────────────────────────────────────────────────
  /// Dark-green to medium-green — used in dashboard SliverAppBar header
  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF104422), Color(0xFF14522A), Color(0xFF14532D)],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryDeep, primary],
  );

  static const LinearGradient farmGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF14532D), Color(0xFF15803D), Color(0xFF16A34A)],
  );

  static const LinearGradient emeraldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF059669), Color(0xFF10B981)],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [surface, surfaceSoft],
  );

  static const LinearGradient dangerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
  );
}
