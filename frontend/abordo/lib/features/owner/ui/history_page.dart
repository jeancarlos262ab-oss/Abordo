import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/dates.dart';
import '../../../core/utils/money.dart';
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
    final history = ref.watch(historyProvider(day));
    return PageScaffold(
      title: 'Cobros del día',
      child: AsyncValueView<History>(
        value: history,
        onRetry: () => ref.invalidate(historyProvider(day)),
        data: (h) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppDates.longDay(day), style: text.titleMedium),
            const SizedBox(height: 8),
            for (final i in h.items)
              ListTile(
                contentPadding: EdgeInsets.zero,
                minVerticalPadding: 12,
                title: Text(Money.format(i.amountCents), style: text.titleLarge),
                subtitle: Text('${i.unitLabel} · ${i.driverName}', style: text.bodyLarge),
                trailing: Text(AppDates.time(i.paidAt), style: text.titleMedium),
              ),
            if (h.total > h.items.length) Text('Mostrando los últimos ${h.items.length} de ${h.total} cobros.', style: text.bodyMedium),
          ],
        ),
      ),
    );
  }
}
