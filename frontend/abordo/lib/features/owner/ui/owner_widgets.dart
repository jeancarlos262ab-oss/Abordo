import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/state_views.dart';

/// Tonos del panel del dueño. La idea: el contenido vive directo sobre el fondo de la pantalla
/// (nada de tarjetas blancas); lo que necesita destacar usa una superficie de tinta oscura.
extension OwnerTones on BuildContext {
  AppPalette get _p => Theme.of(this).extension<AppPalette>() ?? AppPalette.light;

  bool get isDarkTheme => Theme.of(this).brightness == Brightness.dark;

  /// Color de texto principal (tinta en claro, blanco cálido en oscuro).
  Color get inkColor => _p.text;

  /// La tinta con transparencia: sirve para rellenos suaves y líneas sobre el fondo.
  Color inkAt(double opacity) => _p.text.withOpacity(opacity);

  /// Línea fina de separación entre filas.
  Color get hairline => _p.text.withOpacity(.14);

  /// Superficie oscura para lo más importante de la pantalla (cifra del día, barra inferior).
  Color get panelColor => isDarkTheme ? _p.card : AppColors.ink;

  /// Botones rellenos: tinta con texto rosa en claro; rosa con texto tinta en oscuro.
  Color get buttonBg => isDarkTheme ? AppColors.rose : AppColors.ink;
  Color get buttonFg => isDarkTheme ? AppColors.ink : AppColors.rose;

  /// Rojo con contraste suficiente sobre el fondo rosa.
  Color get dangerInk => isDarkTheme ? _p.danger : const Color(0xFF7A0F3A);
}

/// Línea fina entre filas de una lista abierta.
class OwnerDivider extends StatelessWidget {
  const OwnerDivider({super.key, this.indent = 0});
  final double indent;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(left: indent),
        child: Container(height: .8, color: context.hairline),
      );
}

/// "Juan Pérez" -> "JP". Con [max] = 1 devuelve solo la inicial.
String initialsOf(String name, {int max = 2}) {
  final parts = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  final buf = StringBuffer();
  for (final w in parts.take(max)) {
    buf.write(w[0]);
  }
  return buf.toString().toUpperCase();
}

/// Iniciales sobre un círculo de tinta (o apagado si la persona no tiene acceso).
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({super.key, required this.name, this.size = 56, this.active = true, this.letters = 2});
  final String name;
  final double size;
  final bool active;
  final int letters;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(shape: BoxShape.circle, color: active ? context.buttonBg : context.inkAt(.1)),
        child: Text(
          initialsOf(name, max: letters),
          style: text.titleLarge?.copyWith(
            color: active ? context.buttonFg : context.inkAt(.55),
            fontSize: size * .36,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

/// Estado con punto de color y texto (nunca solo color).
class StateTag extends StatelessWidget {
  const StateTag({super.key, required this.label, required this.on});
  final String label;
  final bool on;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(9, 5, 12, 5),
      decoration: BoxDecoration(color: context.inkAt(.08), borderRadius: BorderRadius.circular(99)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: on ? AppColors.success : context.inkAt(.35)),
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(color: context.inkColor),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Etiqueta con solo contorno y un icono.
class OutlineChip extends StatelessWidget {
  const OutlineChip({super.key, required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 5, 13, 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: context.inkAt(.3), width: .8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: context.inkColor),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(color: context.inkColor),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Botón grande de ancho completo: tinta con texto rosa.
class InkButton extends StatelessWidget {
  const InkButton({super.key, required this.label, required this.onPressed, this.icon, this.loading = false});
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final bg = context.buttonBg;
    final fg = context.buttonFg;
    final enabled = onPressed != null && !loading;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: SizedBox(
        height: 54,
        width: double.infinity,
        child: Material(
          color: (enabled || loading) ? bg : bg.withOpacity(.4),
          shape: const StadiumBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: enabled
                ? () {
                    HapticFeedback.lightImpact();
                    onPressed!();
                  }
                : null,
            child: Center(
              child: loading
                  ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.6, color: fg))
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[Icon(icon, size: 20, color: fg), const SizedBox(width: 8)],
                        Flexible(
                          child: Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: fg), overflow: TextOverflow.ellipsis),
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

/// Botón compacto en forma de píldora: relleno de tinta o solo contorno.
class PillButton extends StatelessWidget {
  const PillButton({super.key, required this.label, required this.onPressed, this.icon, this.filled = false});
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final fg = filled ? context.buttonFg : context.inkColor;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: filled ? context.buttonBg : Colors.transparent,
        shape: StadiumBorder(side: filled ? BorderSide.none : BorderSide(color: context.inkAt(.3), width: 1)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed == null
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  onPressed!();
                },
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[Icon(icon, size: 18, color: fg), const SizedBox(width: 8)],
                  Flexible(child: Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: fg), overflow: TextOverflow.ellipsis)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Acción rápida: icono en un círculo y su nombre debajo. Sin contenedor alrededor.
class QuickAction extends StatelessWidget {
  const QuickAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.semanticLabel,
    this.primary = false,
    this.loading = false,
  });
  final IconData icon;
  final String label;
  final String? semanticLabel;
  final VoidCallback onTap;
  final bool primary;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final fg = primary ? context.buttonFg : context.inkColor;
    return Semantics(
      button: true,
      label: semanticLabel ?? label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: loading
            ? null
            : () {
                HapticFeedback.selectionClick();
                onTap();
              },
        radius: 44,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 54,
                height: 54,
                alignment: Alignment.center,
                decoration: BoxDecoration(shape: BoxShape.circle, color: primary ? context.buttonBg : context.inkAt(.08)),
                child: loading
                    ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: fg))
                    : Icon(icon, size: 22, color: fg),
              ),
              const SizedBox(height: 6),
              Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: context.inkColor), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}

/// Contorno de cada elemento de una lista: solo borde (sin relleno), para no perder dónde
/// empieza y termina cada unidad o chofer.
class OwnerItemBox extends StatelessWidget {
  const OwnerItemBox({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Dimens.rLg),
        border: Border.all(color: context.inkAt(.32), width: 1),
      ),
      child: child,
    );
  }
}

