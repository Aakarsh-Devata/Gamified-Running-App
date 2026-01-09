import 'package:flutter/material.dart';

class FuturisticTheme {
  // Core Colors
  static const Color background = Color(0xFF0A0A0F);
  static const Color surface = Color(0xFF12121A);
  static const Color primaryCyan = Color(0xFF00E5FF);
  static const Color secondaryViolet = Color(0xFFA855F7);
  static const Color textWhite = Color(0xFFF5F5F5);
  static const Color textGrey = Color(0xFF9ca3af);

  // Gradients
  static const LinearGradient neonGradient = LinearGradient(
    colors: [primaryCyan, secondaryViolet],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient surfGradient = LinearGradient(
     begin: Alignment.topCenter,
     end: Alignment.bottomCenter,
     colors: [Color(0xFF0a0a0f), Color(0xFF12121a)],
  );

  // Shadows/Glows
  static List<BoxShadow> glowCyan = [
    BoxShadow(color: primaryCyan.withOpacity(0.3), blurRadius: 10, spreadRadius: 0),
    BoxShadow(color: primaryCyan.withOpacity(0.15), blurRadius: 20, spreadRadius: 0),
  ];

  static List<BoxShadow> glowViolet = [
    BoxShadow(color: secondaryViolet.withOpacity(0.3), blurRadius: 10, spreadRadius: 0),
    BoxShadow(color: secondaryViolet.withOpacity(0.15), blurRadius: 20, spreadRadius: 0),
  ];

  // Theme Data
  static ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: primaryCyan,
      colorScheme: ColorScheme.dark(
        primary: primaryCyan,
        secondary: secondaryViolet,
        surface: surface,
        background: background,
        onBackground: textWhite,
        onSurface: textWhite,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textWhite,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryCyan,
          foregroundColor: Colors.black,
          elevation: 5,
          shadowColor: primaryCyan.withOpacity(0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0),
        ),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(color: textWhite, fontWeight: FontWeight.bold, letterSpacing: -0.5),
        displayMedium: TextStyle(color: textWhite, fontWeight: FontWeight.bold, letterSpacing: -0.5),
        bodyLarge: TextStyle(color: textWhite),
        bodyMedium: TextStyle(color: textGrey),
      ),
    );
  }
}
