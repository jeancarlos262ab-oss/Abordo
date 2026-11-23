import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/page_scaffold.dart';
import '../../../core/widgets/scan_frame.dart';
import '../domain/owner_models.dart';

/// QR fijo de la unidad, listo para tomar captura/imprimir y pegar en la combi.
class UnitQrPage extends StatelessWidget {
  const UnitQrPage({super.key, required this.unit});
  final OwnerUnit unit;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return PageScaffold(
      title: 'Código de la unidad',
      hero: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(unit.label, style: text.headlineMedium),
          Text('${unit.route} · Pasaje ${Money.format(unit.fareCents)}', style: text.bodyLarge?.copyWith(color: AppColors.silver)),
        ],
      ),
      child: Column(
        children: [
          Center(
            child: Semantics(
              label: 'Código QR de ${unit.label}',
              child: ScanFrame(
                child: Container(
                  margin: const EdgeInsets.all(6),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: AppColors.pink),
                  child: QrImageView(data: unit.qrContent, size: 210, backgroundColor: AppColors.pink),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Número de la unidad', style: text.bodyLarge),
          Text(unit.spacedCode, style: text.headlineMedium?.copyWith(letterSpacing: 5)),
          const SizedBox(height: 20),
          Text(
            'Imprime este código y pégalo junto a la puerta y cerca del chofer. Los pasajeros lo escanean para pagar.',
            textAlign: TextAlign.center,
            style: text.bodyLarge,
          ),
        ],
      ),
    );
  }
}
