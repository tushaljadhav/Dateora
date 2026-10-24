import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  static final List<String> _devanagariFallback = [
    GoogleFonts.notoSansDevanagari().fontFamily ?? 'Noto Sans Devanagari',
  ];

  // Display / Large Titles
  static TextStyle display = GoogleFonts.plusJakartaSans(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.6,
    height: 1.25,
  ).copyWith(fontFamilyFallback: _devanagariFallback);

  static TextStyle titleLarge = GoogleFonts.plusJakartaSans(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
    height: 1.3,
  ).copyWith(fontFamilyFallback: _devanagariFallback);

  static TextStyle titleMedium = GoogleFonts.plusJakartaSans(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    height: 1.35,
  ).copyWith(fontFamilyFallback: _devanagariFallback);

  static TextStyle titleSmall = GoogleFonts.plusJakartaSans(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
  ).copyWith(fontFamilyFallback: _devanagariFallback);

  // Body Text
  static TextStyle bodyLarge = GoogleFonts.plusJakartaSans(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  ).copyWith(fontFamilyFallback: _devanagariFallback);

  static TextStyle bodyMedium = GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.45,
  ).copyWith(fontFamilyFallback: _devanagariFallback);

  static TextStyle bodySmall = GoogleFonts.plusJakartaSans(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.4,
  ).copyWith(fontFamilyFallback: _devanagariFallback);

  // Captions & Labels
  static TextStyle caption = GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.35,
  ).copyWith(fontFamilyFallback: _devanagariFallback);

  static TextStyle label = GoogleFonts.plusJakartaSans(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
  ).copyWith(fontFamilyFallback: _devanagariFallback);

  // Buttons
  static TextStyle button = GoogleFonts.plusJakartaSans(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.1,
  ).copyWith(fontFamilyFallback: _devanagariFallback);
}
