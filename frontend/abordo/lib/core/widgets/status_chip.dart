import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Etiqueta de estado con icono y texto (nunca solo color).
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.good});
  final String label;
  final bool good;

  @override
  Widget build(BuildContext context) {
    final color = good ? AppColors.success : Theme.of(context).colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(.16)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(good ? Icons.check_circle_rounded : Icons.pause_circle_rounded, size: 20, color: color),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
