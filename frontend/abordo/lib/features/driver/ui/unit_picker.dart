import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/ticket_card.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/state_views.dart';
import '../domain/driver_models.dart';
import '../state/driver_providers.dart';
import '../../../core/theme/app_icons.dart';

/// Elegir unidad = empezar turno. Una tarjeta por unidad y una confirmación.
class UnitPicker extends ConsumerStatefulWidget {
  const UnitPicker({super.key});

  @override
  ConsumerState<UnitPicker> createState() => _UnitPickerState();
}

class _UnitPickerState extends ConsumerState<UnitPicker> {
  bool _busy = false;

  Future<void> _start(ShiftUnit unit) async {
    final ok = await confirm(
      context,
      title: '¿Empezar turno?',
      message: '${unit.label} · ${unit.route}\nPasaje ${Money.format(unit.fareCents)}',
      confirmLabel: 'Sí, empezar',
      icon: AppIcons.playCircle,
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref.read(shiftProvider.notifier).start(unit.id);
    } catch (e) {
      if (mounted) showMessage(context, friendlyError(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final units = ref.watch(driverUnitsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('¿En qué unidad vas hoy?', style: text.headlineSmall),
        const SizedBox(height: 6),
        Text('Toca tu unidad para empezar el turno.', style: text.bodyLarge?.copyWith(color: p.muted)),
        const SizedBox(height: 18),
        AsyncValueView<List<ShiftUnit>>(
          value: units,
          onRetry: () => ref.invalidate(driverUnitsProvider),
          data: (list) => list.isEmpty
              ? const MessageView(icon: AppIcons.busOutlined, message: 'Tu dueño todavía no registra unidades. Avísale para que las agregue.')
              : Column(
                  children: [
                    for (final u in list)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _UnitTicket(unit: u, onTap: _busy ? () {} : () => _start(u)),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

/// Unidad como boleto: ilustración del vehículo, nombre, ruta, pasaje y botón de empezar.
class _UnitTicket extends StatelessWidget {
  const _UnitTicket({required this.unit, required this.onTap});
  final ShiftUnit unit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    return Semantics(
      button: true,
      label: '${unit.label}, ${unit.route}, pasaje ${Money.spoken(unit.fareCents)}. Toca para empezar el turno.',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: TicketCard(
          top: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(unit.label, style: text.titleLarge, overflow: TextOverflow.ellipsis),
                    Text(unit.route, style: text.bodyMedium?.copyWith(color: p.muted), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
          bottom: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PASAJE', style: text.labelSmall?.copyWith(color: p.muted)),
                    Text(Money.format(unit.fareCents), style: tabular(text.headlineSmall)),
                  ],
                ),
              ),
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(99)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Empezar', style: text.labelLarge?.copyWith(color: Theme.of(context).colorScheme.onPrimary)),
                    const SizedBox(width: 6),
                    Icon(AppIcons.play, size: 22, color: Theme.of(context).colorScheme.onPrimary),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
