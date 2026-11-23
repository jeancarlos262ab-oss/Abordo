import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Medidas compartidas. Pensadas para dedos grandes y poca precisión (personas mayores).
abstract final class Dimens {
  static const pagePadding = 18.0;
  static const maxContentWidth = 560.0;
  static const buttonHeight = 52.0;
  static const radius = 0.0; // diseño de esquinas rectas
  static const gap = 14.0;
  static const minTap = 48.0;
}

abstract final class AppTheme {
  static final ThemeData dark = _build(
        const ColorScheme(
          brightness: Brightness.dark,
          primary: AppColors.pink,
          onPrimary: AppColors.ink,
          secondary: AppColors.silver,
          onSecondary: AppColors.ink,
          error: Color(0xFFFF8A8A),
          onError: AppColors.ink,
          surface: AppColors.ink,
          onSurface: Colors.white,
          surfaceContainerHighest: Color(0xFF2B2627),
          onSurfaceVariant: AppColors.silver,
          outline: AppColors.grey,
        ),
      );

  static ThemeData _build(ColorScheme scheme) {
    final body = GoogleFonts.redHatTextTextTheme();
    final display = GoogleFonts.redHatDisplay;
    final text = body
        .copyWith(
          displaySmall: display(fontSize: 34, fontWeight: FontWeight.w900, height: 1.1),
          headlineMedium: display(fontSize: 26, fontWeight: FontWeight.w900, height: 1.15),
          headlineSmall: display(fontSize: 21, fontWeight: FontWeight.w800, height: 1.2),
          titleLarge: display(fontSize: 19, fontWeight: FontWeight.w800),
          titleMedium: body.titleMedium?.copyWith(fontSize: 17, fontWeight: FontWeight.w700),
          bodyLarge: body.bodyLarge?.copyWith(fontSize: 17, height: 1.4),
          bodyMedium: body.bodyMedium?.copyWith(fontSize: 15, height: 1.4),
          bodySmall: body.bodySmall?.copyWith(fontSize: 13, height: 1.4),
          labelLarge: body.labelLarge?.copyWith(fontSize: 17, fontWeight: FontWeight.w700),
        )
        .apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);

    const none = InputBorder.none;
    const square = RoundedRectangleBorder();
    final squareButton = ButtonStyle(shape: WidgetStateProperty.all(square));

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: text,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
        toolbarHeight: 56,
      ),
      // Campos sólidos, sin borde: el color de relleno cambia al enfocar.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.graphite,
        focusColor: const Color(0xFF5B4A51),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: none,
        enabledBorder: none,
        focusedBorder: none,
        errorBorder: none,
        focusedErrorBorder: none,
        hintStyle: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
        errorStyle: text.bodyMedium?.copyWith(color: scheme.error, fontWeight: FontWeight.w600),
      ),
      filledButtonTheme: FilledButtonThemeData(style: squareButton),
      textButtonTheme: TextButtonThemeData(style: squareButton),
      iconButtonTheme: IconButtonThemeData(style: squareButton),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(shape: square, elevation: 0),
      bottomSheetTheme: const BottomSheetThemeData(shape: square, showDragHandle: false),
      expansionTileTheme: const ExpansionTileThemeData(shape: Border(), collapsedShape: Border()),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        backgroundColor: scheme.surfaceContainerHighest,
        indicatorColor: scheme.primary,
        indicatorShape: square,
        labelTextStyle: WidgetStatePropertyAll(text.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(size: 26, color: s.contains(WidgetState.selected) ? scheme.onPrimary : scheme.onSurfaceVariant),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        shape: square,
        behavior: SnackBarBehavior.floating,
        contentTextStyle: text.bodyLarge?.copyWith(color: scheme.surface),
        backgroundColor: scheme.onSurface,
      ),
      dividerColor: scheme.outline.withOpacity(.3),
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );
  }
}
