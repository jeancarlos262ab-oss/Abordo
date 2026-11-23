import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/motion.dart';

/// Esquinas rosas tipo visor + línea de escaneo animada. Enmarca un QR (o la cámara).
class ScanFrame extends StatefulWidget {
  const ScanFrame({super.key, this.child, this.size, this.scanning = true});
  final Widget? child;
  final double? size;
  final bool scanning;

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
      foregroundPainter: _FramePainter(_c, widget.scanning),
      child: Padding(padding: const EdgeInsets.all(14), child: widget.child),
    );
    return widget.size == null ? frame : SizedBox(width: widget.size, height: widget.size, child: frame);
  }
}

class _FramePainter extends CustomPainter {
  _FramePainter(this.t, this.scanning) : super(repaint: t);
  final Animation<double> t;
  final bool scanning;

  @override
  void paint(Canvas canvas, Size size) {
    const len = 34.0;
        final p = Paint()
      ..color = AppColors.pink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.butt;
    final w = size.width, h = size.height;
    Path corner(double x, double y, double dx, double dy) => Path()
      ..moveTo(x, y + dy * len)
      ..lineTo(x, y)
      ..lineTo(x + dx * len, y);
    canvas
      ..drawPath(corner(0, 0, 1, 1), p)
      ..drawPath(corner(w, 0, -1, 1), p)
      ..drawPath(corner(0, h, 1, -1), p)
      ..drawPath(corner(w, h, -1, -1), p);
    if (scanning) {
      final y = 12 + (h - 24) * t.value;
      canvas.drawRect(
        Rect.fromLTWH(10, y - 1.5, w - 20, 3),
        Paint()..color = AppColors.pink,
      );
    }
  }

  @override
  bool shouldRepaint(_FramePainter old) => old.scanning != scanning;
}
