import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/money.dart';
import '../../../core/services/qr_pdf.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/page_scaffold.dart';
import '../../../core/widgets/scan_frame.dart';
import '../../../core/widgets/labeled_field.dart';
import '../domain/owner_models.dart';
import '../../../core/theme/app_icons.dart';

/// QR fijo de la unidad, listo para tomar captura/imprimir y pegar en la combi.
/// El QR va en negro sobre blanco: es lo que mejor leen las cámaras.
class UnitQrPage extends StatelessWidget {
  const UnitQrPage({super.key, required this.unit});
  final OwnerUnit unit;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    return PageScaffold(
      overlap: false,
      title: 'Código de la unidad',
      hero: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(unit.label, style: text.headlineMedium?.copyWith(color: AppColors.ink)),
          const SizedBox(height: 4),
          Text('${unit.route} · Pasaje ${Money.format(unit.fareCents)}', style: text.bodyLarge?.copyWith(color: AppColors.graphite)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Semantics(
              label: 'Código QR de ${unit.label}',
              child: ScanFrame(
                color: p.accent,
                scanning: false,
                child: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(Dimens.rMd),
                    border: Border.all(color: p.border, width: .8),
                  ),
                  child: QrImageView(data: unit.qrContent, size: 210, backgroundColor: Colors.white),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
            child: Column(
              children: [
                Text('NÚMERO DE LA UNIDAD', style: text.labelSmall?.copyWith(color: p.muted)),
                const SizedBox(height: 6),
                Text(unit.spacedCode, style: text.headlineLarge?.copyWith(letterSpacing: 6)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppButton(
            label: 'Imprimir QR en PDF',
            icon: AppIcons.printer,
            onPressed: () async {
              try {
                await QrPdf.printOrSave(unit);
              } catch (_) {
                if (context.mounted) showMessage(context, 'No pudimos preparar el PDF. Intenta de nuevo.', error: true);
              }
            },
          ),
          const SizedBox(height: 16),
          const InfoNote(
            icon: AppIcons.printer,
            message: 'Imprime este código y pégalo junto a la puerta y cerca del chofer. Los pasajeros lo escanean para pagar.',
          ),
        ],
      ),
    );
  }
}
