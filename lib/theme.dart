import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF3A8DFF);
  // A darker blue for headers and primary actions when needed
  static const Color primaryDark = Color(0xFF0B57A4);
  static const Color primaryLight = Color(0xFFBEE7FF);
  static const Color primaryLighter = Color(0xFFDFF3FF);

  static LinearGradient get mainGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primaryLight, primaryLighter],
      );

  static BoxDecoration headerDecoration = BoxDecoration(
    gradient: mainGradient,
  );

  static BoxDecoration cardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(14),
    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
  );

  static InputDecorationTheme inputDecorationTheme = InputDecorationTheme(
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: primary.withOpacity(0.15))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: primary, width: 2)),
    prefixIconColor: primary,
    floatingLabelStyle: TextStyle(color: primary),
  );

  static ElevatedButtonThemeData elevatedButtonTheme = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
    ),
  );
}
