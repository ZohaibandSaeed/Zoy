import 'package:flutter/material.dart';

class YouTubeTheme {
  // YouTube Colors
  static const Color ytRed = Color(0xFFFF0000);
  static const Color ytBlack = Color(0xFF0F0F0F);
  static const Color ytSurface = Color(0xFF1E1E1E);
  static const Color ytSurfaceLight = Color(0xFF272727);
  static const Color ytTextPrimary = Color(0xFFF1F1F1);
  static const Color ytTextSecondary = Color(0xFFAAAAAA);
  static const Color ytBorder = Color(0xFF282828);
  static const Color ytPillBg = Color(0xFF272727);
  static const Color ytPillActiveBg = Color(0xFFFFFFFF);
  static const Color ytPillActiveText = Color(0xFF0F0F0F);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: ytBlack,
      canvasColor: ytBlack,
      colorScheme: const ColorScheme.dark(
        primary: ytRed,
        secondary: ytRed,
        surface: ytSurface,
        onSurface: ytTextPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: ytBlack,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: ytTextPrimary, size: 24),
        actionsIconTheme: IconThemeData(color: ytTextPrimary, size: 24),
        titleTextStyle: TextStyle(
          color: ytTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: ytBlack,
        selectedItemColor: ytTextPrimary,
        unselectedItemColor: ytTextSecondary,
        selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        unselectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.normal),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      cardTheme: const CardThemeData(
        color: ytSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(
        color: ytBorder,
        thickness: 0.8,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: ytPillBg,
        labelStyle: const TextStyle(
          color: ytTextPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
      textTheme: const TextTheme(
        titleMedium: TextStyle(
          color: ytTextPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          height: 1.3,
        ),
        titleSmall: TextStyle(
          color: ytTextPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        bodySmall: TextStyle(
          color: ytTextSecondary,
          fontSize: 12,
          fontWeight: FontWeight.normal,
        ),
      ),
    );
  }
}

