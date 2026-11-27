import 'package:flutter/material.dart';

/// Transición global entre pantallas: la nueva entra deslizándose desde la derecha y la
/// anterior se desplaza un poco hacia la izquierda. Al volver, el movimiento se invierte.
class SlideRightPageTransitionsBuilder extends PageTransitionsBuilder {
  const SlideRightPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    const curve = Curves.easeOutCubic;
    final enter = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: animation, curve: curve, reverseCurve: Curves.easeInCubic));
    final leave = Tween<Offset>(begin: Offset.zero, end: const Offset(-.25, 0))
        .animate(CurvedAnimation(parent: secondaryAnimation, curve: curve, reverseCurve: Curves.easeInCubic));
    return SlideTransition(position: leave, child: SlideTransition(position: enter, child: child));
  }
}

const pageTransitions = PageTransitionsTheme(builders: {
  TargetPlatform.android: SlideRightPageTransitionsBuilder(),
  TargetPlatform.iOS: SlideRightPageTransitionsBuilder(),
  TargetPlatform.macOS: SlideRightPageTransitionsBuilder(),
  TargetPlatform.windows: SlideRightPageTransitionsBuilder(),
  TargetPlatform.linux: SlideRightPageTransitionsBuilder(),
  TargetPlatform.fuchsia: SlideRightPageTransitionsBuilder(),
});
