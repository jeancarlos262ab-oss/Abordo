import 'package:flutter/material.dart';

import '../utils/money.dart';

class RankedItem {
  const RankedItem({required this.name, required this.cents, required this.caption});
  final String name;
  final int cents;
  final String caption;
}

/// Lista ordenada con barra proporcional (como "cobros por chofer" de la landing).
class RankedBars extends StatelessWidget {
  const RankedBars({super.key, required this.items});
  final List<RankedItem> items;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final max = items.fold<int>(1, (m, i) => i.cents > m ? i.cents : m);
    return Column(
      children: [
        for (final i in items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Semantics(
              label: '${i.name}: ${Money.format(i.cents)}, ${i.caption}',
              excludeSemantics: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(i.name, style: text.titleMedium, overflow: TextOverflow.ellipsis)),
                      Text(Money.format(i.cents), style: text.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRect(
                    child: LinearProgressIndicator(
                      value: i.cents / max,
                      minHeight: 12,
                      color: scheme.primary,
                      backgroundColor: scheme.outline.withOpacity(.25),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(i.caption, style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
