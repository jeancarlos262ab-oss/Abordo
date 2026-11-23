import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/motion.dart';

/// Cabecera de marca: degradado grafito→rosa con la línea punteada de "ruta" de la landing.
/// Es el elemento memorable de la app; todo lo demás se mantiene sobrio.
/// Su contenido siempre usa el tema oscuro, sin importar el del teléfono.
class BrandHero extends StatelessWidget {
  const BrandHero({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(Dimens.pagePadding, 4, Dimens.pagePadding, 22),
    this.safeTop = true,
  });

  final Widget child;
  final EdgeInsets padding;
  final bool safeTop;

  @override
  Widget build(BuildContext context) {
    final dark = AppTheme.dark;
    return Theme(
      data: dark,
      child: DefaultTextStyle(
        style: dark.textTheme.bodyLarge!,
        child: ColoredBox(
          color: AppColors.graphite,
          child: ClipRect(
            child: Stack(
              children: [
                const Positioned.fill(child: RouteLine()),
                SafeArea(bottom: false, top: safeTop, child: Padding(padding: padding, child: child)),
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
      height: 52,
      child: Row(
        children: [
          if (canBack) ...[
            IconButton.filled(
              onPressed: () => Navigator.of(context).maybePop(),
              tooltip: 'Regresar',
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(.14),
                foregroundColor: Colors.white,
                minimumSize: const Size.square(Dimens.minTap - 6),
              ),
              icon: const Icon(Icons.arrow_back_rounded, size: 24),
            ),
            const SizedBox(width: 12),
          ],
          if (title != null) Expanded(child: Text(title!, style: Theme.of(context).textTheme.titleLarge, overflow: TextOverflow.ellipsis)) else const Spacer(),
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

  static const _dash = 4.0;
  static const _gap = 14.0;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 800;
    final sy = size.height / 300;
    final path = Path()
      ..moveTo(-20 * sx, 240 * sy)
      ..cubicTo(150 * sx, 60 * sy, 300 * sx, 300 * sy, 460 * sx, 140 * sy)
      ..cubicTo(620 * sx, -20 * sy, 700 * sx, 60 * sy, 840 * sx, 120 * sy);
    final paint = Paint()
      ..color = AppColors.pink.withOpacity(.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.butt;

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
