import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Cifra grande con su etiqueta. Se usa para el total del turno y del día.
class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.label, required this.value, this.caption, this.live = false});
  final String label;
  final String value;
  final String? caption;
  final bool live;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted = context.palette.muted;
    return Semantics(
      label: '$label: $value${caption == null ? '' : ', $caption'}',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (live) ...[Icon(Icons.circle, size: 10, color: Theme.of(context).colorScheme.primary), const SizedBox(width: 8)],
              Text(label, style: text.titleMedium?.copyWith(color: muted)),
            ],
          ),
          const SizedBox(height: 2),
          FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: text.displaySmall)),
          if (caption != null) Text(caption!, style: text.bodyMedium?.copyWith(color: muted)),
        ],
      ),
    );
  }
}

/// Mini tarjeta de cifra: etiqueta pequeña arriba y número destacado. Se usan en fila.
class MiniStat extends StatelessWidget {
  const MiniStat({super.key, required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Semantics(
      label: '$label: $value',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: p.border),
          boxShadow: p.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: p.accent),
            const SizedBox(height: 10),
            Text(value, style: text.headlineSmall),
            Text(label, style: text.bodySmall?.copyWith(color: p.muted)),
          ],
        ),
      ),
    );
  }
}
