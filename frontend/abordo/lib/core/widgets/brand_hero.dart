import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/motion.dart';

/// Cabecera de marca: tinta con un resplandor rosa y la línea punteada de "ruta" de la landing.
/// Es el elemento memorable de la app; todo lo demás se mantiene sobrio.
/// Su contenido siempre usa el tema oscuro, sin importar el del teléfono.
///
/// Por defecto es una cabecera de pantalla (esquinas inferiores redondeadas). Con
/// [panel] = true es una tarjeta oscura redondeada para usar dentro de una pantalla.
class BrandHero extends StatelessWidget {
  const BrandHero({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(Dimens.pagePadding, 4, Dimens.pagePadding, 28),
    this.safeTop = true,
    this.panel = false,
  });

  final Widget child;
  final EdgeInsets padding;
  final bool safeTop;
  final bool panel;

  @override
  Widget build(BuildContext context) {
    final dark = AppTheme.dark;
    final radius = panel
        ? BorderRadius.circular(Dimens.rXl)
        : const BorderRadius.vertical(bottom: Radius.circular(Dimens.rXl + 8));

    return Theme(
      data: dark,
      child: DefaultTextStyle(
        style: dark.textTheme.bodyLarge!,
        child: ClipRRect(
          borderRadius: radius,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2E2527), AppColors.ink],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -110,
                  right: -80,
                  child: IgnorePointer(
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [AppColors.pink.withOpacity(.34), AppColors.pink.withOpacity(0)]),
                      ),
                    ),
                  ),
                ),
                const Positioned.fill(child: RouteLine()),
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
    return SizedBox(
      height: 60,
      child: Row(
        children: [
          if (canBack) ...[
            IconButton.filled(
              onPressed: () => Navigator.of(context).maybePop(),
              tooltip: 'Regresar',
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(.14),
                foregroundColor: Colors.white,
                fixedSize: const Size.square(Dimens.minTap - 2),
              ),
              icon: const Icon(Icons.arrow_back_rounded, size: 24),
            ),
            const SizedBox(width: 12),
          ],
          if (title != null)
            Expanded(
              child: Semantics(
                header: true,
                child: Text(title!, style: Theme.of(context).textTheme.titleLarge, overflow: TextOverflow.ellipsis),
              ),
            )
          else
            const Spacer(),
          ...?actions,
        ],
      ),
    );
  }
}

/// La ruta punteada de la landing (`M-20 240 C 150 60 …`), con los guiones avanzando despacio.
class RouteLine extends StatefulWidget {
  const RouteLine({super.key});

  @override
  State<RouteLine> createState() => _RouteLineState();
}

class _RouteLineState extends State<RouteLine> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 3));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduceMotion(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: ExcludeSemantics(child: CustomPaint(painter: _RoutePainter(_c))),
      );
}

class _RoutePainter extends CustomPainter {
  _RoutePainter(this.t) : super(repaint: t);
  final Animation<double> t;

  static const _dash = 5.0;
  static const _gap = 15.0;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 800;
    final sy = size.height / 300;
    final path = Path()
      ..moveTo(-20 * sx, 240 * sy)
      ..cubicTo(150 * sx, 60 * sy, 300 * sx, 300 * sy, 460 * sx, 140 * sy)
      ..cubicTo(620 * sx, -20 * sy, 700 * sx, 60 * sy, 840 * sx, 120 * sy);
    final paint = Paint()
      ..color = AppColors.pink.withOpacity(.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    const period = _dash + _gap;
    for (final m in path.computeMetrics()) {
      for (var d = -period + t.value * period; d < m.length; d += period) {
        final start = math.max(d, 0.0);
        final end = math.min(d + _dash, m.length);
        if (end > start) canvas.drawPath(m.extractPath(start, end), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_RoutePainter old) => false;
}
