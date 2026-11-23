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
  );
  if (ok) await ref.read(sessionProvider.notifier).logout();
}

/// Botón "Salir" con texto visible para la barra superior.
class LogoutAction extends ConsumerWidget {
  const LogoutAction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => TextButton.icon(
        onPressed: () => confirmLogout(context, ref),
        icon: const Icon(Icons.logout_rounded),
        label: const Text('Salir'),
      );
}
