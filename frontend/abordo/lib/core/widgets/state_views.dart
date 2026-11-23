import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_exception.dart';
import 'app_button.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message = 'Cargando…'});
  final String message;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(strokeWidth: 5),
              const SizedBox(height: 20),
              Text(message, style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
        ),
      );
}

/// Pantalla de mensaje con icono grande (vacío, error, aviso).
class MessageView extends StatelessWidget {
  const MessageView({super.key, required this.icon, required this.message, this.actionLabel, this.onAction});
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: scheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
            if (onAction != null) ...[
              const SizedBox(height: 24),
              AppButton(label: actionLabel ?? 'Reintentar', icon: Icons.refresh_rounded, onPressed: onAction),
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
