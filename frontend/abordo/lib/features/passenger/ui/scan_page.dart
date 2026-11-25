import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/unit_code.dart';
import '../../../core/widgets/scan_frame.dart';
import '../../../core/widgets/state_views.dart';

/// Cámara a pantalla completa que lee el QR fijo de la unidad y regresa su código con `Navigator.pop`.
/// Un velo oscuro con ventana redondeada guía la vista hacia el recuadro.
class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  static const _side = 252.0;
  static const _align = -.25; // el visor queda un poco arriba del centro

  final _controller = MobileScannerController(formats: const [BarcodeFormat.qrCode], facing: CameraFacing.back);
  bool _handled = false;
  bool _invalid = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    for (final b in capture.barcodes) {
      final code = UnitCode.parse(b.rawValue ?? '');
      if (code != null) {
        _handled = true;
        HapticFeedback.mediumImpact();
        Navigator.of(context).pop(code);
        return;
      }
    }
    if (!_invalid) setState(() => _invalid = true);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: Colors.black,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Stack(
          fit: StackFit.expand,
          children: [
            MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
              errorBuilder: (context, error, child) => Theme(
                data: AppTheme.dark,
                child: ColoredBox(
                  color: AppColors.ink,
                  child: MessageView(
                    icon: Icons.no_photography_rounded,
                    message: 'No pudimos abrir la cámara. Permite el acceso a la cámara o escribe el número de la unidad.',
                    actionLabel: 'Escribir el número',
                    onAction: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ),
            IgnorePointer(child: CustomPaint(painter: _ScrimPainter(side: _side, align: _align))),
            const Align(alignment: Alignment(0, _align), child: ScanFrame(size: _side)),
            SafeArea(
              child: Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: IconButton.filled(
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Regresar',
                    style: IconButton.styleFrom(backgroundColor: Colors.black54, foregroundColor: Colors.white, fixedSize: const Size.square(52)),
                    icon: const Icon(Icons.arrow_back_rounded, size: 26),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding: EdgeInsets.fromLTRB(22, 26, 22, 22 + MediaQuery.paddingOf(context).bottom),
                decoration: const BoxDecoration(
                  color: AppColors.ink,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Semantics(
                      liveRegion: true,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 1),
                            child: Icon(_invalid ? Icons.error_outline_rounded : Icons.qr_code_scanner_rounded, color: _invalid ? AppColors.dangerBright : AppColors.pink, size: 22),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              _invalid ? 'Ese código no es de una unidad ABORDO. Intenta con otro.' : 'Apunta la cámara al código QR de la unidad.',
                              textAlign: TextAlign.center,
                              style: text.titleMedium?.copyWith(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _OnDarkButton(label: 'Escribir el número', icon: Icons.pin_outlined, onPressed: () => Navigator.of(context).pop()),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Botón secundario pensado para el panel oscuro de la cámara (no depende del tema del teléfono).
class _OnDarkButton extends StatelessWidget {
  const _OnDarkButton({required this.label, required this.icon, required this.onPressed});
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 22),
      label: Text(label),
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        backgroundColor: Colors.white.withOpacity(.12),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.white.withOpacity(.2), width: 1.5)),
        textStyle: Theme.of(context).textTheme.labelLarge,
      ),
    );
  }
}

/// Oscurece todo menos una ventana redondeada, centrada igual que el `ScanFrame`.
class _ScrimPainter extends CustomPainter {
  const _ScrimPainter({required this.side, required this.align});
  final double side;
  final double align;

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height / 2 + align * (size.height - side) / 2;
    final hole = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(size.width / 2, cy), width: side, height: side), const Radius.circular(24));
    final path = Path.combine(PathOperation.difference, Path()..addRect(Offset.zero & size), Path()..addRRect(hole));
    canvas.drawPath(path, Paint()..color = Colors.black.withOpacity(.58));
  }

  @override
  bool shouldRepaint(_ScrimPainter old) => old.side != side || old.align != align;
}
