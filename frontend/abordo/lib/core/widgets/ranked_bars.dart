import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/money.dart';

class RankedItem {
  const RankedItem({required this.name, required this.cents, required this.caption});
  final String name;
  final int cents;
  final String caption;
}

/// Lista ordenada con barra proporcional (como "cobros por chofer" de la landing).
/// El primer lugar lleva el rosa de marca; los demás, una versión suave.
class RankedBars extends StatelessWidget {
  const RankedBars({super.key, required this.items, this.leadingIcon, this.total});
  final List<RankedItem> items;

  /// Si se da, cada fila lleva este icono en vez del número de lugar.
  final IconData? leadingIcon;

  /// Si se da, se muestra el porcentaje que representa cada fila.
  final int? total;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final max = items.fold<int>(1, (m, i) => i.cents > m ? i.cents : m);
    return Column(
      children: [
        for (var n = 0; n < items.length; n++)
          Padding(
            padding: EdgeInsets.only(top: n == 0 ? 0 : 18),
            child: Semantics(
              label: '${n + 1}. ${items[n].name}: ${Money.format(items[n].cents)}, ${items[n].caption}',
              excludeSemantics: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: n == 0 ? AppColors.rose : p.field, shape: BoxShape.circle),
                        child: leadingIcon != null
                            ? Icon(leadingIcon, size: 20, color: n == 0 ? AppColors.ink : p.muted)
                            : Text('${n + 1}', style: text.labelMedium?.copyWith(color: n == 0 ? AppColors.ink : p.muted)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(items[n].name, style: text.titleMedium, overflow: TextOverflow.ellipsis),
                            Text(items[n].caption, style: text.bodySmall?.copyWith(color: p.muted)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(Money.format(items[n].cents), style: tabular(text.titleMedium)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: items[n].cents / max,
                      minHeight: 10,
                      color: n == 0 ? p.accent : p.accent.withOpacity(.45),
                      backgroundColor: p.field,
                    ),
                  ),
                  if (total != null && total! > 0) ...[
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text('${(items[n].cents * 100 / total!).round()} % del total', style: text.bodySmall?.copyWith(color: p.muted)),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}
