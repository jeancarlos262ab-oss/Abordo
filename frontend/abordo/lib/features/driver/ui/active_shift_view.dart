import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/services/voice_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/dates.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/stat_tile.dart';
import '../domain/driver_models.dart';
import '../state/driver_providers.dart';

/// Turno en marcha: último cobro, aviso de voz y lista de cobros recientes.
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
      icon: Icons.stop_circle_outlined,
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
        builder: (ctx) => AppDialog(
          icon: Icons.check_rounded,
          iconColor: Colors.white,
          iconBackground: AppColors.success,
          title: 'Turno terminado',
          message: 'Tu dueño ya ve este cuadre.',
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
            decoration: BoxDecoration(color: ctx.palette.field, borderRadius: BorderRadius.circular(Dimens.rMd)),
            child: Center(child: StatTile(label: 'Cobraste', value: Money.format(summary.amountCents), caption: '${summary.count} ${summary.count == 1 ? 'pasajero' : 'pasajeros'}')),
          ),
          actions: [AppButton(label: 'Listo', onPressed: () => Navigator.pop(ctx))],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final s = widget.shift;
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final voice = ref.watch(voiceEnabledProvider);
    final last = s.recent.isEmpty ? null : s.recent.first;
    final older = s.recent.skip(1).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          color: last == null ? null : p.successSoft,
          padding: const EdgeInsets.all(20),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Row(
              key: ValueKey(last?.seq ?? 0),
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: last == null ? p.field : AppColors.success),
                  child: Icon(last == null ? Icons.hourglass_empty_rounded : Icons.check_rounded, size: 30, color: last == null ? p.muted : Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Semantics(
                    liveRegion: true,
                    child: last == null
                        ? Text('Esperando el primer pasajero…', style: text.titleLarge)
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('ÚLTIMO COBRO', style: text.labelSmall?.copyWith(color: p.success)),
                              const SizedBox(height: 2),
                              Text('Pagó ${Money.format(last.amountCents)}', style: tabular(text.headlineSmall)),
                              Text('Hoy a las ${AppDates.time(last.paidAt)}', style: text.bodyMedium?.copyWith(color: p.muted)),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        AppCard(
          onTap: () => ref.read(voiceEnabledProvider.notifier).set(!voice),
          semanticLabel: 'Aviso de voz ${voice ? 'encendido' : 'apagado'}. Toca para cambiar.',
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              IconTile(icon: voice ? Icons.volume_up_rounded : Icons.volume_off_rounded, size: 44),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Aviso de voz', style: text.titleMedium),
                    Text(voice ? 'Dice cada cobro en voz alta' : 'Apagado', style: text.bodySmall?.copyWith(color: p.muted)),
                  ],
                ),
              ),
              ExcludeSemantics(child: Switch(value: voice, onChanged: (v) => ref.read(voiceEnabledProvider.notifier).set(v))),
            ],
          ),
        ),
        if (older.isNotEmpty) ...[
          const SizedBox(height: 32),
          const SectionLabel('Cobros anteriores'),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            child: Column(
              children: [
                for (var i = 0; i < older.length; i++) ...[
                  if (i > 0) Divider(color: p.border),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_rounded, size: 22, color: p.success),
                        const SizedBox(width: 12),
                        Expanded(child: Text(Money.format(older[i].amountCents), style: tabular(text.titleMedium))),
                        Text(AppDates.time(older[i].paidAt), style: text.bodyMedium?.copyWith(color: p.muted)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 32),
        AppButton(label: 'Terminar turno', icon: Icons.stop_circle_outlined, kind: ButtonKind.dangerSoft, loading: _ending, onPressed: _end),
      ],
    );
  }
}
