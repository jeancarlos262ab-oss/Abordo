import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/dates.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/pulse_dot.dart';
import '../../../core/widgets/sparkline.dart';
import '../../../core/widgets/state_views.dart';
import '../domain/owner_models.dart';
import '../state/owner_providers.dart';
import 'history_page.dart';
import 'owner_widgets.dart';

String _count(int n, String one, String many) => '$n ${n == 1 ? one : many}';

String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// Cuadre del día: la cifra del día en un panel oscuro y, debajo, quién y qué unidad cobró cuánto,
/// directo sobre el fondo (sin tarjetas).
class TodayTab extends ConsumerWidget {
  const TodayTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final day = ref.watch(selectedDayProvider);
    final summary = ref.watch(summaryProvider);
    final isToday = day == AppDates.todayKey();

    return RefreshIndicator(
      color: AppColors.rose,
      backgroundColor: context.panelColor,
      onRefresh: () async => ref.invalidate(summaryProvider),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(Dimens.pagePadding, 0, Dimens.pagePadding, 32),
        children: [
          _DayPicker(day: day, isToday: isToday),
          const SizedBox(height: 14),
          OwnerAsync<DaySummary>(
            value: summary,
            onRetry: () => ref.invalidate(summaryProvider),
            data: (s) => _Content(summary: s, isToday: isToday),
          ),
        ],
      ),
    );
  }
}

/// Selector de día sin contenedor: flechas redondas a los lados y, al centro, la fecha que abre el calendario.
class _DayPicker extends ConsumerWidget {
  const _DayPicker({required this.day, required this.isToday});
  final String day;
  final bool isToday;

  Future<void> _openCalendar(BuildContext context, WidgetRef ref) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: context.palette.background,
      constraints: const BoxConstraints(maxWidth: Dimens.maxContentWidth),
      builder: (_) => _CalendarSheet(selected: day),
    );
    if (picked != null) ref.read(selectedDayProvider.notifier).state = picked;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    void go(int delta) => ref.read(selectedDayProvider.notifier).state = AppDates.shiftKey(day, delta);

    Widget arrow(IconData icon, String tooltip, VoidCallback? onTap) => IconButton(
          tooltip: tooltip,
          onPressed: onTap,
          style: IconButton.styleFrom(
            backgroundColor: context.inkAt(.08),
            foregroundColor: context.inkColor,
            disabledBackgroundColor: Colors.transparent,
            disabledForegroundColor: context.inkAt(.25),
            fixedSize: const Size.square(Dimens.minTap),
            shape: const CircleBorder(),
          ),
          icon: Icon(icon, size: 22),
        );

    return Row(
      children: [
        arrow(AppIcons.caretLeft, 'Día anterior', () => go(-1)),
        Expanded(
          child: Semantics(
            button: true,
            liveRegion: true,
            label: '${AppDates.longDay(day)}. Toca para abrir el calendario.',
            excludeSemantics: true,
            child: InkWell(
              borderRadius: BorderRadius.circular(Dimens.rMd),
              onTap: () => _openCalendar(context, ref),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: Dimens.minTap),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isToday) Text('HOY', style: text.labelSmall?.copyWith(color: context.inkColor)),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(AppIcons.calendar, size: 18, color: context.inkColor),
                        const SizedBox(width: 8),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(_cap(AppDates.longDay(day)), style: text.titleLarge),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(AppIcons.caretDown, size: 14, color: context.palette.muted),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        arrow(AppIcons.caretRight, 'Día siguiente', isToday ? null : () => go(1)),
      ],
    );
  }
}

/// Calendario de la app (table_calendar con estilo propio): mes con flechas, días en cuadros
/// redondeados, hoy marcado con borde rosa y el día elegido relleno. No deja elegir el futuro.
class _CalendarSheet extends StatefulWidget {
  const _CalendarSheet({required this.selected});
  final String selected;

  @override
  State<_CalendarSheet> createState() => _CalendarSheetState();
}

