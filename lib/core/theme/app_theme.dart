import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomColors extends ThemeExtension<CustomColors> {
  final Color? success;
  final Color? warning;

  const CustomColors({
    this.success,
    this.warning,
  });

  @override
  ThemeExtension<CustomColors> copyWith({Color? success, Color? warning}) {
    return CustomColors(
      success: success ?? this.success,
      warning: warning ?? this.warning,
    );
  }

  @override
  ThemeExtension<CustomColors> lerp(
      covariant ThemeExtension<CustomColors>? other, double t) {
    if (other is! CustomColors) {
      return this;
    }
    return CustomColors(
      success: Color.lerp(success, other.success, t),
      warning: Color.lerp(warning, other.warning, t),
    );
  }
}

final ColorScheme _coraColorScheme = ColorScheme.fromSeed(
  seedColor: const Color(0xFF00C8FF),
  brightness: Brightness.dark,
).copyWith(
  surface: const Color(0xFF0B132B), // Deep space blue for backgrounds
  error: const Color(0xFFFF4C4C), // Brighter red for error/destructive in dark mode
);

final ThemeData coraTheme = ThemeData(
  useMaterial3: true,
  colorScheme: _coraColorScheme,
  scaffoldBackgroundColor: const Color(0xFF0B132B),
  cardTheme: CardThemeData(
    color: const Color(0xFF1C2541), // Slightly lighter blue-grey for cards
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  extensions: const <ThemeExtension<dynamic>>[
    CustomColors(
      success: Color(0xFF00E676),
      warning: Color(0xFFFFC107),
    ),
  ],
  textTheme: TextTheme(
    headlineMedium: GoogleFonts.rajdhani(fontSize: 20, fontWeight: FontWeight.bold),
    titleMedium: GoogleFonts.rajdhani(fontSize: 16, fontWeight: FontWeight.w600),
    bodyMedium: GoogleFonts.roboto(fontSize: 14),
    labelSmall: GoogleFonts.robotoMono(fontSize: 11),
  ),
);
