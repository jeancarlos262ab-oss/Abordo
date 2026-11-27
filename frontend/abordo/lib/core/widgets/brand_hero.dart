import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_icons.dart';

/// Cabecera de marca: rosa pastel de Inter Miami con texto negro. Su contenido usa colores oscuros
/// sobre rosa sin importar el tema del teléfono.
///
/// Por defecto es una cabecera de pantalla (a todo lo ancho, borde inferior recto). Con
/// [panel] = true es una tarjeta rosa redondeada para usar dentro de una pantalla.
class BrandHero extends StatelessWidget {
  const BrandHero({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(Dimens.pagePadding, 0, Dimens.pagePadding, 24),
    this.safeTop = true,
    this.panel = false,
    this.cover = false,
  });

  final Widget child;
  final EdgeInsets padding;
  final bool safeTop;
  final bool panel;

  /// Se conserva por compatibilidad: las cabeceras de pantalla ya no usan la portada (solo el inicio).
  final bool cover;

  @override
  Widget build(BuildContext context) {
    final dark = AppTheme.light;
    final radius = panel
        ? BorderRadius.circular(Dimens.rXl)
        : BorderRadius.zero;

    return Theme(
      data: dark,
      child: DefaultTextStyle(
        style: dark.textTheme.bodyLarge!,
        child: ClipRRect(
          borderRadius: radius,
          child: DecoratedBox(
            decoration: const BoxDecoration(color: AppColors.rose),
            child: Stack(
              children: [
                SafeArea(
                  bottom: false,
                  top: safeTop,
                  child: Padding(
                    padding: padding,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: Dimens.maxContentWidth - 2 * Dimens.pagePadding),
                        child: SizedBox(width: double.infinity, child: child),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Barra superior para pantallas con hero: botón de regreso redondo, título y acciones.
class HeroTopBar extends StatelessWidget {
  const HeroTopBar({super.key, this.title, this.actions, this.showBack = true});
  final String? title;
  final List<Widget>? actions;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final canBack = showBack && Navigator.of(context).canPop();
    const slot = Dimens.minTap;
    final acts = actions ?? const <Widget>[];
    // Regreso a la izquierda, título al centro y acciones a la derecha (mismo ancho a ambos lados).
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          SizedBox(
            width: slot * (acts.isEmpty ? 1 : acts.length),
            child: canBack
                ? Align(alignment: Alignment.centerLeft, child: IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    tooltip: 'Regresar',
                    color: AppColors.ink,
                    style: IconButton.styleFrom(fixedSize: const Size.square(44)),
                    icon: const Icon(AppIcons.back, size: 24),
                  ))
                : null,
          ),
          Expanded(
            child: title == null
                ? const SizedBox.shrink()
                : Semantics(
                    header: true,
                    child: Text(title!, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge, overflow: TextOverflow.ellipsis),
                  ),
          ),
          SizedBox(
            width: slot * (acts.isEmpty ? 1 : acts.length),
            child: Row(mainAxisAlignment: MainAxisAlignment.end, children: acts),
          ),
        ],
      ),
    );
  }
}
