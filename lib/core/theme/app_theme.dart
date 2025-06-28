// filepath: /Users/ilonaholikova/VSCode/flutter_new_project/stream_flutter/lib/theme.dart

import 'package:flutter/material.dart';

class AppTheme {
  // Enhanced color palette with better contrast
  static const primaryBlue = Color(0xFF3F51B5); // More accessible primary blue
  static const primaryVariant = Color(0xFF1A237E); // Your original dark blue
  static const accentBlue = Color(0xFF64B5F6); // Light blue accent
  static const lightAccent = Color(
    0xFF90CAF9,
  ); // Even lighter for better contrast

  // Surface colors with proper hierarchy
  static const surfaceBlue = Color(
    0xFF1E2746,
  ); // Lighter surface for better contrast
  static const surfaceVariant = Color(0xFF2A3B5C); // Medium surface tone
  static const backgroundBlue = Color(
    0xFF0F1419,
  ); // Dark background with subtle blue

  // Text colors optimized for readability
  static const highEmphasisText = Color(0xFFE8EAF6); // High contrast white-blue
  static const mediumEmphasisText = Color(0xFFB3B8CF); // Medium contrast
  static const lowEmphasisText = Color(
    0xFF8A92B2,
  ); // Low emphasis but still readable
  static const disabledText = Color(0xFF5C6B85); // Disabled state

  // Success, warning, error colors that work on dark backgrounds
  static const successColor = Color(0xFF4CAF50);
  static const warningColor = Color(0xFFFF9800);
  static const errorColor = Color(0xFFFF5252);

  // Outline colors for better definition
  static const outlineColor = Color(0xFF4A5C7A);
  static const outlineVariant = Color(0xFF374157);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        // Primary colors
        primary: primaryBlue,
        onPrimary: Colors.white,
        primaryContainer: primaryVariant,
        onPrimaryContainer: lightAccent,

        // Secondary colors
        secondary: accentBlue,
        onSecondary: backgroundBlue,
        secondaryContainer: Color(0xFF1565C0),
        onSecondaryContainer: lightAccent,

        // Surface colors with proper contrast
        surface: surfaceBlue,
        onSurface: highEmphasisText,
        surfaceVariant: surfaceVariant,
        onSurfaceVariant: mediumEmphasisText,

        // Background
        background: backgroundBlue,
        onBackground: highEmphasisText,

        // State colors
        error: errorColor,
        onError: Colors.white,
        errorContainer: Color(0xFF601410),
        onErrorContainer: Color(0xFFFFDAD6),

        // Outline colors
        outline: outlineColor,
        outlineVariant: outlineVariant,

