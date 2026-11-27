import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_icons.dart';

/// Etiqueta de estado en forma de píldora, con icono y texto (nunca solo color).
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.good, this.icon});
  final String label;
  final bool good;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = good ? p.success : p.muted;
    final bg = good ? p.successSoft : p.field;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 12, 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon ?? (good ? AppIcons.checkCircle : AppIcons.pauseCircle), size: 18, color: color),
          const SizedBox(width: 6),
          Flexible(child: Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}
