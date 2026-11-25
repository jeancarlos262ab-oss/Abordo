import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_exception.dart';
import '../theme/app_colors.dart';
import 'app_button.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message = 'Cargando…'});
  final String message;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Semantics(
            liveRegion: true,
            label: message,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(width: 36, height: 36, child: CircularProgressIndicator(strokeWidth: 3.5)),
                const SizedBox(height: 18),
                Text(message, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: context.palette.muted)),
              ],
            ),
          ),
        ),
      );
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
              child: Icon(icon, size: 42, color: Theme.of(context).brightness == Brightness.dark ? AppColors.pink : AppColors.ink),
            ),
            const SizedBox(height: 22),
            Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5)),
            if (onAction != null) ...[
              const SizedBox(height: 26),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: AppButton(label: actionLabel ?? 'Reintentar', icon: Icons.refresh_rounded, onPressed: onAction),
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
        error: (e, _) => MessageView(icon: Icons.wifi_off_rounded, message: friendlyError(e), onAction: onRetry),
      );
}