class _CalendarSheetState extends State<_CalendarSheet> {
  late final DateTime _today = AppDates.fromKey(AppDates.todayKey());
  late DateTime _selected = AppDates.fromKey(widget.selected);
  late DateTime _focused = _selected;

  static String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  void _page(int delta) {
    final next = DateTime(_focused.year, _focused.month + delta, 1);
    if (next.isAfter(DateTime(_today.year, _today.month, 1))) return;
    setState(() => _focused = next);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final canNext = DateTime(_focused.year, _focused.month + 1, 1).isBefore(DateTime(_today.year, _today.month + 1, 1));

    Widget nav(IconData icon, String tip, VoidCallback? onTap) => IconButton(
          tooltip: tip,
          onPressed: onTap,
          style: IconButton.styleFrom(
            backgroundColor: p.accentSoft,
            foregroundColor: AppColors.ink,
            disabledBackgroundColor: p.field,
            disabledForegroundColor: p.borderStrong,
            fixedSize: const Size.square(40),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimens.rSm)),
          ),
          icon: Icon(icon, size: 18),
        );

    Widget chip(String label, DateTime day) {
      final on = isSameDay(_selected, day);
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _selected = _focused = day),
          child: Container(
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: on ? AppColors.rose : p.field,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(label, style: text.labelLarge?.copyWith(color: on ? AppColors.ink : p.text)),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(Dimens.pagePadding, 0, Dimens.pagePadding, 20 + MediaQuery.paddingOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  liveRegion: true,
                  child: Text(_cap(DateFormat('MMMM yyyy', 'es_MX').format(_focused)), style: text.headlineSmall),
                ),
              ),
              nav(AppIcons.caretLeft, 'Mes anterior', () => _page(-1)),
              const SizedBox(width: 8),
              nav(AppIcons.caretRight, 'Mes siguiente', canNext ? () => _page(1) : null),
            ],
          ),
          const SizedBox(height: 8),
          TableCalendar<void>(
            locale: 'es_MX',
            firstDay: DateTime(2024, 1, 1),
            lastDay: _today,
            focusedDay: _focused.isAfter(_today) ? _today : _focused,
            currentDay: _today,
            selectedDayPredicate: (d) => isSameDay(d, _selected),
            startingDayOfWeek: StartingDayOfWeek.monday,
            headerVisible: false,
            availableGestures: AvailableGestures.horizontalSwipe,
            rowHeight: 48,
            daysOfWeekHeight: 34,
            onDaySelected: (sel, foc) => setState(() {
              _selected = sel;
              _focused = foc;
            }),
            onPageChanged: (foc) => setState(() => _focused = foc),
            daysOfWeekStyle: DaysOfWeekStyle(
              dowTextFormatter: (date, locale) => DateFormat.E(locale).format(date).substring(0, 1).toUpperCase(),
              weekdayStyle: text.labelMedium!.copyWith(color: p.muted),
              weekendStyle: text.labelMedium!.copyWith(color: AppColors.ink),
            ),
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              cellMargin: const EdgeInsets.all(3),
              defaultTextStyle: text.titleMedium!,
              weekendTextStyle: text.titleMedium!,
              disabledTextStyle: text.titleMedium!.copyWith(color: p.borderStrong),
              todayTextStyle: text.titleMedium!.copyWith(color: AppColors.ink, fontWeight: FontWeight.w800),
              todayDecoration: BoxDecoration(
                color: p.accentSoft,
                borderRadius: BorderRadius.circular(Dimens.rSm + 2),
                border: Border.all(color: AppColors.ink, width: 1),
              ),
              selectedTextStyle: text.titleMedium!.copyWith(color: AppColors.ink, fontWeight: FontWeight.w800),
              selectedDecoration: BoxDecoration(color: AppColors.rose, borderRadius: BorderRadius.circular(Dimens.rSm + 2)),
              defaultDecoration: BoxDecoration(borderRadius: BorderRadius.circular(Dimens.rSm + 2)),
              weekendDecoration: BoxDecoration(borderRadius: BorderRadius.circular(Dimens.rSm + 2)),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              chip('Hoy', _today),
              const SizedBox(width: 10),
              chip('Ayer', _today.subtract(const Duration(days: 1))),
              const SizedBox(width: 10),
              chip('Hace 7 días', _today.subtract(const Duration(days: 7))),
            ],
          ),
          const SizedBox(height: 16),
          AppButton(
            label: 'Ver ${AppDates.longDay(AppDates.key(_selected))}',
            icon: AppIcons.check,
            onPressed: () => Navigator.of(context).pop(AppDates.key(_selected)),
          ),
        ],
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.summary, required this.isToday});
  final DaySummary summary;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    if (summary.count == 0) {
      return MessageView(
        icon: AppIcons.receiptOutlined,
        message: isToday ? 'Todavía no hay cobros hoy. Aparecerán aquí en cuanto un pasajero pague.' : 'No hubo cobros este día.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TotalPanel(summary: summary, isToday: isToday),
        const SizedBox(height: 30),
        _RankSection(
          title: 'Por chofer',
          total: summary.totalCents,
          items: [for (final r in summary.byDriver) RankedRow(name: r.name, cents: r.totalCents, caption: _count(r.count, 'pasajero', 'pasajeros'))],
        ),
        const SizedBox(height: 28),
        _RankSection(
          title: 'Por unidad',
          total: summary.totalCents,
          items: [for (final r in summary.byUnit) RankedRow(name: r.name, cents: r.totalCents, caption: _count(r.count, 'pasajero', 'pasajeros'))],
        ),
        const SizedBox(height: 22),
        _AllChargesRow(day: summary.date),
      ],
    );
  }
}

