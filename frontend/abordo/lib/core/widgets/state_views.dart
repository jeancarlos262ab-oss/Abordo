import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_exception.dart';
import '../theme/app_colors.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../theme/app_theme.dart';
import 'app_button.dart';
import 'app_card.dart';
import '../theme/app_icons.dart';

/// Carga con "esqueletos" (skeletonizer): tarjetas fantasma con pulso suave, sin giradores genéricos
/// ni brillos con degradado. Anuncia [message] a los lectores de pantalla.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message = 'Cargando…'});
  final String message;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      liveRegion: true,
      label: message,
      child: ExcludeSemantics(
        child: Skeletonizer(
          enabled: true,
          effect: PulseEffect(from: p.field, to: p.border),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < 3; i++) ...[
                  if (i > 0) const SizedBox(height: 12),
                  AppCard(
                    radius: Dimens.rXl,
                    child: Row(
                      children: [
                        const Bone.circle(size: 48),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Bone.text(words: 2),
                              SizedBox(height: 8),
                              Bone.text(words: 5, fontSize: 12),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Pantalla de mensaje con icono en un círculo suave (vacío, error, aviso).
class MessageView extends StatelessWidget {
  const MessageView({super.key, required this.icon, required this.message, this.actionLabel, this.onAction});
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(color: p.accentSoft, shape: BoxShape.circle),
              child: Icon(icon, size: 42, color: AppColors.ink),
            ),
            const SizedBox(height: 22),
            Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5)),
            if (onAction != null) ...[
              const SizedBox(height: 26),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: AppButton(label: actionLabel ?? 'Reintentar', icon: AppIcons.refresh, onPressed: onAction),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Convierte un AsyncValue en carga / error con "Reintentar" / contenido.
/// Mantiene el dato anterior visible mientras se refresca (sin parpadeos).
class AsyncValueView<T> extends StatelessWidget {
  const AsyncValueView({super.key, required this.value, required this.data, this.onRetry});
  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => value.when(
        skipLoadingOnReload: true,
        data: data,
        loading: () => const LoadingView(),
        error: (e, _) => MessageView(icon: AppIcons.wifiSlash, message: friendlyError(e), onAction: onRetry),
      );
}
