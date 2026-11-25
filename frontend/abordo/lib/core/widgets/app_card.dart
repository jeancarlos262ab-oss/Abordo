import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Contenedor base de la app: superficie redondeada con borde fino y sombra suave.
/// Si recibe `onTap` se vuelve un botón accesible con ripple.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(18),
    this.color,
    this.radius = Dimens.rLg,
    this.shadow = true,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final double radius;
  final bool shadow;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = BorderRadius.circular(radius);
    final card = DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? p.card,
        borderRadius: r,
        border: Border.all(color: p.border),
        boxShadow: shadow ? p.cardShadow : const [],
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: r,
        clipBehavior: Clip.antiAlias,
        child: InkWell(onTap: onTap, borderRadius: r, child: Padding(padding: padding, child: child)),
      ),
    );
    return onTap == null && semanticLabel == null
        ? card
        : Semantics(button: onTap != null, label: semanticLabel, container: true, child: card);
  }
}

/// Título de sección sobre fondo de pantalla: pequeño, en mayúsculas y con aire.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.label, {super.key, this.trailing});
  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(label.toUpperCase(), style: text.labelSmall?.copyWith(color: context.palette.muted)),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Baldosa redondeada con un icono dentro. Se usa en filas y encabezados de tarjeta.
class IconTile extends StatelessWidget {
  const IconTile({super.key, required this.icon, this.size = 48, this.background, this.foreground});
  final IconData icon;
  final double size;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: background ?? p.accentSoft, borderRadius: BorderRadius.circular(size * .3)),
        child: Icon(icon, size: size * .5, color: foreground ?? (Theme.of(context).brightness == Brightness.dark ? AppColors.pink : AppColors.ink)),
      ),
    );
  }
}
