import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors (Light Green - Fresh, Soft, Friendly)
  static const Color primary = Color(0xFF4ADE80);       // Light green 400
  static const Color primaryStrong = Color(0xFF16A34A); // Green 600 (links, active icons)
  static const Color primaryDark = Color(0xFF15803D);   // Green 700 (pressed states)
  static const Color primarySoft = Color(0xFFDCFCE7);   // Green 100 (chips, selected badges)
  static const Color textOnPrimary = Color(0xFF052E16); // Deep forest green for accessible contrast on #4ADE80

  // Semantic Status Colors
  // Note: "Safe" is intentionally a teal-green tone (#0D9488) so it never clashes with brand green (#4ADE80)
  static const Color statusSafe = Color(0xFF0D9488);       // Teal 600
  static const Color statusSafeBg = Color(0xFFCCFBF1);     // Teal 100
  static const Color statusSuccess = Color(0xFF16A34A);    // Green 600
  static const Color statusSuccessBg = Color(0xFFDCFCE7);  // Green 100
  static const Color statusWarning = Color(0xFFF59E0B);    // Amber 500
  static const Color statusWarningBg = Color(0xFFFEF3C7);  // Amber 100
  static const Color statusDanger = Color(0xFFEF4444);     // Red 500
  static const Color statusDangerBg = Color(0xFFFEE2E2);   // Red 100

  // Light Theme Surfaces
  static const Color lightBg = Color(0xFFF7FEF9);          // Fresh, slightly mint-tinted clean background
  static const Color lightSurface = Color(0xFFFFFFFF);     // Pure white card surfaces
  static const Color lightCard = Color(0xFFFFFFFF);        // Card background
  static const Color lightBorder = Color(0xFFE5EEE8);      // Subtle sage border
  static const Color lightDivider = Color(0xFFEFF4F0);     // Very soft divider
  static const Color lightTextPrimary = Color(0xFF0F172A); // Slate 900
  static const Color lightTextSecondary = Color(0xFF475569);// Slate 600
  static const Color lightTextMuted = Color(0xFF94A3B8);   // Slate 400

  // Dark Theme Surfaces
  static const Color darkBg = Color(0xFF0B120E);           // Deep obsidian-green background
  static const Color darkSurface = Color(0xFF121C16);      // Dark elevated surface
  static const Color darkCard = Color(0xFF17241C);         // Elevated card
  static const Color darkBorder = Color(0xFF1F2E25);       // Soft dark border
  static const Color darkDivider = Color(0xFF19271E);      // Dark divider
  static const Color darkTextPrimary = Color(0xFFF1F5F2);  // Off-white readable text
  static const Color darkTextSecondary = Color(0xFF94A3B8);// Slate 400
  static const Color darkTextMuted = Color(0xFF64748B);    // Slate 500
}
