import 'package:flutter/material.dart';

/// Colores de marca (tokens.css de la landing de ABORDO). Son constantes de identidad:
/// no cambian con el tema. Para superficies, textos y estados usa [AppPalette] (`context.palette`).
abstract final class AppColors {
  static const ink = Color(0xFF161314);
  static const ink2 = Color(0xFF231F20);
  static const graphite = Color(0xFF3A3536);
  static const grey = Color(0xFF8A8587);
  static const silver = Color(0xFFDEDBDC);
  static const pink = Color(0xFFF7B5CD);
  static const pinkDeep = Color(0xFFE97FA7);
  static const paper = Color(0xFFF5F3F3);

  static const success = Color(0xFF23915F);
  static const danger = Color(0xFFD64545);

  /// Versiones claras para usar encima de fondos oscuros (hero, snackbars).
  static const successBright = Color(0xFF4CC38A);
  static const dangerBright = Color(0xFFFF8A8A);
}

/// Colores semánticos que sí cambian entre tema claro y oscuro.
/// Se leen con `context.palette`.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.background,
    required this.card,
    required this.field,
    required this.border,
    required this.borderStrong,
    required this.text,
    required this.muted,
    required this.success,
    required this.successSoft,
    required this.danger,
    required this.dangerSoft,
    required this.accent,
    required this.accentSoft,
    required this.switchOff,
    required this.shadow,
  });

  /// Fondo de pantalla.
  final Color background;

  /// Superficie elevada (tarjetas, hojas, diálogos, campos).
  final Color card;

  /// Superficie hundida (pistas de barras, chips neutros, botones secundarios).
  final Color field;

  /// Línea fina de tarjetas y separadores.
  final Color border;

  /// Borde de campos de texto (debe verse con claridad).
  final Color borderStrong;

  final Color text;
  final Color muted;

  final Color success;
  final Color successSoft;
  final Color danger;
  final Color dangerSoft;

  /// Rosa de marca apto para el tema (más profundo en claro).
  final Color accent;
  final Color accentSoft;

  final Color switchOff;
  final Color shadow;

  static const light = AppPalette(
    background: Color(0xFFF6F3F4),
    card: Color(0xFFFFFFFF),
    field: Color(0xFFEFEBEC),
    border: Color(0xFFE7E2E4),
    borderStrong: Color(0xFFB0A9AC),
    text: Color(0xFF161314),
    muted: Color(0xFF655E61),
    success: Color(0xFF157A4D),
    successSoft: Color(0xFFE2F4EA),
    danger: Color(0xFFC62F34),
    dangerSoft: Color(0xFFFCE8E8),
    accent: Color(0xFFE97FA7),
    accentSoft: Color(0xFFFDEAF1),
    switchOff: Color(0xFFC9C2C5),
    shadow: Color(0x14161314),
  );

  static const dark = AppPalette(
    background: Color(0xFF110F10),
    card: Color(0xFF1C1819),
    field: Color(0xFF282324),
    border: Color(0xFF2F292B),
    borderStrong: Color(0xFF6A6164),
    text: Color(0xFFF7F4F5),
    muted: Color(0xFFB3ACAF),
    success: Color(0xFF4CC38A),
    successSoft: Color(0xFF16342A),
    danger: Color(0xFFFF8A8A),
    dangerSoft: Color(0xFF3D1F21),
    accent: Color(0xFFF7B5CD),
    accentSoft: Color(0xFF3A2630),
    switchOff: Color(0xFF4A4244),
    shadow: Color(0x00000000),
  );

  /// Sombra suave de tarjetas (vacía en tema oscuro, donde manda el borde).
  List<BoxShadow> get cardShadow => shadow.alpha == 0
      ? const []
      : [
          BoxShadow(color: shadow, blurRadius: 24, offset: const Offset(0, 8)),
          BoxShadow(color: shadow, blurRadius: 3, offset: const Offset(0, 1)),
        ];

  @override
  AppPalette copyWith({Color? background, Color? card}) => AppPalette(
        background: background ?? this.background,
        card: card ?? this.card,
        field: field,
        border: border,
        borderStrong: borderStrong,
        text: text,
        muted: muted,
        success: success,
        successSoft: successSoft,
        danger: danger,
        dangerSoft: dangerSoft,
        accent: accent,
        accentSoft: accentSoft,
        switchOff: switchOff,
        shadow: shadow,
      );

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      background: l(background, other.background),
      card: l(card, other.card),
      field: l(field, other.field),
      border: l(border, other.border),
      borderStrong: l(borderStrong, other.borderStrong),
      text: l(text, other.text),
      muted: l(muted, other.muted),
      success: l(success, other.success),
      successSoft: l(successSoft, other.successSoft),
      danger: l(danger, other.danger),
      dangerSoft: l(dangerSoft, other.dangerSoft),
      accent: l(accent, other.accent),
      accentSoft: l(accentSoft, other.accentSoft),
      switchOff: l(switchOff, other.switchOff),
      shadow: l(shadow, other.shadow),
    );
  }
}

extension AppPaletteContext on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}
