import 'package:flutter/material.dart';

/// Gráfica de línea suave con relleno plano translúcido y punto final (la del panel de la landing).
/// Sin dependencias externas. Toma el color primario del tema (rosa dentro del hero).
class Sparkline extends StatelessWidget {
  const Sparkline({super.key, required this.values, this.height = 96, this.semanticLabel, this.color});
  final List<double> values;
  final double height;
  final String? semanticLabel;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return Semantics(
      label: semanticLabel,
      image: true,
      child: ExcludeSemantics(
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: CustomPaint(painter: _SparklinePainter(values, c)),
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
    const padX = 6.0;
    const padTop = 10.0;
    const padBottom = 6.0;
    final w = size.width - padX * 2;
    final h = size.height - padTop - padBottom;
    Offset at(int i) => Offset(padX + w * i / (values.length - 1), padTop + h - h * (values[i] / span));

    // Guías horizontales muy tenues.
    final grid = Paint()
      ..color = color.withOpacity(.12)
      ..strokeWidth = 1;
    for (var g = 0; g < 3; g++) {
      final y = padTop + h * g / 2;
      canvas.drawLine(Offset(padX, y), Offset(size.width - padX, y), grid);
    }

    // Curva suave: cada tramo es una cúbica con puntos de control a la mitad.
    final line = Path()..moveTo(at(0).dx, at(0).dy);
    for (var i = 1; i < values.length; i++) {
      final a = at(i - 1);
      final b = at(i);
      final mx = (a.dx + b.dx) / 2;
      line.cubicTo(mx, a.dy, mx, b.dy, b.dx, b.dy);
    }

    final area = Path.from(line)
      ..lineTo(at(values.length - 1).dx, size.height - padBottom)
      ..lineTo(at(0).dx, size.height - padBottom)
      ..close();
    canvas.drawPath(
      area,
      Paint()..color = color.withOpacity(.16),
    );

    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final end = at(values.length - 1);
    canvas
      ..drawCircle(end, 9, Paint()..color = color.withOpacity(.25))
      ..drawCircle(end, 4.5, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_SparklinePainter old) => old.values != values || old.color != color;
}
