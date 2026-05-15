import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // 1. Color Palette (Material 3)
  static const Color primary = Color(0xFF1565C0); // Xanh dương đậm (Blue 800)
  static const Color secondary = Color(0xFF64B5F6);
  static const Color background = Color(0xFFF1F8FF); // Xanh nhạt (Blue 50)
  static const Color cardColor = Colors.white;
  static const Color error = Color(0xFFD32F2F);

  // 2. Text Theme (Google Fonts Inter)
  static final TextTheme textTheme = TextTheme(
    displayLarge: GoogleFonts.inter(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: Colors.black,
    ),
    displayMedium: GoogleFonts.inter(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: Colors.black,
    ),
    headlineMedium: GoogleFonts.inter(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      color: Colors.black,
    ),
    bodyLarge: GoogleFonts.inter(
      fontSize: 16,
      color: Colors.black,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: 14,
      color: Colors.black87, // Darker than black54
    ),
  );


  // 3. Main Theme Data
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        background: background,
        surface: cardColor,
        error: error,
      ),
      textTheme: textTheme,
      scaffoldBackgroundColor: background,
      
      // Button Style
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // Input Decoration (TextField)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: const TextStyle(color: Colors.black87),
        floatingLabelStyle: const TextStyle(color: primary, fontWeight: FontWeight.bold),
        hintStyle: TextStyle(color: Colors.grey[600]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[400]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[400]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error),
        ),
        prefixIconColor: primary.withOpacity(0.8),
      ),
      
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: cardColor,
      ),
    );
  }

  // --- Members for backward compatibility with existing screens ---
  static const Color primaryDark = Color(0xFF0D47A1);
  static const LinearGradient mainGradient = LinearGradient(
    colors: [Color(0xFFBEE7FF), Color(0xFFDFF3FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static BoxDecoration cardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(14),
    boxShadow: [
      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
    ],
  );
}

