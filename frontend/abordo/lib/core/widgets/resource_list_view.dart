import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';
import 'state_views.dart';
import '../theme/app_icons.dart';

/// Lista administrable (unidades, choferes): carga/error/vacío, jalar para actualizar
/// y un botón flotante con TEXTO ("Agregar unidad"), no solo un "+".
class ResourceListView<T> extends StatelessWidget {
  const ResourceListView({
    super.key,
    required this.value,
    required this.onRefresh,
    required this.itemBuilder,
    required this.emptyIcon,
    required this.emptyMessage,
    required this.addLabel,
    required this.onAdd,
  });

  final AsyncValue<List<T>> value;
  final Future<void> Function() onRefresh;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final IconData emptyIcon;
  final String emptyMessage;
  final String addLabel;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AsyncValueView<List<T>>(
          value: value,
          onRetry: onRefresh,
          data: (items) => items.isEmpty
              ? MessageView(icon: emptyIcon, message: emptyMessage, actionLabel: addLabel, onAction: onAdd)
              : RefreshIndicator(
                  onRefresh: onRefresh,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(Dimens.pagePadding, 4, Dimens.pagePadding, 120),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: Dimens.gap + 2),
                    itemBuilder: (ctx, i) => itemBuilder(ctx, items[i]),
                  ),
                ),
        ),
        if (value.valueOrNull?.isNotEmpty ?? false)
          Positioned(
            right: Dimens.pagePadding,
            bottom: 20,
            child: FloatingActionButton.extended(
              onPressed: onAdd,
              icon: const Icon(AppIcons.plus, size: 26),
              label: Text(addLabel, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: const Color(0xFF161314))),
            ),
          ),
      ],
    );
  }
}
