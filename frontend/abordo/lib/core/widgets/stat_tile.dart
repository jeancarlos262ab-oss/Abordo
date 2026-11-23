import 'package:flutter/material.dart';

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
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: '$label: $value${caption == null ? '' : ', $caption'}',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (live) ...[Icon(Icons.circle, size: 12, color: scheme.primary), const SizedBox(width: 8)],
              Text(label, style: text.titleMedium?.copyWith(color: scheme.onSurfaceVariant)),
            ],
          ),
          FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: text.displaySmall)),
          if (caption != null) Text(caption!, style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
