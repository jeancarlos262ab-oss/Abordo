import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../theme/app_colors.dart';
import '../utils/motion.dart';

/// QR de adorno (generado con la librería `qr_flutter`) con la línea de escaneo de la landing.
/// Su contenido es solo de muestra: no cobra nada.
class QrMark extends StatefulWidget {
  const QrMark({
    super.key,
    this.size = 120,
    this.background = Colors.white,
    this.foreground = AppColors.ink,
    this.line = AppColors.pinkDeep,
  });
  final double size;
  final Color background;
  final Color foreground;
  final Color line;

  @override
  State<QrMark> createState() => _QrMarkState();
}

class _QrMarkState extends State<QrMark> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduceMotion(context)) {
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
    final pad = widget.size * .1;
    return ExcludeSemantics(
      child: Container(
        width: widget.size,
        height: widget.size,
        padding: EdgeInsets.all(pad),
        decoration: BoxDecoration(
          color: widget.background,
          borderRadius: BorderRadius.circular(widget.size * .2),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            QrImageView(
              data: 'ABORDO · pasaje con CoDi',
              padding: EdgeInsets.zero,
              backgroundColor: widget.background,
              eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.circle, color: widget.foreground),
              dataModuleStyle: QrDataModuleStyle(dataModuleShape: QrDataModuleShape.circle, color: widget.foreground),
            ),
            AnimatedBuilder(
              animation: _c,
              builder: (_, __) => Align(
                alignment: Alignment(0, -1 + 2 * _c.value),
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: widget.line,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [BoxShadow(color: widget.line.withOpacity(.6), blurRadius: 8)],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
