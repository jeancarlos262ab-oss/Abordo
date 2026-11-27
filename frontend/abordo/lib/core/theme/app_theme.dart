import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'page_transitions.dart';

/// Medidas compartidas. Pensadas para dedos grandes y poca precisión (personas mayores):
/// botones de 56 px, objetivos táctiles de al menos 48 px y mucho aire entre elementos.
abstract final class Dimens {
  static const pagePadding = 20.0;
  static const maxContentWidth = 560.0;
  static const buttonHeight = 52.0;
  static const heroOverlap = 44.0;
  static const gap = 12.0;
  static const minTap = 48.0;

  // Escala de radios.
  static const rSm = 12.0;
  static const rMd = 16.0;
  static const rLg = 22.0;
  static const rXl = 28.0;
}

/// Cifras con ancho fijo: los montos no "bailan" al cambiar.
TextStyle tabular(TextStyle? style) =>
    (style ?? const TextStyle()).copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

abstract final class AppTheme {
  static final ThemeData light = _build(Brightness.light);
  static final ThemeData dark = _build(Brightness.dark);

  static TextTheme _textTheme(Color color) {
    TextStyle f(double size, FontWeight weight, {double? height, double? spacing, bool tnum = false}) => GoogleFonts.plusJakartaSans(
          fontSize: size,
          fontWeight: weight,
          height: height,
          letterSpacing: spacing,
          color: color,
          fontFeatures: tnum ? const [FontFeature.tabularFigures()] : null,
        );

    return TextTheme(
      displayLarge: f(40, FontWeight.w800, height: 1.08, spacing: -1.0, tnum: true),
      displayMedium: f(32, FontWeight.w800, height: 1.1, spacing: -.8, tnum: true),
      displaySmall: f(26, FontWeight.w800, height: 1.15, spacing: -.5, tnum: true),
      headlineLarge: f(24, FontWeight.w800, height: 1.2, spacing: -.4),
      headlineMedium: f(22, FontWeight.w800, height: 1.2, spacing: -.3),
      headlineSmall: f(18, FontWeight.w700, height: 1.25, spacing: -.2),
      titleLarge: f(16, FontWeight.w700, height: 1.3),
      titleMedium: f(14, FontWeight.w600, height: 1.35),
      titleSmall: f(13, FontWeight.w600, height: 1.35),
      bodyLarge: f(14, FontWeight.w400, height: 1.4),
      bodyMedium: f(13, FontWeight.w400, height: 1.4),
      bodySmall: f(12, FontWeight.w400, height: 1.35),
      labelLarge: f(14, FontWeight.w700, height: 1.2),
      labelMedium: f(12, FontWeight.w700, height: 1.2),
      labelSmall: f(10.5, FontWeight.w700, height: 1.2, spacing: .8),
    );
  }

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final p = isDark ? AppPalette.dark : AppPalette.light;

    // La acción principal es el rosa de Inter Miami con texto negro, en claro y en oscuro.
    final primary = isDark ? AppColors.rose : AppColors.roseButton;
    const onPrimary = AppColors.ink;

    final scheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: p.accentSoft,
      onPrimaryContainer: p.text,
      secondary: AppColors.pink,
      onSecondary: AppColors.ink,
      secondaryContainer: p.accentSoft,
      onSecondaryContainer: p.text,
      error: p.danger,
      onError: isDark ? AppColors.ink : Colors.white,
      errorContainer: p.dangerSoft,
      onErrorContainer: p.danger,
      surface: p.card,
      onSurface: p.text,
      onSurfaceVariant: p.muted,
      outline: p.borderStrong,
      outlineVariant: p.border,
      surfaceContainerHighest: p.field,
      inverseSurface: AppColors.ink,
      onInverseSurface: Colors.white,
    );

    final text = _textTheme(p.text);

    OutlineInputBorder outline(Color color, [double width = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(Dimens.rMd),
          borderSide: BorderSide(color: color, width: width),
        );

    final buttonShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimens.rMd));

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.background,
      canvasColor: p.background,
      textTheme: text,
      extensions: <ThemeExtension<dynamic>>[p],
      splashFactory: InkRipple.splashFactory,
      pageTransitionsTheme: pageTransitions,
      shadowColor: Colors.transparent,
      cardTheme: const CardThemeData(elevation: 0, shadowColor: Colors.transparent, surfaceTintColor: Colors.transparent),
      dialogTheme: DialogThemeData(backgroundColor: p.background, elevation: 0, shadowColor: Colors.transparent, surfaceTintColor: Colors.transparent),
      popupMenuTheme: PopupMenuThemeData(color: p.background, elevation: 0, shadowColor: Colors.transparent, surfaceTintColor: Colors.transparent),
      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        foregroundColor: p.text,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: text.headlineSmall,
        toolbarHeight: 60,
      ),
      // Campos claros y definidos: relleno de tarjeta, borde visible y foco marcado.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.text.withOpacity(.06),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: outline(p.text.withOpacity(.3)),
        enabledBorder: outline(p.text.withOpacity(.3)),
        focusedBorder: outline(isDark ? AppColors.pink : AppColors.ink, 1.5),
        errorBorder: outline(p.danger),
        focusedErrorBorder: outline(p.danger, 1.5),
        hintStyle: text.bodyLarge?.copyWith(color: p.muted.withOpacity(.75)),
        errorStyle: text.titleSmall?.copyWith(color: p.danger),
        errorMaxLines: 3,
        prefixIconColor: p.muted,
        suffixIconColor: p.muted,
      ),
      filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(shape: buttonShape)),
      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(shape: buttonShape)),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        backgroundColor: AppColors.roseButton,
        foregroundColor: AppColors.ink,
        shape: const CircleBorder(),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.background,
        modalBackgroundColor: p.background,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: p.borderStrong,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(Dimens.rXl))),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        elevation: 0,
        backgroundColor: p.card,
        surfaceTintColor: Colors.transparent,
        indicatorColor: p.accentSoft,
        indicatorShape: const StadiumBorder(),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => text.labelMedium?.copyWith(color: s.contains(WidgetState.selected) ? p.text : p.muted),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(size: 24, color: s.contains(WidgetState.selected) ? (isDark ? AppColors.pink : AppColors.ink) : p.muted),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? const Color(0xFF332D2F) : AppColors.ink,
        contentTextStyle: text.bodyLarge?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimens.rMd)),
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(Colors.white),
        trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? AppColors.success : p.switchOff),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: isDark ? AppColors.pink : AppColors.ink),
      dividerTheme: DividerThemeData(color: p.border, thickness: 1, space: 1),
      textSelectionTheme: TextSelectionThemeData(cursorColor: isDark ? AppColors.pink : AppColors.ink, selectionHandleColor: AppColors.pinkDeep),
      listTileTheme: const ListTileThemeData(contentPadding: EdgeInsets.zero),
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );
  }
}
