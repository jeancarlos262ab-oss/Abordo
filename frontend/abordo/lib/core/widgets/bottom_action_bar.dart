import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Barra fija al fondo de la pantalla para el botón principal (Continuar, Pagar, Terminar…).
/// Va en `PageScaffold.bottomBar`: no se mueve con el scroll, respeta la zona segura
/// y sube con el teclado para no quedar tapada.
class BottomActionBar extends StatelessWidget {
  const BottomActionBar({super.key, required this.children});

  /// Uno o más botones, de arriba hacia abajo.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Dimens.maxContentWidth),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(Dimens.pagePadding, 8, Dimens.pagePadding, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < children.length; i++) ...[
                    if (i > 0) const SizedBox(height: 10),
                    children[i],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
