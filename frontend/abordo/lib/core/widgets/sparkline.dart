import 'package:flutter/material.dart';

/// Gráfica de línea mínima (la del panel de la landing). Sin dependencias externas.
class Sparkline extends StatelessWidget {
  const Sparkline({super.key, required this.values, this.height = 90, this.semanticLabel});
  final List<double> values;
  final double height;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Semantics(
      label: semanticLabel,
      image: true,
      child: ExcludeSemantics(
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: CustomPaint(painter: _SparklinePainter(values, color)),
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter(this.values, this.color);
  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final span = maxV <= 0 ? 1.0 : maxV;
    const pad = 4.0;
    Offset at(int i) => Offset(
          pad + (size.width - pad * 2) * i / (values.length - 1),
          size.height - pad - (size.height - pad * 2) * (values[i] / span),
        );

    final line = Path()..moveTo(at(0).dx, at(0).dy);
    for (var i = 1; i < values.length; i++) {
      line.lineTo(at(i).dx, at(i).dy);
    }
    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.butt
        ..strokeJoin = StrokeJoin.miter,
    );
  }

  @override
  bool shouldRepaint(_SparklinePainter old) => old.values != values || old.color != color;
}
