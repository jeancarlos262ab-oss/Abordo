import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/unit_code.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/scan_frame.dart';
import '../../../core/widgets/state_views.dart';

/// Cámara a pantalla completa que lee el QR fijo de la unidad y regresa su código con `Navigator.pop`.
class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
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
                data: Theme.of(context),
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
            const Center(child: ScanFrame(size: 240)),
            SafeArea(
              child: Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: IconButton.filled(
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Regresar',
                    style: IconButton.styleFrom(backgroundColor: Colors.black54, foregroundColor: Colors.white, minimumSize: const Size.square(56)),
                    icon: const Icon(Icons.arrow_back_rounded, size: 28),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding: EdgeInsets.fromLTRB(20, 24, 20, 20 + MediaQuery.paddingOf(context).bottom),
                color: AppColors.ink,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        _invalid ? 'Ese código no es de una unidad ABORDO. Intenta con otro.' : 'Apunta la cámara al código QR de la unidad.',
                        textAlign: TextAlign.center,
                        style: text.titleMedium?.copyWith(color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Theme(
                      data: Theme.of(context).copyWith(colorScheme: Theme.of(context).colorScheme.copyWith(onSurface: Colors.white, outline: AppColors.grey)),
                      child: AppButton(label: 'Escribir el número', kind: ButtonKind.secondary, onPressed: () => Navigator.of(context).pop()),
                    ),
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
