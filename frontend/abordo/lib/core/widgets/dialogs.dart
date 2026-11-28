import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'app_button.dart';
import '../theme/app_icons.dart';

/// Diálogo con la forma de la app: icono en círculo, título, contenido y botones apilados.
/// Los botones llegan a todo lo ancho, fáciles de tocar con una sola mano.
class AppDialog extends StatelessWidget {
  const AppDialog({
    super.key,
    required this.title,
    required this.actions,
    this.icon,
    this.iconColor,
    this.iconBackground,
    this.message,
    this.child,
  });

  final String title;
  final String? message;
  final Widget? child;
  final IconData? icon;
  final Color? iconColor;
  final Color? iconBackground;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Dialog(
      backgroundColor: p.background,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimens.rXl)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (icon != null) ...[
                Center(
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(color: iconBackground ?? p.accentSoft, shape: BoxShape.circle),
                    child: Icon(icon, size: 22, color: iconColor ?? p.text),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              Semantics(header: true, child: Text(title, textAlign: TextAlign.center, style: text.titleLarge)),
              if (message != null) ...[
                const SizedBox(height: 6),
                Text(message!, textAlign: TextAlign.center, style: text.bodyMedium?.copyWith(color: p.muted)),
              ],
              if (child != null) ...[const SizedBox(height: 12), child!],
              const SizedBox(height: 16),
              for (var i = 0; i < actions.length; i++) ...[
                if (i > 0) const SizedBox(height: 8),
                actions[i],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Pregunta de sí/no con botones grandes. Devuelve true si la persona confirma.
Future<bool> confirm(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Mejor no',
  bool danger = false,
  IconData? icon,
}) async {
  final p = context.palette;
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AppDialog(
      icon: icon ?? (danger ? AppIcons.warning : AppIcons.help),
      iconColor: danger ? p.danger : null,
      iconBackground: danger ? p.dangerSoft : null,
      title: title,
      message: message,
      actions: [
        AppButton(
          label: confirmLabel,
          kind: danger ? ButtonKind.danger : ButtonKind.primary,
          onPressed: () => Navigator.pop(ctx, true),
        ),
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
    showDragHandle: true,
    constraints: const BoxConstraints(maxWidth: Dimens.maxContentWidth),
    builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(Dimens.pagePadding, 0, Dimens.pagePadding, MediaQuery.viewInsetsOf(ctx).bottom + 16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(child: Semantics(header: true, child: Text(title, style: Theme.of(ctx).textTheme.titleLarge))),
                IconButton(
                  tooltip: 'Cerrar',
                  onPressed: () => Navigator.of(ctx).maybePop(),
                  style: IconButton.styleFrom(fixedSize: const Size.square(36)),
                  icon: const Icon(AppIcons.close, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 10),
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
            Icon(error ? AppIcons.warningCircle : AppIcons.checkCircle, color: error ? AppColors.dangerBright : AppColors.successBright),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
}
