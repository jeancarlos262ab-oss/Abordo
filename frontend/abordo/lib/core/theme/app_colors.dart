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

  /// Asfalto de la portada (el de la carretera de día).
  static const road = Color(0xFF231F20);

  /// Rosa de Inter Miami (#F7B5CD): botones, iconos activos y acentos. Siempre con texto negro encima.
  static const rose = Color(0xFFF7B5CD); // rosa de Inter Miami
  static const roseLight = Color(0xFFFBD3E2);

  /// Rosa Miami un poco más oscuro, para botones sobre el fondo rosa de las pantallas (se nota la diferencia).
  static const roseButton = Color(0xFFEC96B8);

  static const success = Color(0xFFB4155A); // rosa profundo (antes verde)
  static const danger = Color(0xFF7A0F3A); // rosa vino (antes rojo)

  /// Versiones claras para usar encima de fondos oscuros (hero, snackbars).
  static const successBright = Color(0xFFFF8FB8);
  static const dangerBright = Color(0xFFFF6B9A);
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
    background: Color(0xFFF7B5CD),
    card: Color(0xFFFFFFFF),
    field: Color(0xFFFBD3E2),
    border: Color(0xFFEFC6D6),
    borderStrong: Color(0xFFC9B5BF),
    text: Color(0xFF161314),
    muted: Color(0xFF4A4346),
    success: Color(0xFFB4155A),
    successSoft: Color(0xFFFBD3E2),
    danger: Color(0xFF7A0F3A),
    dangerSoft: Color(0xFFF2A0BE),
    accent: Color(0xFF231F20),
    accentSoft: Color(0xFFFBD3E2),
    switchOff: Color(0xFFC9C2C5),
    shadow: Color(0x1AD94F86),
  );

  static const dark = AppPalette(
    background: Color(0xFF110F10),
    card: Color(0xFF1C1819),
    field: Color(0xFF282324),
    border: Color(0xFF2F292B),
    borderStrong: Color(0xFF6A6164),
    text: Color(0xFFF7F4F5),
    muted: Color(0xFFB3ACAF),
    success: Color(0xFFFF8FB8),
    successSoft: Color(0xFF3A2630),
    danger: Color(0xFFE5407F),
    dangerSoft: Color(0xFF4A1830),
    accent: Color(0xFFF7B5CD),
    accentSoft: Color(0xFF3A2630),
    switchOff: Color(0xFF4A4244),
    shadow: Color(0x00000000),
  );

  /// Borde de los contenedores: tinta al 32 %, igual que las pantallas del dueño (sin relleno blanco).
  Color get outline => text.withOpacity(.32);

  /// Sin sombras: las tarjetas se definen solo con borde.
  List<BoxShadow> get cardShadow => const [];

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
