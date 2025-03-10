import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Main color palette - updated with playful pastel colors
  static const Color primaryColor = Color(0xFF6B9DFF); // Soft blue
  static const Color secondaryColor = Color(0xFFFF9D6B); // Soft orange
  static const Color accentColor = Color(0xFF9DFFB3); // Soft mint green
  static const Color tertiaryColor = Color(0xFFD9B3FF); // Soft purple
  static const Color successColor = Color(0xFF9CE3AC); // Soft green
  static const Color errorColor = Color(0xFFFF8383); // Soft red
  static const Color warningColor = Color(0xFFFFDF8E); // Soft yellow

  // Background colors
  static const Color backgroundColorLight = Color(0xFFF9F9FD);
  static const Color backgroundColorDark = Color(0xFF2A2A40);
  static const Color surfaceColorLight = Colors.white;
  static const Color surfaceColorDark = Color(0xFF333344);

  // Text colors
  static const Color textColorLight = Color(0xFF3D3D56);
  static const Color textColorDark = Color(0xFFF5F5FF);
  static const Color textSecondaryLight = Color(0xFF757589);
  static const Color textSecondaryDark = Color(0xFFBDBDDB);

  // Canvas colors
  static const Color canvasColor = Colors.white;
  static const Color canvasBorderColor = Color(0xFFE0E0E6);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryColor, Color(0xFF8EB5FF)],
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondaryColor, Color(0xFFFFB59E)],
  );

  static const LinearGradient playfulGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6B9DFF), Color(0xFFD9B3FF), Color(0xFFFF9D6B)],
  );

  // Animation durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 350);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);

  // Border radiuses - increased for more playful look
  static const double buttonRadius = 20.0;
  static const double cardRadius = 20.0;
  static const double inputRadius = 16.0;

  // Shadows - softer for cartoonish look
  static List<BoxShadow> smallShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 8,
      offset: const Offset(0, 3),
      spreadRadius: 1,
    ),
  ];

  static List<BoxShadow> mediumShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 12,
      offset: const Offset(0, 5),
      spreadRadius: 2,
    ),
  ];

  static List<BoxShadow> largeShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 20,
      offset: const Offset(0, 8),
      spreadRadius: 3,
    ),
  ];

  static List<BoxShadow> coloredShadow(Color color) => [
    BoxShadow(
      color: color.withOpacity(0.25),
      blurRadius: 12,
      offset: const Offset(0, 4),
      spreadRadius: 2,
    ),
  ];

  // Button styles
  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: Colors.white,
    elevation: 6,
    shadowColor: primaryColor.withOpacity(0.5),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(buttonRadius),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    textStyle: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.normal),
  );

  static ButtonStyle secondaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: secondaryColor,
    foregroundColor: Colors.white,
    elevation: 6,
    shadowColor: secondaryColor.withOpacity(0.5),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(buttonRadius),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    textStyle: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.normal),
  );

  static ButtonStyle outlinedButtonStyle = OutlinedButton.styleFrom(
    foregroundColor: primaryColor,
    side: const BorderSide(color: primaryColor, width: 2),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(buttonRadius),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    textStyle: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.normal),
  );

  // Card styles
  static CardTheme cardTheme = CardTheme(
    color: surfaceColorLight,
    elevation: 6,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(cardRadius),
    ),
    margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
  );

  // Input decoration
  static InputDecorationTheme inputDecorationTheme = InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(inputRadius),
      borderSide: BorderSide(color: primaryColor.withOpacity(0.3)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(inputRadius),
      borderSide: BorderSide(color: primaryColor.withOpacity(0.3)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(inputRadius),
      borderSide: const BorderSide(color: primaryColor, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(inputRadius),
      borderSide: const BorderSide(color: errorColor),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    filled: true,
    fillColor: surfaceColorLight,
    labelStyle: TextStyle(color: textColorLight.withOpacity(0.7)),
    hintStyle: TextStyle(color: textColorLight.withOpacity(0.5)),
  );

  // Light theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: accentColor,
        surface: surfaceColorLight,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textColorLight,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: backgroundColorLight,
      fontFamily: GoogleFonts.comicNeue().fontFamily,
      textTheme: GoogleFonts.comicNeueTextTheme(
        ThemeData.light().textTheme.copyWith(
          displayLarge: GoogleFonts.fredoka(
            color: textColorLight,
            fontSize: 32,
            fontWeight: FontWeight.normal,
          ),
          displayMedium: GoogleFonts.fredoka(
            color: textColorLight,
            fontSize: 28,
            fontWeight: FontWeight.normal,
          ),
          displaySmall: GoogleFonts.fredoka(
            color: textColorLight,
            fontSize: 24,
            fontWeight: FontWeight.normal,
          ),
          headlineMedium: GoogleFonts.fredoka(
            color: textColorLight,
            fontSize: 20,
            fontWeight: FontWeight.normal,
          ),
          titleLarge: GoogleFonts.fredoka(
            color: textColorLight,
            fontSize: 18,
            fontWeight: FontWeight.normal,
          ),
          bodyLarge: const TextStyle(color: textColorLight, fontSize: 16),
          bodyMedium: const TextStyle(color: textColorLight, fontSize: 14),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(style: primaryButtonStyle),
      outlinedButtonTheme: OutlinedButtonThemeData(style: outlinedButtonStyle),
      cardTheme: cardTheme,
      inputDecorationTheme: inputDecorationTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.fredoka(
          fontSize: 22,
          color: Colors.white,
          fontWeight: FontWeight.normal,
        ),
      ),
      tabBarTheme: const TabBarTheme(
        labelColor: primaryColor,
        unselectedLabelColor: textSecondaryLight,
        indicatorColor: primaryColor,
        labelStyle: TextStyle(fontWeight: FontWeight.bold),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceColorLight,
        selectedItemColor: primaryColor,
        unselectedItemColor: textSecondaryLight,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: textColorLight,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 6,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryColor,
        inactiveTrackColor: primaryColor.withOpacity(0.2),
        thumbColor: primaryColor,
        overlayColor: primaryColor.withOpacity(0.2),
        trackHeight: 6,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return textSecondaryLight;
        }),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return Colors.grey.shade400;
        }),
        trackColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor.withOpacity(0.4);
          }
          return Colors.grey.shade300;
        }),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryColor,
      ),
      dividerTheme: const DividerThemeData(
        color: canvasBorderColor,
        thickness: 1,
        space: 24,
      ),
      dialogTheme: DialogTheme(
        backgroundColor: surfaceColorLight,
        elevation: 16,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: textColorLight.withOpacity(0.9),
          borderRadius: BorderRadius.circular(10),
        ),
        textStyle: const TextStyle(color: Colors.white),
      ),
    );
  }

  // Dark theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: accentColor,
        surface: surfaceColorDark,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textColorDark,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: backgroundColorDark,
      fontFamily: GoogleFonts.comicNeue().fontFamily,
      textTheme: GoogleFonts.comicNeueTextTheme(
        ThemeData.dark().textTheme.copyWith(
          displayLarge: GoogleFonts.fredoka(
            color: textColorDark,
            fontSize: 32,
            fontWeight: FontWeight.normal,
          ),
          displayMedium: GoogleFonts.fredoka(
            color: textColorDark,
            fontSize: 28,
            fontWeight: FontWeight.normal,
          ),
          displaySmall: GoogleFonts.fredoka(
            color: textColorDark,
            fontSize: 24,
            fontWeight: FontWeight.normal,
          ),
          headlineMedium: GoogleFonts.fredoka(
            color: textColorDark,
            fontSize: 20,
            fontWeight: FontWeight.normal,
          ),
          titleLarge: GoogleFonts.fredoka(
            color: textColorDark,
            fontSize: 18,
            fontWeight: FontWeight.normal,
          ),
          bodyLarge: const TextStyle(color: textColorDark, fontSize: 16),
          bodyMedium: const TextStyle(color: textColorDark, fontSize: 14),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(style: primaryButtonStyle),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: primaryColor, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: GoogleFonts.fredoka(
            fontSize: 18,
            fontWeight: FontWeight.normal,
          ),
        ),
      ),
      cardTheme: CardTheme(
        color: surfaceColorDark,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: BorderSide(color: primaryColor.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: BorderSide(color: primaryColor.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: const BorderSide(color: errorColor),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        filled: true,
        fillColor: surfaceColorDark,
        labelStyle: TextStyle(color: textColorDark.withOpacity(0.7)),
        hintStyle: TextStyle(color: textColorDark.withOpacity(0.5)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.fredoka(
          fontSize: 22,
          color: Colors.white,
          fontWeight: FontWeight.normal,
        ),
      ),
      tabBarTheme: const TabBarTheme(
        labelColor: primaryColor,
        unselectedLabelColor: textSecondaryDark,
        indicatorColor: primaryColor,
        labelStyle: TextStyle(fontWeight: FontWeight.bold),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceColorDark,
        selectedItemColor: primaryColor,
        unselectedItemColor: textSecondaryDark,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: surfaceColorDark,
        contentTextStyle: const TextStyle(color: textColorDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryColor,
        inactiveTrackColor: primaryColor.withOpacity(0.2),
        thumbColor: primaryColor,
        overlayColor: primaryColor.withOpacity(0.2),
        trackHeight: 6,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return textSecondaryDark;
        }),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return Colors.grey.shade600;
        }),
        trackColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor.withOpacity(0.4);
          }
          return Colors.grey.shade700;
        }),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryColor,
      ),
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade800,
        thickness: 1,
        space: 24,
      ),
      dialogTheme: DialogTheme(
        backgroundColor: surfaceColorDark,
        elevation: 16,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: textColorDark.withOpacity(0.9),
          borderRadius: BorderRadius.circular(10),
        ),
        textStyle: const TextStyle(color: Colors.black),
      ),
    );
  }
}