/// La cifra del día: el único bloque oscuro de la pantalla. Total, curva acumulada y tres datos.
class _TotalPanel extends StatelessWidget {
  const _TotalPanel({required this.summary, required this.isToday});
  final DaySummary summary;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final soft = Colors.white.withOpacity(.62);
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
      decoration: BoxDecoration(color: context.panelColor, borderRadius: BorderRadius.circular(Dimens.rXl)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isToday) const PulseDot(size: 8, color: AppColors.rose) else const Icon(AppIcons.calendar, size: 16, color: AppColors.rose),
              SizedBox(width: isToday ? 4 : 8),
              Text(isToday ? 'Cobros de hoy' : 'Cobros del día', style: text.labelMedium?.copyWith(color: AppColors.rose)),
            ],
          ),
          const SizedBox(height: 10),
          Semantics(
            label: '${Money.format(summary.totalCents)}, ${_count(summary.count, 'pasaje cobrado', 'pasajes cobrados')}',
            excludeSemantics: true,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(Money.format(summary.totalCents), style: tabular(text.displayLarge).copyWith(color: Colors.white, fontSize: 52)),
            ),
          ),
          const SizedBox(height: 2),
          Text(_count(summary.count, 'pasaje cobrado', 'pasajes cobrados'), style: text.bodyMedium?.copyWith(color: soft)),
          const SizedBox(height: 18),
          Sparkline(values: summary.cumulative, semanticLabel: 'Gráfica del dinero acumulado durante el día', color: AppColors.rose),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppDates.hourLabel(0), style: text.bodySmall?.copyWith(color: soft)),
              Text(AppDates.hourLabel(12), style: text.bodySmall?.copyWith(color: soft)),
              Text(AppDates.hourLabel(23), style: text.bodySmall?.copyWith(color: soft)),
            ],
          ),
          const SizedBox(height: 18),
          Container(height: 1, color: Colors.white.withOpacity(.12)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _PanelStat(icon: AppIcons.ticket, value: '${summary.count}', label: summary.count == 1 ? 'Pasaje' : 'Pasajes')),
              const _PanelDivider(),
              Expanded(child: _PanelStat(icon: AppIcons.groups, value: '${summary.byDriver.length}', label: summary.byDriver.length == 1 ? 'Chofer' : 'Choferes')),
              const _PanelDivider(),
              Expanded(child: _PanelStat(icon: AppIcons.bus, value: '${summary.byUnit.length}', label: summary.byUnit.length == 1 ? 'Unidad' : 'Unidades')),
            ],
          ),
        ],
      ),
    );
  }
}

