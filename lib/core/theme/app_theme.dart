// lib/core/theme/app_theme.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,

      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.black,
        brightness: Brightness.light,
        background: Colors.white,
        surface: const Color(0xFFFDFDFD),
      ),

      textTheme: GoogleFonts.quicksandTextTheme(),

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 2,
        titleTextStyle: GoogleFonts.quicksand(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),

      cardTheme: CardThemeData(
        // ADD THIS LINE to explicitly set the card background to off-white
        color: const Color(0xFFFDFDFD),
        elevation: 1.5,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
          side: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: GoogleFonts.quicksand(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: Colors.black, width: 2.0),
        ),
        labelStyle: TextStyle(color: Colors.grey.shade700),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: Colors.grey.shade200,
        selectedColor: Colors.black,
        labelStyle: const TextStyle(color: Colors.black),
        secondaryLabelStyle: const TextStyle(color: Colors.white),
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      ),

      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: Color(0xFFFDFDFD),
        selectedIconTheme: IconThemeData(color: Colors.black),
        unselectedIconTheme: IconThemeData(color: Colors.grey),
        selectedLabelTextStyle: TextStyle(color: Colors.black),
        indicatorColor: Color(0xFFEEEEEE),
      ),
    );
  }
}
