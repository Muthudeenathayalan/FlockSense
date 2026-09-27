import 'package:flutter/material.dart';

/// Centralized layout tokens and styling constants for the FlockSense Home Dashboard.
class HomeTokens {
  HomeTokens._();

  // Spatial Grid
  static const double screenGutter = 16.0;
  static const double cardPadding = 14.0;
  static const double cardRadius = 16.0;
  static const double smallRadius = 12.0;

  // Vertical Rhythm
  static const double gapTight = 8.0;
  static const double gapNormal = 12.0;
  static const double gapMedium = 16.0;
  static const double gapSection = 22.0;
  static const double gapHeaderToBody = 10.0;

  // Primary Palette
  static const Color primary = Color(0xFF16A34A);
  static const Color primaryDark = Color(0xFF104422);
  static const Color primaryDeep = Color(0xFF14522A);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF8FAFC);
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFF1F5F9);

  // Text Colors
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);

  // Accents
  static const Color blue = Color(0xFF2563EB);
  static const Color sky = Color(0xFF0EA5E9);
  static const Color amber = Color(0xFFF59E0B);
  static const Color red = Color(0xFFEF4444);
  static const Color indigo = Color(0xFF6366F1);

  // Soft Tints
  static const Color greenTint = Color(0xFFDCFCE7);
  static const Color blueTint = Color(0xFFDBEAFE);
  static const Color amberTint = Color(0xFFFEF3C7);
  static const Color redTint = Color(0xFFFEE2E2);
  static const Color indigoTint = Color(0xFFEEF2FF);

  // Shadows
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x060F172A),
      blurRadius: 10,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color(0x040F172A),
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
  ];
}
