import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'app_card.dart';

/// Opción grande: icono en baldosa, título y frase corta. La destacada usa el degradado de la marca.
class ActionCard extends StatelessWidget {
  const ActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.highlighted = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final fg = highlighted ? AppColors.ink : scheme.onSurface;
    final soft = highlighted ? AppColors.ink : scheme.onSurfaceVariant;

    return AppCard(
      onTap: onTap,
      color: highlighted ? AppColors.pink : null,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: highlighted ? 20 : 14),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            color: highlighted ? AppColors.ink : AppColors.graphite,
            child: Icon(icon, size: 26, color: highlighted ? AppColors.pink : Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: text.titleLarge?.copyWith(color: fg)),
                if (subtitle != null) Text(subtitle!, style: text.bodyMedium?.copyWith(color: soft)),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_rounded, size: 24, color: highlighted ? AppColors.ink : soft),
        ],
      ),
    );
  }
}
