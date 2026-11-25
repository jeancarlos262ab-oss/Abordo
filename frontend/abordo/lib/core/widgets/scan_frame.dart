import 'dart:ui' show BlurStyle, MaskFilter;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/motion.dart';

/// Esquinas redondeadas tipo visor + línea de escaneo animada. Enmarca un QR (o la cámara).
class ScanFrame extends StatefulWidget {
  const ScanFrame({super.key, this.child, this.size, this.scanning = true, this.color = AppColors.pink});
  final Widget? child;
  final double? size;
  final bool scanning;
  final Color color;

  @override
  State<ScanFrame> createState() => _ScanFrameState();
}

class _ScanFrameState extends State<ScanFrame> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!widget.scanning || reduceMotion(context)) {
      _c.value = .5;
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final frame = CustomPaint(
      foregroundPainter: _FramePainter(_c, widget.scanning, widget.color),
      child: Padding(padding: const EdgeInsets.all(14), child: widget.child),
    );
    return widget.size == null ? frame : SizedBox(width: widget.size, height: widget.size, child: frame);
  }
}

class _FramePainter extends CustomPainter {
  _FramePainter(this.t, this.scanning, this.color) : super(repaint: t);
  final Animation<double> t;
  final bool scanning;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const len = 38.0;
    const r = 18.0;
    const inset = 3.0;
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final w = size.width - inset;
    final h = size.height - inset;

    // Una esquina redondeada: sale del vértice (x, y) hacia dx/dy.
    Path corner(double x, double y, double dx, double dy) => Path()
      ..moveTo(x, y + dy * len)
      ..lineTo(x, y + dy * r)
      ..quadraticBezierTo(x, y, x + dx * r, y)
      ..lineTo(x + dx * len, y);
    canvas
      ..drawPath(corner(inset, inset, 1, 1), p)
      ..drawPath(corner(w, inset, -1, 1), p)
      ..drawPath(corner(inset, h, 1, -1), p)
      ..drawPath(corner(w, h, -1, -1), p);

    if (scanning) {
      final y = 16 + (size.height - 32) * t.value;
      final line = RRect.fromRectAndRadius(Rect.fromLTWH(18, y - 2, size.width - 36, 4), const Radius.circular(2));
      canvas
        ..drawRRect(line, Paint()..color = color.withOpacity(.45)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6))
        ..drawRRect(line, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_FramePainter old) => old.scanning != scanning || old.color != color;
}