        // Additional colors
        shadow: Colors.black.withOpacity(0.8),
        scrim: Colors.black.withOpacity(0.9),
        inverseSurface: highEmphasisText,
        onInverseSurface: backgroundBlue,
        inversePrimary: primaryVariant,
      ),
      scaffoldBackgroundColor: backgroundBlue,

      appBarTheme: AppBarTheme(
        backgroundColor: surfaceBlue,
        foregroundColor: highEmphasisText,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: highEmphasisText,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: mediumEmphasisText),
        actionsIconTheme: IconThemeData(color: accentBlue),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceBlue,
        selectedItemColor: accentBlue,
        unselectedItemColor: mediumEmphasisText,
        showUnselectedLabels: true,
        selectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          color: accentBlue,
        ),
        unselectedLabelStyle: TextStyle(
          fontWeight: FontWeight.normal,
          color: mediumEmphasisText,
        ),
      ),

      cardTheme: CardThemeData(
        color: surfaceBlue,
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: outlineVariant, width: 0.5),
        ),
      ),

      textTheme: TextTheme(
        // Headlines - high emphasis
        headlineLarge: TextStyle(
          color: highEmphasisText,
          fontSize: 32,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.25,
        ),
        headlineMedium: TextStyle(
          color: highEmphasisText,
          fontSize: 28,
          fontWeight: FontWeight.bold,
          letterSpacing: 0,
        ),
        headlineSmall: TextStyle(
          color: highEmphasisText,
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),

        // Titles - medium to high emphasis
        titleLarge: TextStyle(
          color: highEmphasisText,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
        titleMedium: TextStyle(
          color: mediumEmphasisText,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
        ),
        titleSmall: TextStyle(
          color: mediumEmphasisText,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),

        // Body text - readable hierarchy
        bodyLarge: TextStyle(
          color: highEmphasisText,
          fontSize: 16,
          fontWeight: FontWeight.normal,
          letterSpacing: 0.5,
        ),
        bodyMedium: TextStyle(
          color: mediumEmphasisText,
          fontSize: 14,
          fontWeight: FontWeight.normal,
          letterSpacing: 0.25,
        ),
        bodySmall: TextStyle(
          color: lowEmphasisText,
          fontSize: 12,
          fontWeight: FontWeight.normal,
          letterSpacing: 0.4,
        ),

        // Labels
        labelLarge: TextStyle(
          color: accentBlue,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
        labelMedium: TextStyle(
          color: mediumEmphasisText,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        labelSmall: TextStyle(
          color: lowEmphasisText,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: outlineColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: outlineColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accentBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: errorColor),
        ),
        labelStyle: TextStyle(color: mediumEmphasisText),
        hintStyle: TextStyle(color: lowEmphasisText),
        helperStyle: TextStyle(color: lowEmphasisText),
        errorStyle: TextStyle(color: errorColor),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          disabledBackgroundColor: disabledText,
          disabledForegroundColor: Colors.white.withOpacity(0.38),
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accentBlue,
          disabledForegroundColor: disabledText,
          side: BorderSide(color: accentBlue),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentBlue,
          disabledForegroundColor: disabledText,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),

      iconTheme: IconThemeData(color: mediumEmphasisText, size: 24),

      primaryIconTheme: IconThemeData(color: accentBlue, size: 24),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: accentBlue,
        linearTrackColor: outlineVariant,
        circularTrackColor: outlineVariant,
      ),

      textSelectionTheme: TextSelectionThemeData(
        cursorColor: accentBlue,
        selectionColor: accentBlue.withOpacity(0.3),
        selectionHandleColor: accentBlue,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceVariant,
        contentTextStyle: TextStyle(color: highEmphasisText),
        actionTextColor: accentBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      dividerTheme: DividerThemeData(
        color: outlineVariant,
        thickness: 1,
        space: 24,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: surfaceVariant,
        disabledColor: disabledText,
        selectedColor: primaryBlue,
        secondarySelectedColor: accentBlue.withOpacity(0.2),
        shadowColor: Colors.black.withOpacity(0.2),
        selectedShadowColor: Colors.black.withOpacity(0.3),
        showCheckmark: false,
        labelStyle: TextStyle(color: mediumEmphasisText),
        secondaryLabelStyle: TextStyle(color: highEmphasisText),
        brightness: Brightness.dark,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: outlineColor),
        ),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) return accentBlue;
          return mediumEmphasisText;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected))
            return accentBlue.withOpacity(0.5);
          return outlineColor;
        }),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) return accentBlue;
          return Colors.transparent;
        }),
        checkColor: MaterialStateProperty.all(backgroundBlue),
        side: BorderSide(color: outlineColor, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) return accentBlue;
          return outlineColor;
        }),
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: accentBlue,
        inactiveTrackColor: outlineColor,
        thumbColor: accentBlue,
        overlayColor: accentBlue.withOpacity(0.2),
        valueIndicatorColor: primaryBlue,
        valueIndicatorTextStyle: TextStyle(color: Colors.white),
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: accentBlue,
        unselectedLabelColor: mediumEmphasisText,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: accentBlue, width: 2),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        unselectedLabelStyle: TextStyle(
          fontWeight: FontWeight.normal,
          fontSize: 14,
        ),
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: surfaceVariant,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: outlineColor),
        ),
        textStyle: TextStyle(color: highEmphasisText, fontSize: 12),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: surfaceBlue,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: outlineColor),
        ),
        titleTextStyle: TextStyle(
          color: highEmphasisText,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: TextStyle(color: mediumEmphasisText, fontSize: 14),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surfaceBlue,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        constraints: BoxConstraints(maxWidth: double.infinity),
      ),
    );
  }
}
