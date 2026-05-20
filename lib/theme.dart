import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primary = Color(0xFF9C27B0); // Màu tím chủ đạo (Purple 500)
  static const Color secondary = Color(0xFFE1BEE7); // Màu tím nhạt
  static const Color background = Color(0xFFF8F9FA); // Nền xám nhạt sáng chuẩn Apple Health
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

  // 3. Light Theme Data
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
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: cardColor,
      ),

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: Colors.black87,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),

      // BottomNavigationBar
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }

  // 4. Dark Theme Data (Discord Aesthetic)
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        background: Color(0xFF1E1F22),
        surface: Color(0xFF2B2D31),
        error: error,
      ),
      scaffoldBackgroundColor: const Color(0xFF1E1F22),
      dividerColor: const Color(0xFF35373C),
      
      textTheme: TextTheme(
        displayLarge: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: const Color(0xFFF2F3F5),
        ),
        displayMedium: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: const Color(0xFFF2F3F5),
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: const Color(0xFFF2F3F5),
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          color: const Color(0xFFF2F3F5),
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: const Color(0xFFB5BAC1),
        ),
      ),

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
        fillColor: const Color(0xFF2B2D31),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: const TextStyle(color: Color(0xFFB5BAC1)),
        floatingLabelStyle: const TextStyle(color: secondary, fontWeight: FontWeight.bold),
        hintStyle: const TextStyle(color: Color(0xFF949BA4)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF35373C)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF35373C)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error),
        ),
        prefixIconColor: secondary.withOpacity(0.8),
      ),
      
      cardTheme: const CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        color: Color(0xFF2B2D31),
      ),

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF2B2D31),
        foregroundColor: const Color(0xFFF2F3F5),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: const Color(0xFFF2F3F5),
        ),
        iconTheme: const IconThemeData(color: Color(0xFFF2F3F5)),
      ),

      // BottomNavigationBar
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF2B2D31),
        selectedItemColor: primary,
        unselectedItemColor: Color(0xFF949BA4),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }

  // --- Members for backward compatibility with existing screens ---
  static const Color primaryDark = Color(0xFF7B1FA2);
  static const LinearGradient mainGradient = LinearGradient(
    colors: [Color(0xFFE1BEE7), Color(0xFFF3E5F5)],
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

class PurpleGradientButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double? width;
  final double height;
  final BorderRadius? borderRadius;

  const PurpleGradientButton({
    Key? key,
    required this.child,
    required this.onPressed,
    this.width,
    this.height = 52.0,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = onPressed != null;
    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        gradient: isEnabled
            ? const LinearGradient(
                colors: [Color(0xFFBB86FC), Color(0xFF8A2BE2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isEnabled ? null : Colors.grey[400],
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        boxShadow: isEnabled
            ? [
                BoxShadow(
                  color: const Color(0xFF8A2BE2).withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]
            : null,
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          disabledForegroundColor: Colors.white60,
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius ?? BorderRadius.circular(16),
          ),
        ),
        onPressed: onPressed,
        child: child,
      ),
    );
  }
}
