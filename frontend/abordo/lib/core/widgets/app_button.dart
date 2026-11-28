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

  /// Rosa oscurito con texto negro (continuar).
  rose,
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
    final enabled = onPressed != null && !loading;

    // Todos los botones, sin excepción: fondo negro con texto e iconos blancos.
    // [kind] se conserva para no tocar las pantallas que ya lo usan.
    final isRose = kind == ButtonKind.rose;
    final Color bg = isRose ? AppColors.pinkDeep : AppColors.ink;
    final Color fg = isRose ? AppColors.ink : Colors.white;
    const side = BorderSide.none;

    final child = loading
        ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.8, color: fg))
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
              Flexible(child: Text(label, textAlign: TextAlign.center)),
            ],
          );

    void tap() {
      HapticFeedback.lightImpact();
      onPressed!();
    }

    // Mientras carga se mantiene el color normal (no el gris de "deshabilitado").
    final VoidCallback? cb = enabled ? tap : (loading ? () {} : null);
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(99), side: side);
    final labelStyle = Theme.of(context).textTheme.labelLarge;

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