class _PanelStat extends StatelessWidget {
  const _PanelStat({required this.icon, required this.value, required this.label});
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Semantics(
      label: '$label: $value',
      excludeSemantics: true,
      child: Column(
        children: [
          Icon(icon, size: 18, color: AppColors.rose),
          const SizedBox(height: 4),
          Text(value, style: tabular(text.headlineSmall).copyWith(color: Colors.white)),
          Text(label, style: text.bodySmall?.copyWith(color: Colors.white.withOpacity(.62))),
        ],
      ),
    );
  }
}

class _PanelDivider extends StatelessWidget {
  const _PanelDivider();
  @override
  Widget build(BuildContext context) => Container(width: 1, height: 40, color: Colors.white.withOpacity(.12));
}

class RankedRow {
  const RankedRow({required this.name, required this.cents, required this.caption});
  final String name;
  final int cents;
  final String caption;
}

/// Ranking abierto: número de lugar, nombre, monto con su porcentaje y una barra fina debajo.
class _RankSection extends StatelessWidget {
  const _RankSection({required this.title, required this.items, required this.total});
  final String title;
  final List<RankedRow> items;
  final int total;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted = context.palette.muted;
    final max = items.fold<int>(1, (m, i) => i.cents > m ? i.cents : m);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionLabel(title, trailing: Text('${items.length}', style: text.labelMedium?.copyWith(color: muted))),
        for (var n = 0; n < items.length; n++)
          Padding(
            padding: EdgeInsets.only(top: n == 0 ? 0 : 18),
            child: _RankRowView(rank: n, item: items[n], max: max, total: total),
          ),
      ],
    );
  }
}

class _RankRowView extends StatelessWidget {
  const _RankRowView({required this.rank, required this.item, required this.max, required this.total});
  final int rank;
  final RankedRow item;
  final int max;
  final int total;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted = context.palette.muted;
    final first = rank == 0;
    final pct = total > 0 ? (item.cents * 100 / total).round() : 0;
    return Semantics(
      label: '${rank + 1}. ${item.name}: ${Money.format(item.cents)}, ${item.caption}',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(shape: BoxShape.circle, color: first ? context.buttonBg : context.inkAt(.1)),
                child: Text('${rank + 1}', style: text.labelLarge?.copyWith(color: first ? context.buttonFg : context.inkColor)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name, style: text.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(item.caption, style: text.bodySmall?.copyWith(color: muted)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(Money.format(item.cents), style: tabular(text.titleMedium)),
                  Text('$pct %', style: text.bodySmall?.copyWith(color: muted)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 48),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: item.cents / max,
                minHeight: 6,
                color: first ? context.buttonBg : context.buttonBg.withOpacity(.45),
                backgroundColor: context.inkAt(.1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Entrada al detalle de cobros: fila abierta entre dos líneas finas.
class _AllChargesRow extends StatelessWidget {
  const _AllChargesRow({required this.day});
  final String day;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const OwnerDivider(),
        Semantics(
          button: true,
          label: 'Ver todos los cobros. Uno por uno, con hora y chofer.',
          excludeSemantics: true,
          child: InkWell(
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => HistoryPage(day: day))),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: context.inkAt(.08)),
                    child: Icon(AppIcons.receipt, size: 22, color: context.inkColor),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Ver todos los cobros', style: text.titleLarge),
                        Text('Uno por uno, con hora y chofer', style: text.bodyMedium?.copyWith(color: context.palette.muted)),
                      ],
                    ),
                  ),
                  Icon(AppIcons.arrowRight, size: 20, color: context.inkColor),
                ],
              ),
            ),
          ),
        ),
        const OwnerDivider(),
      ],
    );
  }
}
