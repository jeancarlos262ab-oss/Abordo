import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'app_card.dart';
import 'qr_mark.dart';

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
                child: Icon(Icons.arrow_forward_rounded, size: 20, color: p.text),
              ),
        ],
      ),
    );
  }
}

/// La acción principal de la pantalla de inicio: tarjeta rosa de marca con un QR que se escanea.
/// Siempre usa tinta sobre rosa, sin importar el tema.
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
    final r = BorderRadius.circular(Dimens.rXl);
    return Semantics(
      button: true,
      container: true,
      label: '$title. $subtitle',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: r,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFAC6D8), AppColors.pink, Color(0xFFF1A0BF)],
          ),
          boxShadow: const [BoxShadow(color: Color(0x40E97FA7), blurRadius: 28, offset: Offset(0, 14))],
        ),
        child: Material(
          type: MaterialType.transparency,
          borderRadius: r,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            borderRadius: r,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 18, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(color: AppColors.ink.withOpacity(.1), borderRadius: BorderRadius.circular(99)),
                              child: Text(eyebrow.toUpperCase(), style: text.labelSmall?.copyWith(color: AppColors.ink)),
                            ),
                            const SizedBox(height: 14),
                            Text(title, style: text.headlineMedium?.copyWith(color: AppColors.ink)),
                            const SizedBox(height: 6),
                            Text(subtitle, style: text.bodyLarge?.copyWith(color: AppColors.ink.withOpacity(.78))),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Transform.rotate(angle: .1, child: const QrMark(size: 84)),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    height: Dimens.buttonHeight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(Dimens.rMd)),
                    child: Row(
                      children: [
                        Expanded(child: Text(actionLabel, style: text.labelLarge?.copyWith(color: Colors.white))),
                        const Icon(Icons.arrow_forward_rounded, color: AppColors.pink, size: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
