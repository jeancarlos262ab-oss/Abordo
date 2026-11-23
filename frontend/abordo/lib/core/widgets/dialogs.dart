import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'app_button.dart';

/// Pregunta de sí/no con botones grandes. Devuelve true si la persona confirma.
Future<bool> confirm(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Mejor no',
  bool danger = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: const RoundedRectangleBorder(),
      title: Text(title),
      content: Text(message),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      actionsOverflowDirection: VerticalDirection.down,
      actions: [
        AppButton(
          label: confirmLabel,
          kind: danger ? ButtonKind.danger : ButtonKind.primary,
          onPressed: () => Navigator.pop(ctx, true),
        ),
        const SizedBox(height: 8),
        AppButton(label: cancelLabel, kind: ButtonKind.secondary, onPressed: () => Navigator.pop(ctx, false)),
      ],
    ),
  );
  return result ?? false;
}

/// Hoja inferior para formularios. Se ajusta al teclado y hace scroll si hace falta.
Future<T?> showFormSheet<T>(BuildContext context, {required String title, required WidgetBuilder builder}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(Dimens.pagePadding, 0, Dimens.pagePadding, MediaQuery.viewInsetsOf(ctx).bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: Theme.of(ctx).textTheme.headlineSmall),
            const SizedBox(height: 20),
            builder(ctx),
          ],
        ),
      ),
    ),
  );
}

/// Mensaje breve en la parte baja. Los errores llevan icono para no depender solo del color.
void showMessage(BuildContext context, String message, {bool error = false}) =>
    showMessageOn(ScaffoldMessenger.of(context), message, error: error);

/// Igual que [showMessage] pero con el messenger ya capturado: sirve cuando la pantalla
/// que lo pide se cierra justo antes de mostrar el aviso (p. ej. una hoja de formulario).
void showMessageOn(ScaffoldMessengerState messenger, String message, {bool error = false}) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        content: Row(
          children: [
            Icon(error ? Icons.error_rounded : Icons.check_circle_rounded, color: error ? AppColors.danger : AppColors.success),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
}
