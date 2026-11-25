import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/dates.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/page_scaffold.dart';
import '../../../core/widgets/state_views.dart';
import '../domain/owner_models.dart';
import '../state/owner_providers.dart';

/// Cada cobro del día con unidad, chofer y hora.
class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key, required this.day});
  final String day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final history = ref.watch(historyProvider(day));
    return PageScaffold(
      title: 'Cobros del día',
      child: AsyncValueView<History>(
        value: history,
        onRetry: () => ref.invalidate(historyProvider(day)),
        data: (h) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(AppDates.longDay(day), style: text.headlineSmall),
            const SizedBox(height: 4),
            Text('${h.total} ${h.total == 1 ? 'cobro' : 'cobros'}', style: text.bodyLarge?.copyWith(color: p.muted)),
            const SizedBox(height: 18),
            if (h.items.isEmpty)
              const MessageView(icon: Icons.receipt_long_outlined, message: 'No hubo cobros este día.')
            else
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                child: Column(
                  children: [
                    for (var i = 0; i < h.items.length; i++) ...[
                      if (i > 0) Divider(color: p.border),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(color: p.successSoft, shape: BoxShape.circle),
                              child: Icon(Icons.check_rounded, size: 22, color: p.success),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(Money.format(h.items[i].amountCents), style: tabular(text.titleLarge)),
                                  Text('${h.items[i].unitLabel} · ${h.items[i].driverName}', style: text.bodyMedium?.copyWith(color: p.muted)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(AppDates.time(h.items[i].paidAt), style: text.titleSmall?.copyWith(color: p.muted)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            if (h.total > h.items.length) ...[
              const SizedBox(height: 16),
              Center(child: Text('Mostrando los últimos ${h.items.length} de ${h.total} cobros.', style: text.bodyMedium?.copyWith(color: p.muted))),
            ],
          ],
        ),
      ),
    );
  }
}
