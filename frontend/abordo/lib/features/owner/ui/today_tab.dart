import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/dates.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/ranked_bars.dart';
import '../../../core/widgets/sparkline.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/brand_hero.dart';
import '../../../core/widgets/pulse_dot.dart';
import '../../../core/widgets/state_views.dart';
import '../domain/owner_models.dart';
import '../state/owner_providers.dart';
import 'history_page.dart';

/// Cuadre del día: total, avance por hora y quién/qué unidad cobró cuánto.
class TodayTab extends ConsumerWidget {
  const TodayTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final day = ref.watch(selectedDayProvider);
    final summary = ref.watch(summaryProvider);
    final isToday = day == AppDates.todayKey();

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(summaryProvider),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(Dimens.pagePadding, 8, Dimens.pagePadding, 32),
        children: [
          _DayPicker(day: day, isToday: isToday),
          const SizedBox(height: 16),
          AsyncValueView<DaySummary>(
            value: summary,
            onRetry: () => ref.invalidate(summaryProvider),
            data: (s) => _Content(summary: s, isToday: isToday),
          ),
        ],
      ),
    );
  }
}

class _DayPicker extends ConsumerWidget {
  const _DayPicker({required this.day, required this.isToday});
  final String day;
  final bool isToday;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    void go(int delta) => ref.read(selectedDayProvider.notifier).state = AppDates.shiftKey(day, delta);
    return Row(
      children: [
        IconButton.filledTonal(
          iconSize: 26,
          tooltip: 'Día anterior',
          constraints: const BoxConstraints.tightFor(width: Dimens.minTap, height: Dimens.minTap),
          onPressed: () => go(-1),
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Expanded(
          child: Semantics(
            liveRegion: true,
            child: Text(
              '${isToday ? 'Hoy, ' : ''}${AppDates.longDay(day)}',
              textAlign: TextAlign.center,
              style: text.titleMedium,
            ),
          ),
        ),
        IconButton.filledTonal(
          iconSize: 26,
          tooltip: 'Día siguiente',
          constraints: const BoxConstraints.tightFor(width: Dimens.minTap, height: Dimens.minTap),
          onPressed: isToday ? null : () => go(1),
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.summary, required this.isToday});
  final DaySummary summary;
  final bool isToday;

  static String _count(int n, String one, String many) => '$n ${n == 1 ? one : many}';

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    if (summary.count == 0) {
      return MessageView(
        icon: Icons.receipt_long_outlined,
        message: isToday ? 'Todavía no hay cobros hoy. Aparecerán aquí en cuanto un pasajero pague.' : 'No hubo cobros este día.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BrandHero(
          safeTop: false,
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (isToday) ...[const PulseDot(), const SizedBox(width: 4)],
                  Text(isToday ? 'Cobros de hoy' : 'Cobros del día', style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
              Semantics(
                label: '${Money.format(summary.totalCents)}, ${_count(summary.count, 'pasaje cobrado', 'pasajes cobrados')}',
                excludeSemantics: true,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(Money.format(summary.totalCents), style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 44)),
                ),
              ),
              Text(_count(summary.count, 'pasaje cobrado', 'pasajes cobrados'), style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.silver)),
              const SizedBox(height: 18),
              Sparkline(values: summary.cumulative, semanticLabel: 'Gráfica del dinero acumulado durante el día'),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('Por chofer', style: text.titleLarge),
        RankedBars(items: [for (final r in summary.byDriver) RankedItem(name: r.name, cents: r.totalCents, caption: _count(r.count, 'pasajero', 'pasajeros'))]),
        const SizedBox(height: 16),
        Text('Por unidad', style: text.titleLarge),
        RankedBars(items: [for (final r in summary.byUnit) RankedItem(name: r.name, cents: r.totalCents, caption: _count(r.count, 'pasajero', 'pasajeros'))]),
        const SizedBox(height: 24),
        AppButton(
          label: 'Ver todos los cobros',
          icon: Icons.receipt_long_rounded,
          kind: ButtonKind.secondary,
          onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => HistoryPage(day: summary.date))),
        ),
      ],
    );
  }
}