/// Título de una lista: cantidad grande y una línea de apoyo.
class OwnerListHeader extends StatelessWidget {
  const OwnerListHeader({super.key, required this.title, this.subtitle});
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 6, 0, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: text.displaySmall),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!, style: text.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ],
      ),
    );
  }
}

/// Estilo de los campos sobre el fondo rosa: relleno suave de tinta en lugar de blanco.
InputDecorationTheme ownerInputTheme(BuildContext context) {
  final text = Theme.of(context).textTheme;
  final scheme = Theme.of(context).colorScheme;
  final danger = scheme.error;
  OutlineInputBorder border(Color color, [double width = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(Dimens.rMd),
        borderSide: BorderSide(color: color, width: width),
      );
  return InputDecorationTheme(
    filled: true,
    fillColor: context.inkAt(.07),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    border: border(Colors.transparent),
    enabledBorder: border(Colors.transparent),
    focusedBorder: border(context.inkColor, 1.5),
    errorBorder: border(danger),
    focusedErrorBorder: border(danger, 1.5),
    hintStyle: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant.withOpacity(.75)),
    errorStyle: text.titleSmall?.copyWith(color: danger),
    errorMaxLines: 3,
    prefixIconColor: scheme.onSurfaceVariant,
    suffixIconColor: scheme.onSurfaceVariant,
  );
}

/// Carga con esqueletos sin tarjetas: filas fantasma sobre el fondo.
class OwnerSkeleton extends StatelessWidget {
  const OwnerSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: 'Cargando…',
      child: ExcludeSemantics(
        child: Skeletonizer(
          enabled: true,
          effect: PulseEffect(from: context.inkAt(.07), to: context.inkAt(.15)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < 4; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
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
                            Bone.text(words: 4, fontSize: 12),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Bone.text(words: 1),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Como `AsyncValueView`, pero con la carga propia del panel (sin tarjetas blancas).
class OwnerAsync<T> extends StatelessWidget {
  const OwnerAsync({super.key, required this.value, required this.data, this.onRetry, this.loading});
  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback? onRetry;
  final Widget? loading;

  @override
  Widget build(BuildContext context) => value.when(
        skipLoadingOnReload: true,
        data: data,
        loading: () => loading ?? const OwnerSkeleton(),
        error: (e, _) => MessageView(icon: AppIcons.wifiSlash, message: friendlyError(e), onAction: onRetry),
      );
}

/// Lista abierta (unidades, choferes): encabezado con cantidades, filas separadas por una línea
/// fina, jalar para actualizar y un botón de tinta con TEXTO para agregar.
class OwnerList<T> extends StatelessWidget {
  const OwnerList({
    super.key,
    required this.value,
    required this.onRefresh,
    required this.header,
    required this.itemBuilder,
    required this.emptyIcon,
    required this.emptyMessage,
    required this.addLabel,
    required this.onAdd,
  });

  final AsyncValue<List<T>> value;
  final Future<void> Function() onRefresh;
  final Widget Function(BuildContext context, List<T> items) header;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final IconData emptyIcon;
  final String emptyMessage;
  final String addLabel;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Stack(
      children: [
        OwnerAsync<List<T>>(
          value: value,
          onRetry: onRefresh,
          loading: const Padding(padding: EdgeInsets.symmetric(horizontal: Dimens.pagePadding), child: OwnerSkeleton()),
          data: (items) => items.isEmpty
              ? MessageView(icon: emptyIcon, message: emptyMessage, actionLabel: addLabel, onAction: onAdd)
              : RefreshIndicator(
                  color: AppColors.rose,
                  backgroundColor: context.panelColor,
                  onRefresh: onRefresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(Dimens.pagePadding, 0, Dimens.pagePadding, 110),
                    children: [
                      header(context, items),
                      const SizedBox(height: 10),
                      for (var i = 0; i < items.length; i++) ...[
                        if (i > 0) const SizedBox(height: 12),
                        OwnerItemBox(child: itemBuilder(context, items[i])),
                      ],
                    ],
                  ),
                ),
        ),
        if (value.valueOrNull?.isNotEmpty ?? false)
          Positioned(
            right: Dimens.pagePadding,
            bottom: 16,
            child: FloatingActionButton.extended(
              onPressed: onAdd,
              elevation: 0,
              focusElevation: 0,
              hoverElevation: 0,
              highlightElevation: 0,
              shape: const StadiumBorder(),
              backgroundColor: context.buttonBg,
              foregroundColor: context.buttonFg,
              icon: const Icon(AppIcons.plus, size: 22),
              label: Text(addLabel, style: text.labelLarge?.copyWith(color: context.buttonFg)),
            ),
          ),
      ],
    );
  }
}
