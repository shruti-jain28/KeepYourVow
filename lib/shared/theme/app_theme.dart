// lib/shared/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── COLORS ─────────────────────────────────────────────────────────────────
// Import anywhere: import 'package:keepyourvow/shared/theme/app_theme.dart';
class KYVColors {
  KYVColors._(); // prevent instantiation

  static const sky = Color(0xFF2E86C1); // primary — buttons, ring, accents
  static const deep = Color(0xFF1A5276); // headers, dark backgrounds
  static const light = Color(0xFFD6EAF8); // card backgrounds, surfaces
  static const pale = Color(0xFFEBF5FB); // page/scaffold background
  static const teal = Color(0xFF1ABC9C); // SUCCESS ONLY — habit complete, unlock
  static const slate = Color(0xFF4A5568); // body text
  static const darkGray = Color(0xFF718096); // captions, secondary text
  static const white = Color(0xFFFFFFFF);

  // Use these for Guardian status (Week 3)
  static const guardianActive = teal;
  static const guardianInactive = Color(0xFF9CA3AF);
}

// ─── TEXT STYLES ─────────────────────────────────────────────────────────────
class KYVText {
  KYVText._();

  static TextStyle display(BuildContext context) =>
      GoogleFonts.plusJakartaSans(
          fontSize: 28, fontWeight: FontWeight.bold, color: KYVColors.deep);

  static TextStyle heading(BuildContext context) =>
      GoogleFonts.plusJakartaSans(
          fontSize: 20, fontWeight: FontWeight.bold, color: KYVColors.deep);

  static TextStyle subheading(BuildContext context) =>
      GoogleFonts.plusJakartaSans(
          fontSize: 16, fontWeight: FontWeight.w600, color: KYVColors.slate);

  static TextStyle body(BuildContext context) =>
      GoogleFonts.plusJakartaSans(
          fontSize: 15,
          fontWeight: FontWeight.normal,
          color: KYVColors.slate);

  static TextStyle caption(BuildContext context) =>
      GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.normal,
          color: KYVColors.darkGray);

  // for identity phrases on lock screen
  static TextStyle identity(BuildContext context) =>
      GoogleFonts.plusJakartaSans(
          fontSize: 17,
          fontWeight: FontWeight.w500,
          color: KYVColors.deep,
          fontStyle: FontStyle.italic);
}

// ─── THEME ───────────────────────────────────────────────────────────────────
class KYVTheme {
  KYVTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: KYVColors.sky,
          surface: KYVColors.white,
          primary: KYVColors.sky,
        ),
        scaffoldBackgroundColor: KYVColors.pale,
        textTheme: GoogleFonts.plusJakartaSansTextTheme(),
        appBarTheme: const AppBarTheme(
          backgroundColor: KYVColors.pale,
          elevation: 0,
          foregroundColor: KYVColors.deep,
          centerTitle: false,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: KYVColors.sky,
            foregroundColor: KYVColors.white,
            minimumSize: const Size.fromHeight(52), // full-width, 52dp tall
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        cardTheme: CardThemeData(
          color: KYVColors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: KYVColors.light, width: 1.5),
          ),
        ),
      );
}
