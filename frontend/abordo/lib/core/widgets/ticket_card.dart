import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Tarjeta tipo boleto: dos mitades separadas por una línea punteada con muescas semicirculares
/// recortadas de verdad a los lados (se ve el fondo de la pantalla a través de ellas).
class TicketCard extends StatelessWidget {
  const TicketCard({super.key, required this.top, required this.bottom, this.strip});
  final Widget top;
  final Widget bottom;

  /// Franja gris sobre el boleto (como el "origen ⇄ destino" de la referencia).
  final Widget? strip;

  static const _notch = 12.0;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
        children: [
          if (strip != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              decoration: BoxDecoration(color: p.field, borderRadius: BorderRadius.circular(Dimens.rLg)),
              child: strip,
            ),
            const SizedBox(height: 8),
          ],
          ClipPath(
            clipper: const _TicketClipper(top: true),
            child: Container(
              width: double.infinity,
              color: p.card,
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 20 + _notch),
              child: top,
            ),
          ),
          ClipPath(
            clipper: const _TicketClipper(top: false),
            child: Container(
              width: double.infinity,
              color: p.card,
              padding: const EdgeInsets.fromLTRB(22, _notch + 18, 22, 22),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: -(_notch + 18),
                    child: SizedBox(height: 2, child: CustomPaint(painter: _DashPainter(p.borderStrong))),
                  ),
                  SizedBox(width: double.infinity, child: bottom),
                ],
              ),
            ),
          ),
        ],
    );
  }
}

class _TicketClipper extends CustomClipper<Path> {
  const _TicketClipper({required this.top});
  final bool top;

  @override
  Path getClip(Size size) {
    const r = Dimens.rLg;
    const n = TicketCard._notch;
    final rect = top
        ? RRect.fromRectAndCorners(Offset.zero & size, topLeft: const Radius.circular(r), topRight: const Radius.circular(r))
        : RRect.fromRectAndCorners(Offset.zero & size, bottomLeft: const Radius.circular(r), bottomRight: const Radius.circular(r));
    final shape = Path()..addRRect(rect);
    final y = top ? size.height : 0.0;
    final holes = Path()
      ..addOval(Rect.fromCircle(center: Offset(0, y), radius: n))
      ..addOval(Rect.fromCircle(center: Offset(size.width, y), radius: n));
    return Path.combine(PathOperation.difference, shape, holes);
  }

  @override
  bool shouldReclip(_TicketClipper old) => old.top != top;
}

class _DashPainter extends CustomPainter {
  const _DashPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var x = TicketCard._notch; x < size.width - TicketCard._notch; x += 12) {
      canvas.drawLine(Offset(x, 1), Offset(x + 6, 1), p);
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => old.color != color;
}
