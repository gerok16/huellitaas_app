
import 'package:flutter/material.dart';

/// Tema global Kawaii de Huellitas 🐾
class AppTheme {
  // Paleta rosa pastel
  static const Color primary = Color(0xFFEC407A);
  static const Color secondary = Color(0xFFCE93D8);
  static const Color background = Color(0xFFFFF8FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color pinkLight = Color(0xFFFCE4EC);
  static const Color pinkSoft = Color(0xFFF8BBD0);
  static const Color lavender = Color(0xFFE1BEE7);
  static const Color textDark = Color(0xFF6D4C5B);
  static const Color textSoft = Color(0xFFAD8295);

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: primary,
      onPrimary: Colors.white,
      secondary: secondary,
      onSecondary: textDark,
      surface: surface,
      onSurface: textDark,
      error: const Color(0xFFE57373),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,

      // Textos generales
      fontFamily: 'Roboto',
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: textDark,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: textDark,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: TextStyle(
          color: textDark,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: TextStyle(
          color: textDark,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: textDark,
          fontSize: 15,
        ),
        bodyMedium: TextStyle(
          color: textSoft,
          fontSize: 14,
        ),
      ),

      // Barra superior
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: textDark,
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: textDark,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: primary),
      ),

      // Botones principales
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          elevation: 2,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),

      // Botones secundarios
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size.fromHeight(50),
          side: const BorderSide(color: pinkSoft, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),

      // Campos de texto
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: pinkLight.withValues(alpha: 0.45),
        hintStyle: const TextStyle(color: textSoft),
        labelStyle: const TextStyle(color: textSoft),
        prefixIconColor: primary,
        suffixIconColor: primary,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 17,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(color: pinkSoft),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(color: primary, width: 1.8),
        ),
      ),

      // Tarjetas
      cardTheme: CardThemeData(
        color: surface,
        elevation: 2,
        shadowColor: pinkSoft.withValues(alpha: 0.35),
        margin: const EdgeInsets.symmetric(vertical: 7, horizontal: 3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: Color(0xFFFFE0EB)),
        ),
      ),

      // Iconos seleccionados
      iconTheme: const IconThemeData(
        color: primary,
        size: 23,
      ),

      // Barra de navegación inferior
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: pinkLight,
        elevation: 5,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: primary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            );
          }
          return const TextStyle(
            color: textSoft,
            fontSize: 12,
          );
        }),
      ),

      // Botón flotante
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),

      // Checkboxes y switches
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? primary
              : Colors.white;
        }),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
        ),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? primary
              : Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? pinkLight
              : Colors.grey.shade200;
        }),
      ),

      dividerTheme: const DividerThemeData(
        color: Color(0xFFF8DDE8),
        thickness: 1,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: textDark,
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
    );
  }
}
