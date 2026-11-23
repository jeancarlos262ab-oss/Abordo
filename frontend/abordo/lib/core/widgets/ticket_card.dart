import 'package:flutter/material.dart';

/// Tarjeta tipo boleto: dos mitades separadas por una línea punteada con muescas a los lados.
class TicketCard extends StatelessWidget {
  const TicketCard({super.key, required this.top, required this.bottom});
  final Widget top;
  final Widget bottom;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const notch = 8.0;
    return Material(
      color: scheme.surfaceContainerHighest,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(),
      child: Column(
        children: [
          Padding(padding: const EdgeInsets.fromLTRB(22, 22, 22, 18), child: SizedBox(width: double.infinity, child: top)),
          SizedBox(
            height: notch * 2,
            child: Stack(
              children: [
                Positioned.fill(left: 22, right: 22, child: Center(child: CustomPaint(size: const Size(double.infinity, 2), painter: _DashPainter(scheme.outline.withOpacity(.6))))),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.fromLTRB(22, 14, 22, 22), child: SizedBox(width: double.infinity, child: bottom)),
        ],
      ),
    );
  }
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
    for (var x = 0.0; x < size.width; x += 12) {
      canvas.drawLine(Offset(x, 1), Offset(x + 6, 1), p);
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => old.color != color;
}
