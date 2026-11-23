import 'package:flutter/material.dart';


/// Contenedor base de la app. Si recibe `onTap` se vuelve un botón accesible.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final body = InkWell(onTap: onTap, child: Padding(padding: padding, child: child));
    final card = Material(
      color: color ?? scheme.surfaceContainerHighest,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(),
      child: body,
    );
    return onTap == null && semanticLabel == null
        ? card
        : Semantics(button: onTap != null, label: semanticLabel, container: true, child: card);
  }
}
