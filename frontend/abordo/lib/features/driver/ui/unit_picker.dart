import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/action_card.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/state_views.dart';
import '../domain/driver_models.dart';
import '../state/driver_providers.dart';

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
      icon: Icons.play_circle_outline_rounded,
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
        const SizedBox(height: 20),
        AsyncValueView<List<ShiftUnit>>(
          value: units,
          onRetry: () => ref.invalidate(driverUnitsProvider),
          data: (list) => list.isEmpty
              ? const MessageView(icon: Icons.directions_bus_outlined, message: 'Tu dueño todavía no registra unidades. Avísale para que las agregue.')
              : Column(
                  children: [
                    for (final u in list)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ActionCard(
                          icon: Icons.directions_bus_rounded,
                          title: u.label,
                          subtitle: u.route,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(Money.format(u.fareCents), style: tabular(text.titleLarge)),
                              Icon(Icons.chevron_right_rounded, color: p.muted),
                            ],
                          ),
                          onTap: _busy ? () {} : () => _start(u),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}
