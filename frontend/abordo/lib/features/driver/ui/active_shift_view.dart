import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/services/voice_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/dates.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/stat_tile.dart';
import '../domain/driver_models.dart';
import '../state/driver_providers.dart';

/// Turno en marcha: total del día, último cobro y aviso de voz.
/// Mantiene la pantalla encendida para que el aviso nunca se pierda.
class ActiveShiftView extends ConsumerStatefulWidget {
  const ActiveShiftView({super.key, required this.shift});
  final ShiftState shift;

  @override
  ConsumerState<ActiveShiftView> createState() => _ActiveShiftViewState();
}

class _ActiveShiftViewState extends ConsumerState<ActiveShiftView> {
  bool _ending = false;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  Future<void> _end() async {
    final s = widget.shift;
    final ok = await confirm(
      context,
      title: '¿Terminar el turno?',
      message: 'Llevas ${Money.format(s.amountCents)} en ${s.count} ${s.count == 1 ? 'cobro' : 'cobros'}.',
      confirmLabel: 'Sí, terminar',
      danger: true,
    );
    if (!ok || !mounted) return;
    setState(() => _ending = true);
    try {
      final summary = await ref.read(shiftProvider.notifier).end();
      if (mounted) await _showSummary(summary);
    } catch (e) {
      if (mounted) showMessage(context, friendlyError(e), error: true);
    } finally {
      if (mounted) setState(() => _ending = false);
    }
  }

  Future<void> _showSummary(ShiftState summary) => showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Turno terminado'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StatTile(label: 'Cobraste', value: Money.format(summary.amountCents), caption: '${summary.count} pasajeros'),
              const SizedBox(height: 12),
              const Text('Tu dueño ya ve este cuadre.'),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          actions: [AppButton(label: 'Listo', onPressed: () => Navigator.pop(ctx))],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final s = widget.shift;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final voice = ref.watch(voiceEnabledProvider);
    final last = s.recent.isEmpty ? null : s.recent.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          color: last == null ? null : AppColors.success.withOpacity(.16),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Row(
              key: ValueKey(last?.seq ?? 0),
              children: [
                Icon(last == null ? Icons.hourglass_empty_rounded : Icons.check_circle_rounded, size: 44, color: last == null ? scheme.onSurfaceVariant : AppColors.success),
                const SizedBox(width: 14),
                Expanded(
                  child: Semantics(
                    liveRegion: true,
                    child: last == null
                        ? Text('Esperando el primer pasajero…', style: text.titleLarge)
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Pagó ${Money.format(last.amountCents)}', style: text.headlineSmall),
                              Text('Hoy a las ${AppDates.time(last.paidAt)}', style: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant)),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          onTap: () => ref.read(voiceEnabledProvider.notifier).set(!voice),
          semanticLabel: 'Aviso de voz ${voice ? 'encendido' : 'apagado'}. Toca para cambiar.',
          child: Row(
            children: [
              Icon(voice ? Icons.volume_up_rounded : Icons.volume_off_rounded, size: 34),
              const SizedBox(width: 14),
              Expanded(child: Text('Aviso de voz: ${voice ? 'Encendido' : 'Apagado'}', style: text.titleMedium)),
              ExcludeSemantics(child: Switch(value: voice, onChanged: (v) => ref.read(voiceEnabledProvider.notifier).set(v))),
            ],
          ),
        ),
        if (s.recent.length > 1) ...[
          const SizedBox(height: 24),
          Text('Últimos cobros', style: text.titleLarge),
          const SizedBox(height: 8),
          for (final p in s.recent.skip(1))
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.check_rounded, color: AppColors.success),
              title: Text(Money.format(p.amountCents), style: text.titleMedium),
              trailing: Text(AppDates.time(p.paidAt), style: text.bodyLarge),
            ),
        ],
        const SizedBox(height: 28),
        AppButton(label: 'Terminar turno', icon: Icons.stop_circle_outlined, kind: ButtonKind.danger, loading: _ending, onPressed: _end),
      ],
    );
  }
}
