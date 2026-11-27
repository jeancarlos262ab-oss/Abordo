import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_icons.dart';

/// Pasos del pago (Código → Confirmar → Pagar). `current` 1..3; con 4 todos quedan completos.
/// Pensada para ir sobre el hero oscuro.
class StepProgress extends StatelessWidget {
  const StepProgress({super.key, required this.current});
  final int current;

  static const _labels = ['Código', 'Confirmar', 'Pagar'];
  static const _icons = [AppIcons.scan, AppIcons.checklist, AppIcons.money];

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: current > 3 ? 'Pago completado' : 'Paso $current de 3: ${_labels[current - 1]}',
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < 3; i++) ...[
            if (i > 0)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 21),
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: i < current ? AppColors.ink : Colors.black.withOpacity(.08),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            SizedBox(
              width: 46,
              child: Column(
                children: [
                  _Dot(icon: _icons[i], state: i + 1 < current ? _S.done : (i + 1 == current ? _S.now : _S.next)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

enum _S { done, now, next }

class _Dot extends StatelessWidget {
  const _Dot({required this.icon, required this.state});
  final IconData icon;
  final _S state;

  @override
  Widget build(BuildContext context) {
    final filled = state != _S.next;
    return Container(
      width: 46,
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? AppColors.ink : Colors.black.withOpacity(.08),
        boxShadow: state == _S.now ? [BoxShadow(color: Colors.black.withOpacity(.08), spreadRadius: 5)] : null,
      ),
      child: Icon(
        state == _S.done ? AppIcons.check : icon,
        size: 24,
        color: state == _S.done ? AppColors.rose : (filled ? AppColors.rose : AppColors.graphite),
      ),
    );
  }
}
