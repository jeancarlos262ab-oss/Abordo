import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

enum ButtonKind {
  /// Acción principal: tinta en claro, rosa en oscuro.
  primary,

  /// Acción secundaria: superficie neutra con borde.
  secondary,

  /// Acción destructiva con énfasis (confirmaciones).
  danger,

  /// Acción destructiva discreta (fondo rojo suave).
  dangerSoft,

  /// Enlace-botón sin fondo.
  text,
}

/// Botón grande y claro: icono + texto, 56 px de alto, vibración leve al tocar.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.kind = ButtonKind.primary,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final ButtonKind kind;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final p = context.palette;
    final enabled = onPressed != null && !loading;

    late final Color bg;
    late final Color fg;
    var side = BorderSide.none;
    switch (kind) {
      case ButtonKind.primary:
        bg = scheme.primary;
        fg = scheme.onPrimary;
      case ButtonKind.secondary:
        bg = p.card;
        fg = p.text;
        side = BorderSide(color: p.borderStrong, width: 1.5);
      case ButtonKind.danger:
        bg = p.danger;
        fg = scheme.onError;
      case ButtonKind.dangerSoft:
        bg = p.dangerSoft;
        fg = p.danger;
      case ButtonKind.text:
        bg = Colors.transparent;
        fg = p.text;
    }

    final child = loading
        ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.8, color: fg))
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 22), const SizedBox(width: 10)],
              Flexible(child: Text(label, textAlign: TextAlign.center)),
            ],
          );

    void tap() {
      HapticFeedback.lightImpact();
      onPressed!();
    }

    // Mientras carga se mantiene el color normal (no el gris de "deshabilitado").
    final VoidCallback? cb = enabled ? tap : (loading ? () {} : null);
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimens.rMd), side: side);
    final labelStyle = Theme.of(context).textTheme.labelLarge;

    if (kind == ButtonKind.text) {
      return TextButton(
        onPressed: cb,
        style: TextButton.styleFrom(
          minimumSize: const Size.fromHeight(Dimens.minTap),
          foregroundColor: fg,
          textStyle: labelStyle,
        ),
        child: child,
      );
    }

    return FilledButton(
      onPressed: cb,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(Dimens.buttonHeight),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        backgroundColor: bg,
        foregroundColor: fg,
        disabledBackgroundColor: bg.withOpacity(.38),
        disabledForegroundColor: fg.withOpacity(.6),
        elevation: 0,
        shape: shape,
        textStyle: labelStyle,
      ),
      child: child,
    );
  }
}
