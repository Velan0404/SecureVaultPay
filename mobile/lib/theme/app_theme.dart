import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// SecureVault Pay's design system palette — a dark, premium fintech look
/// (Google Pay / CRED / Revolut register), built from the Figma reference.
/// Every screen should read colors from here; nothing should hardcode a hex
/// value inline.
class AppColors {
  AppColors._();

  // Surfaces
  static const background = Color(0xFF0D0D0D);
  static const surface = Color(0xFF181313);
  static const surfaceElevated = Color(0xFF221B1B);
  static const surfaceSunken = Color(0xFF0A0707);
  static const divider = Color(0xFF2A2222);

  // Legacy alias kept for the few places a literal "card" surface reads more
  // clearly than "surface" — same color, no separate meaning.
  static const card = surface;

  // Brand
  static const primaryRed = Color(0xFFE53935);
  static const crimson = Color(0xFFFF5252);
  static const deepMaroon = Color(0xFF2C0A0A);
  static const maroonGlow = Color(0xFF4A1414);

  // Text
  static const textPrimary = Color(0xFFF5F5F5);
  static const textSecondary = Color(0xFF9B9B9B);
  static const textMuted = Color(0xFF6E6E6E);

  // Semantic
  static const success = Color(0xFF34C759);
  static const warning = Color(0xFFF5A623);
  static const danger = primaryRed;
  static const info = Color(0xFF3E8BFF);

  // Purpose Wallet category accents
  static const categoryTeal = Color(0xFF2DD9A8);
  static const categoryOrange = Color(0xFFF5A623);
  static const categoryPurple = Color(0xFF9B6BFF);
  static const categoryBlue = Color(0xFF3E8BFF);
  static const categoryPink = Color(0xFFEC4899);
  static const categoryGold = Color(0xFFF4C430);

  static const buttonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryRed, crimson],
  );

  /// The dark maroon-to-black gradient used on the Main Wallet / hero
  /// balance card — a premium "credit card" surface, not a loud red banner.
  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [maroonGlow, deepMaroon, background],
    stops: [0, 0.55, 1],
  );

  // Retained for any lingering reference to the pre-redesign token name.
  static const primaryBlack = background;
  static const secondaryRed = primaryRed;
  static const accentCrimson = crimson;
}

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final base = ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryRed,
        secondary: AppColors.crimson,
        surface: AppColors.surface,
        error: AppColors.danger,
      ),
    );

    final textTheme = GoogleFonts.poppinsTextTheme(base.textTheme).apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    );

    return base.copyWith(
      textTheme: textTheme.copyWith(
        headlineSmall: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, fontSize: 26),
        headlineMedium: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
        titleLarge: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        bodyMedium: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary, height: 1.4),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceElevated,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primaryRed, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        hintStyle: const TextStyle(color: AppColors.textMuted),
        prefixIconColor: AppColors.textSecondary,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surfaceElevated,
        contentTextStyle: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.divider),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: textTheme.titleLarge?.copyWith(color: AppColors.textPrimary),
        contentTextStyle: const TextStyle(color: AppColors.textSecondary, height: 1.4),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
        ),
        showDragHandle: true,
        dragHandleColor: AppColors.divider,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.primaryRed),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(backgroundColor: WidgetStateProperty.all(AppColors.surfaceElevated)),
      ),
      popupMenuTheme: const PopupMenuThemeData(color: AppColors.surfaceElevated),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.primaryRed),
      dividerTheme: const DividerThemeData(color: AppColors.divider, thickness: 1),
      splashFactory: InkSparkle.splashFactory,
    );
  }
}
