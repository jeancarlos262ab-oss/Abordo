import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../theme/app_colors.dart';
import '../utils/motion.dart';

/// QR de adorno (generado con la librería `qr_flutter`) con la línea de escaneo de la landing.
/// Su contenido es solo de muestra: no cobra nada.
class QrMark extends StatefulWidget {
  const QrMark({super.key, this.size = 120});
  final double size;

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
    final pad = widget.size * .09;
    return ExcludeSemantics(
      child: Container(
        width: widget.size,
        height: widget.size,
        padding: EdgeInsets.all(pad),
        decoration: BoxDecoration(
          color: AppColors.pink,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            QrImageView(
              data: 'ABORDO · pasaje con CoDi',
              padding: EdgeInsets.zero,
              backgroundColor: AppColors.pink,
              eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppColors.ink),
              dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: AppColors.ink),
            ),
            AnimatedBuilder(
              animation: _c,
              builder: (_, __) => Align(
                alignment: Alignment(0, -1 + 2 * _c.value),
                child: Container(height: 3, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
