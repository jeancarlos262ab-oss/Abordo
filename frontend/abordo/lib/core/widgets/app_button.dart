import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

enum ButtonKind { primary, secondary, danger, text }

/// Botón grande y claro: icono + texto, 64 px de alto, vibración leve al tocar.
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
    final enabled = onPressed != null && !loading;
    final shape = const RoundedRectangleBorder();
    const size = Size.fromHeight(Dimens.buttonHeight);

    final child = loading
        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 3))
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 24), const SizedBox(width: 10)],
              Flexible(child: Text(label, textAlign: TextAlign.center)),
            ],
          );

    void tap() {
      HapticFeedback.lightImpact();
      onPressed!();
    }

    final cb = enabled ? tap : null;
    return switch (kind) {
      ButtonKind.primary => FilledButton(
          onPressed: cb,
          style: FilledButton.styleFrom(minimumSize: size, shape: shape, textStyle: Theme.of(context).textTheme.labelLarge),
          child: child,
        ),
      ButtonKind.danger => FilledButton(
          onPressed: cb,
          style: FilledButton.styleFrom(
            minimumSize: size,
            shape: shape,
            backgroundColor: AppColors.danger,
            foregroundColor: Colors.white,
            textStyle: Theme.of(context).textTheme.labelLarge,
          ),
          child: child,
        ),
      ButtonKind.secondary => FilledButton(
          onPressed: cb,
          style: FilledButton.styleFrom(
            minimumSize: size,
            shape: shape,
            backgroundColor: AppColors.graphite,
            foregroundColor: Colors.white,
            textStyle: Theme.of(context).textTheme.labelLarge,
          ),
          child: child,
        ),
      ButtonKind.text => TextButton(
          onPressed: cb,
          style: TextButton.styleFrom(
            minimumSize: const Size.fromHeight(Dimens.minTap),
            foregroundColor: scheme.onSurface,
            textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(decoration: TextDecoration.underline),
          ),
          child: child,
        ),
    };
  }
}
