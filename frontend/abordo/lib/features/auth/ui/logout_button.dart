import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/dialogs.dart';
import '../state/session_controller.dart';
import '../../../core/theme/app_icons.dart';

/// Pregunta antes de cerrar sesión y la cierra. Compartida por chofer y dueño.
Future<void> confirmLogout(BuildContext context, WidgetRef ref) async {
  final ok = await confirm(
    context,
    title: '¿Salir de tu cuenta?',
    message: 'Tendrás que volver a escribir tu usuario.',
    confirmLabel: 'Sí, salir',
    icon: AppIcons.signOut,
  );
  if (ok) await ref.read(sessionProvider.notifier).logout();
}

/// Botón de salir: solo el icono, sin fondo, pensado para la cabecera rosa del chofer.
class LogoutAction extends ConsumerWidget {
  const LogoutAction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => IconButton(
        onPressed: () => confirmLogout(context, ref),
        tooltip: 'Salir',
        iconSize: 26,
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        icon: const Icon(AppIcons.signOut),
      );
}
