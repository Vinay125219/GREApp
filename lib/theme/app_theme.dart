import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors
  static const Color primary = Color(0xFF1E3A8A);
  static const Color primaryLight = Color(0xFF3B5FBB);
  static const Color primaryContainer = Color(0xFFDBE4FF);
  static const Color secondary = Color(0xFF0F766E);
  static const Color secondaryContainer = Color(0xFFCCFBF1);
  static const Color accent = Color(0xFF7C3AED);
  static const Color accentContainer = Color(0xFFEDE9FE);

  // Semantic Colors
  static const Color success = Color(0xFF0F766E);
  static const Color successContainer = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFB45309);
  static const Color warningContainer = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFB91C1C);
  static const Color errorContainer = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF0369A1);
  static const Color infoContainer = Color(0xFFE0F2FE);

  // Surface Colors
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F5F9);
  static const Color background = Color(0xFFF8FAFC);
  static const Color outline = Color(0xFFCBD5E1);
  static const Color outlineVariant = Color(0xFFE2E8F0);

  // Text Colors
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkSurfaceVariant = Color(0xFF334155);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFFCBD5E1);

  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.ibmPlexSansTextTheme();
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: primary,
        onPrimary: textOnPrimary,
        primaryContainer: primaryContainer,
        onPrimaryContainer: primary,
        secondary: secondary,
        onSecondary: textOnPrimary,
        secondaryContainer: secondaryContainer,
        onSecondaryContainer: secondary,
        tertiary: accent,
        tertiaryContainer: accentContainer,
        error: error,
        errorContainer: errorContainer,
        surface: surface,
        onSurface: textPrimary,
        surfaceContainerHighest: surfaceVariant,
        outline: outline,
        outlineVariant: outlineVariant,
      ),
      scaffoldBackgroundColor: background,
      textTheme: baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        displayMedium: baseTextTheme.displayMedium?.copyWith(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        displaySmall: baseTextTheme.displaySmall?.copyWith(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        headlineLarge: baseTextTheme.headlineLarge?.copyWith(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        headlineSmall: baseTextTheme.headlineSmall?.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleSmall: baseTextTheme.titleSmall?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: textPrimary,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textPrimary,
        ),
        bodySmall: baseTextTheme.bodySmall?.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: textSecondary,
        ),
        labelLarge: baseTextTheme.labelLarge?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: 0.1,
        ),
        labelMedium: baseTextTheme.labelMedium?.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textSecondary,
          letterSpacing: 0.2,
        ),
        labelSmall: baseTextTheme.labelSmall?.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: textMuted,
          letterSpacing: 0.3,
        ),
      ),
      appBarTheme: const AppBarThemeData(
        backgroundColor: surface,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'IBM Plex Sans',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: surface,
        indicatorColor: primaryContainer,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primary, size: 24);
          }
          return const IconThemeData(color: textMuted, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontFamily: 'IBM Plex Sans',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: primary,
            );
          }
          return const TextStyle(
            fontFamily: 'IBM Plex Sans',
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: textMuted,
          );
        }),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(0),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: outline, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error, width: 2),
        ),
        labelStyle: const TextStyle(
          fontFamily: 'IBM Plex Sans',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textSecondary,
        ),
        hintStyle: const TextStyle(
          fontFamily: 'IBM Plex Sans',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textMuted,
        ),
        errorStyle: const TextStyle(
          fontFamily: 'IBM Plex Sans',
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: error,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: textOnPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: 'IBM Plex Sans',
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: textOnPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: 'IBM Plex Sans',
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: 'IBM Plex Sans',
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceVariant,
        selectedColor: primaryContainer,
        labelStyle: const TextStyle(
          fontFamily: 'IBM Plex Sans',
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      dividerTheme: const DividerThemeData(
        color: outlineVariant,
        thickness: 1,
        space: 1,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: textOnPrimary,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: textPrimary,
        contentTextStyle: const TextStyle(
          fontFamily: 'IBM Plex Sans',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: primaryContainer,
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: textMuted,
        indicatorColor: primary,
        labelStyle: TextStyle(
          fontFamily: 'IBM Plex Sans',
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'IBM Plex Sans',
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    final baseTextTheme = GoogleFonts.ibmPlexSansTextTheme(
      ThemeData.dark().textTheme,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF93ABEE),
        onPrimary: Color(0xFF0D1F5C),
        primaryContainer: Color(0xFF1E3A8A),
        onPrimaryContainer: Color(0xFFDBE4FF),
        secondary: Color(0xFF5EEAD4),
        onSecondary: Color(0xFF003733),
        secondaryContainer: Color(0xFF0F766E),
        onSecondaryContainer: Color(0xFFCCFBF1),
        tertiary: Color(0xFFC4B5FD),
        tertiaryContainer: Color(0xFF5B21B6),
        error: Color(0xFFFF8A80),
        errorContainer: Color(0xFF7F1D1D),
        surface: darkSurface,
        onSurface: darkTextPrimary,
        surfaceContainerHighest: darkSurfaceVariant,
        outline: Color(0xFF475569),
        outlineVariant: Color(0xFF334155),
      ),
      scaffoldBackgroundColor: darkBackground,
      textTheme: baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: darkTextPrimary,
        ),
        headlineLarge: baseTextTheme.headlineLarge?.copyWith(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: darkTextPrimary,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: darkTextPrimary,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: darkTextPrimary,
        ),
        bodySmall: baseTextTheme.bodySmall?.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: darkTextSecondary,
        ),
        labelMedium: baseTextTheme.labelMedium?.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: darkTextSecondary,
          letterSpacing: 0.2,
        ),
      ),
      appBarTheme: const AppBarThemeData(
        backgroundColor: darkSurface,
        foregroundColor: darkTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: darkSurface,
        indicatorColor: const Color(0xFF1E3A8A),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: Color(0xFF93ABEE), size: 24);
          }
          return const IconThemeData(color: Color(0xFF64748B), size: 24);
        }),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: darkSurfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF475569), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF93ABEE), width: 2),
        ),
      ),
    );
  }
}
