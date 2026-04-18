import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  // Mor ve Pembe tonları için yeni renk paleti
  static const _lightBackground = Color(0xFFFDF8FF); // Uçuk pembemsi beyaz arka plan
  static const _softPurple = Color(0xFFE1BEE7); // Kenarlıklar ve yumuşak detaylar
  static const _deepPurple = Color(0xFF6A1B9A); // Ana renk (Primary)
  static const _charcoal = Color(0xFF263238); // Metin rengi
  static const _vibrantPink = Color(0xFFE91E63); // İkincil renk (Secondary)

  static ThemeData get lightTheme {
    final base = ThemeData(
      useMaterial3: false,
      scaffoldBackgroundColor: _lightBackground,
      fontFamily: 'sans-serif',
      colorScheme: const ColorScheme.light(
        primary: _deepPurple,
        secondary: _vibrantPink,
        surface: Colors.white,
      ),
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: _charcoal,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: _softPurple),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: _deepPurple, width: 1.4),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _deepPurple,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _vibrantPink, // Buton pembe olsun, dikkat çeksin
        foregroundColor: Colors.white,
      ),
      textTheme: base.textTheme.copyWith(
        headlineLarge: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: _charcoal,
          height: 1.15,
        ),
        headlineSmall: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: _charcoal,
        ),
        titleLarge: const TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w700,
          color: _charcoal,
        ),
        bodyLarge: const TextStyle(
          fontSize: 16,
          color: _charcoal,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: _charcoal.withValues(alpha: 0.75),
          height: 1.45,
        ),
      ),
    );
  }
}