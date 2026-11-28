import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'app_card.dart';
import 'qr_mark.dart';
import '../theme/app_icons.dart';

/// Fila de opción grande: baldosa con icono, título, frase corta y flecha.
class ActionCard extends StatelessWidget {
  const ActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  /// Sustituye la flecha final (por ejemplo, un precio).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          IconTile(icon: icon, size: 52),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: text.titleLarge),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: text.bodyMedium?.copyWith(color: p.muted)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing ??
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: p.field, shape: BoxShape.circle),
                child: Icon(AppIcons.arrowRight, size: 20, color: p.text),
              ),
        ],
      ),
    );
  }
}

/// La acción principal de la pantalla de inicio: una tarjeta de información sobre el mapa y,
/// debajo, un botón blanco aparte (como "Share location" de la referencia).
class FeatureCard extends StatelessWidget {
  const FeatureCard({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onTap,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    return Semantics(
      button: true,
      container: true,
      label: '$title. $subtitle. $actionLabel',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppCard(
              radius: Dimens.rLg,
              padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(eyebrow.toUpperCase(), style: text.labelSmall?.copyWith(color: p.muted)),
                        const SizedBox(height: 4),
                        Text(title, style: text.headlineMedium),
                        const SizedBox(height: 2),
                        Text(subtitle, style: text.bodyMedium?.copyWith(color: p.muted)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.ink),
                    child: const Icon(AppIcons.scan, color: Colors.white, size: 28),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            AppCard(
              radius: Dimens.rLg,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(child: Text(actionLabel, style: text.labelLarge?.copyWith(color: AppColors.ink, fontSize: 15))),
            ),
          ],
        ),
      ),
    );
  }
}
