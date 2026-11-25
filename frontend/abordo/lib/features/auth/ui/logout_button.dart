import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/dialogs.dart';
import '../state/session_controller.dart';

/// Pregunta antes de cerrar sesión y la cierra. Compartida por chofer y dueño.
Future<void> confirmLogout(BuildContext context, WidgetRef ref) async {
  final ok = await confirm(
    context,
    title: '¿Salir de tu cuenta?',
    message: 'Tendrás que volver a escribir tu usuario.',
    confirmLabel: 'Sí, salir',
    icon: Icons.logout_rounded,
  );
  if (ok) await ref.read(sessionProvider.notifier).logout();
}

/// Botón "Salir" con texto visible, pensado para la cabecera oscura.
class LogoutAction extends ConsumerWidget {
  const LogoutAction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => TextButton.icon(
        onPressed: () => confirmLogout(context, ref),
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.white.withOpacity(.12),
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: const StadiumBorder(),
          textStyle: Theme.of(context).textTheme.labelMedium,
        ),
        icon: const Icon(Icons.logout_rounded, size: 20),
        label: const Text('Salir'),
      );
}
