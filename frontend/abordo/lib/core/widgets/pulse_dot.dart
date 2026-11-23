import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/motion.dart';

/// Punto "en vivo" con un halo que se expande.
class PulseDot extends StatefulWidget {
  const PulseDot({super.key, this.color = AppColors.pink, this.size = 12});
  final Color color;
  final double size;

  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduceMotion(context)) {
      _c.value = 0;
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
  Widget build(BuildContext context) {
    final s = widget.size;
    return ExcludeSemantics(
      child: SizedBox(
        width: s * 2.4,
        height: s * 2.4,
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, __) => Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: s + s * 1.4 * _c.value,
                height: s + s * 1.4 * _c.value,
                decoration: BoxDecoration(color: widget.color.withOpacity(.45 * (1 - _c.value))),
              ),
              Container(width: s, height: s, decoration: BoxDecoration(color: widget.color)),
            ],
          ),
        ),
      ),
    );
  }
}
