import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/dates.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/brand_hero.dart';
import '../../../core/widgets/pulse_dot.dart';
import '../../../core/widgets/ranked_bars.dart';
import '../../../core/widgets/sparkline.dart';
import '../../../core/widgets/stat_tile.dart';
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
        padding: const EdgeInsets.fromLTRB(Dimens.pagePadding, 0, Dimens.pagePadding, 32),
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

/// Selector de día: píldora con flechas grandes a los lados.
class _DayPicker extends ConsumerWidget {
  const _DayPicker({required this.day, required this.isToday});
  final String day;
  final bool isToday;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    void go(int delta) => ref.read(selectedDayProvider.notifier).state = AppDates.shiftKey(day, delta);

    Widget arrow(IconData icon, String tooltip, VoidCallback? onTap) => IconButton(
          tooltip: tooltip,
          onPressed: onTap,
          style: IconButton.styleFrom(
            backgroundColor: p.field,
            disabledBackgroundColor: p.field.withOpacity(.5),
            fixedSize: const Size.square(Dimens.minTap),
          ),
          icon: Icon(icon, size: 26),
        );

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(Dimens.rLg),
        border: Border.all(color: p.border),
      ),
      child: Row(
        children: [
          arrow(Icons.chevron_left_rounded, 'Día anterior', () => go(-1)),
          Expanded(
            child: Semantics(
              liveRegion: true,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isToday) Text('HOY', style: text.labelSmall?.copyWith(color: p.accent)),
                  Text(AppDates.longDay(day), textAlign: TextAlign.center, style: text.titleMedium),
                ],
              ),
            ),
          ),
          arrow(Icons.chevron_right_rounded, 'Día siguiente', isToday ? null : () => go(1)),
        ],
      ),
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BrandHero(
          panel: true,
          safeTop: false,
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (isToday) ...[const PulseDot(size: 9), const SizedBox(width: 2)],
                  Text(isToday ? 'Cobros de hoy' : 'Cobros del día', style: text.titleMedium?.copyWith(color: AppColors.silver)),
                ],
              ),
              Semantics(
                label: '${Money.format(summary.totalCents)}, ${_count(summary.count, 'pasaje cobrado', 'pasajes cobrados')}',
                excludeSemantics: true,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(Money.format(summary.totalCents), style: text.displayMedium?.copyWith(color: Colors.white)),
                ),
              ),
              const SizedBox(height: 18),
              Sparkline(values: summary.cumulative, semanticLabel: 'Gráfica del dinero acumulado durante el día', color: AppColors.pink),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(AppDates.hourLabel(0), style: text.bodySmall?.copyWith(color: AppColors.grey)),
                  Text(AppDates.hourLabel(12), style: text.bodySmall?.copyWith(color: AppColors.grey)),
                  Text(AppDates.hourLabel(23), style: text.bodySmall?.copyWith(color: AppColors.grey)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: MiniStat(icon: Icons.confirmation_number_rounded, label: summary.count == 1 ? 'Pasaje' : 'Pasajes', value: '${summary.count}')),
            const SizedBox(width: 10),
            Expanded(child: MiniStat(icon: Icons.groups_rounded, label: summary.byDriver.length == 1 ? 'Chofer' : 'Choferes', value: '${summary.byDriver.length}')),
            const SizedBox(width: 10),
            Expanded(child: MiniStat(icon: Icons.directions_bus_rounded, label: summary.byUnit.length == 1 ? 'Unidad' : 'Unidades', value: '${summary.byUnit.length}')),
          ],
        ),
        const SizedBox(height: 28),
        const SectionLabel('Por chofer'),
        AppCard(
          child: RankedBars(items: [for (final r in summary.byDriver) RankedItem(name: r.name, cents: r.totalCents, caption: _count(r.count, 'pasajero', 'pasajeros'))]),
        ),
        const SizedBox(height: 28),
        const SectionLabel('Por unidad'),
        AppCard(
          child: RankedBars(items: [for (final r in summary.byUnit) RankedItem(name: r.name, cents: r.totalCents, caption: _count(r.count, 'pasajero', 'pasajeros'))]),
        ),
        const SizedBox(height: 28),
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
