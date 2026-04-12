import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Girgo admin — brand: green, white, black.
abstract final class GirgoBrand {
  static const Color green = Color(0xFF0D5C43);
  static const Color greenMid = Color(0xFF14805E);
  static const Color greenMuted = Color(0xFF2A9D78);
  static const Color greenSoft = Color(0xFFE8F5F0);
  static const Color greenWash = Color(0xFFF0F7F4);

  static const Color black = Color(0xFF0A0A0A);
  static const Color blackMuted = Color(0xFF2D2D2D);
  static const Color white = Color(0xFFFFFFFF);
  static const Color offWhite = Color(0xFFF7F9F8);

  static const Color border = Color(0xFFDDE8E3);
  static const Color borderLight = Color(0xFFEBF2EF);

  static ThemeData light() {
    final scheme = ColorScheme(
      brightness: Brightness.light,
      primary: green,
      onPrimary: white,
      primaryContainer: greenSoft,
      onPrimaryContainer: black,
      secondary: blackMuted,
      onSecondary: white,
      secondaryContainer: Color(0xFFECEEED),
      onSecondaryContainer: black,
      tertiary: greenMid,
      onTertiary: white,
      error: Color(0xFFC62828),
      onError: white,
      surface: white,
      onSurface: black,
      onSurfaceVariant: Color(0xFF4A5753),
      surfaceContainerLow: white,
      surfaceContainer: offWhite,
      surfaceContainerHigh: greenWash,
      surfaceContainerHighest: greenSoft,
      outline: border,
      outlineVariant: borderLight,
    );

    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));

    final baseText = ThemeData(brightness: Brightness.light, useMaterial3: true).textTheme;
    final textTheme = GoogleFonts.plusJakartaSansTextTheme(baseText).apply(
      bodyColor: black,
      displayColor: black,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: offWhite,
      splashFactory: InkRipple.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        backgroundColor: white,
        foregroundColor: black,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: black,
          letterSpacing: -0.3,
        ),
        iconTheme: const IconThemeData(color: black, size: 22),
        shape: const Border(
          bottom: BorderSide(color: borderLight, width: 1),
        ),
      ),
      cardTheme: CardThemeData(
        color: white,
        elevation: 0,
        shadowColor: black.withValues(alpha: 0.06),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderLight, width: 1),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          foregroundColor: white,
          backgroundColor: green,
          disabledForegroundColor: white.withValues(alpha: 0.7),
          disabledBackgroundColor: green.withValues(alpha: 0.4),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: shape,
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: black,
          side: const BorderSide(color: border, width: 1.2),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: shape,
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: green,
          foregroundColor: white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: shape,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: green, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
        labelStyle: TextStyle(color: black.withValues(alpha: 0.65), fontWeight: FontWeight.w500),
        floatingLabelStyle: const TextStyle(color: green, fontWeight: FontWeight.w600),
        hintStyle: TextStyle(color: black.withValues(alpha: 0.38)),
      ),
      dividerTheme: const DividerThemeData(color: borderLight, thickness: 1, space: 1),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: white,
        elevation: 0,
        indicatorColor: greenSoft,
        selectedIconTheme: const IconThemeData(color: green, size: 24),
        unselectedIconTheme: IconThemeData(color: black.withValues(alpha: 0.45), size: 22),
        selectedLabelTextStyle: const TextStyle(
          color: green,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: black.withValues(alpha: 0.55),
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        labelType: NavigationRailLabelType.all,
      ),
      scrollbarTheme: ScrollbarThemeData(
        radius: const Radius.circular(8),
        thickness: WidgetStateProperty.all(6),
        thumbColor: WidgetStateProperty.all(green.withValues(alpha: 0.35)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: blackMuted,
        contentTextStyle: const TextStyle(color: white, fontWeight: FontWeight.w500),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: black,
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: black.withValues(alpha: 0.55),
        textColor: black,
        titleTextStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: black,
        ),
        subtitleTextStyle: TextStyle(
          fontSize: 13,
          color: black.withValues(alpha: 0.55),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: green,
        linearTrackColor: greenSoft,
        circularTrackColor: greenSoft,
      ),
    );
  }
}
