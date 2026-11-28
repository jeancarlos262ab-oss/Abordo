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
import '../../../core/theme/app_icons.dart';

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
      icon: AppIcons.stopCircle,
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
          icon: AppIcons.check,
          iconColor: Colors.white,
          iconBackground: AppColors.success,
          title: 'Turno terminado',
          message: 'Tu dueño ya ve este cuadre.',
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
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
          radius: Dimens.rXl,
          color: last == null ? null : p.successSoft,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Row(
              key: ValueKey(last?.seq ?? 0),
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: last == null ? p.field : AppColors.success,
                    
                  ),
                  child: Icon(last == null ? AppIcons.hourglass : AppIcons.check, size: 32, color: last == null ? p.muted : Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Semantics(
                    liveRegion: true,
                    child: last == null
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Esperando el primer pasajero…', style: text.titleLarge),
                              Text('Aquí verás cada cobro al instante.', style: text.bodyMedium?.copyWith(color: p.muted)),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('ÚLTIMO COBRO', style: text.labelSmall?.copyWith(color: p.success)),
                              FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(Money.format(last.amountCents), style: tabular(text.displaySmall))),
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
          radius: Dimens.rXl,
          onTap: () => ref.read(voiceEnabledProvider.notifier).set(!voice),
          semanticLabel: 'Aviso de voz ${voice ? 'encendido' : 'apagado'}. Toca para cambiar.',
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              IconTile(icon: voice ? AppIcons.speakerOn : AppIcons.speakerOff, size: 44),
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
          const SizedBox(height: 24),
          const SectionLabel('Cobros anteriores'),
          AppCard(
            radius: Dimens.rXl,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            child: Column(
              children: [
                for (var i = 0; i < older.length; i++) ...[
                  if (i > 0) Divider(color: p.border),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(color: p.successSoft, shape: BoxShape.circle),
                          child: Icon(AppIcons.check, size: 20, color: p.success),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(Money.format(older[i].amountCents), style: tabular(text.titleMedium))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(color: p.field, borderRadius: BorderRadius.circular(99)),
                          child: Text(AppDates.time(older[i].paidAt), style: text.labelMedium?.copyWith(color: p.muted)),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        AppButton(label: 'Terminar turno', icon: AppIcons.stopCircle, kind: ButtonKind.dangerSoft, loading: _ending, onPressed: _end),
      ],
    );
  }
}
