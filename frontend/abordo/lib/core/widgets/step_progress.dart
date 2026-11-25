import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Pasos del pago (Código → Confirmar → Pagar). `current` 1..3; con 4 todos quedan completos.
/// Pensada para ir sobre el hero oscuro.
class StepProgress extends StatelessWidget {
  const StepProgress({super.key, required this.current});
  final int current;

  static const _labels = ['Código', 'Confirmar', 'Pagar'];

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
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
                  padding: const EdgeInsets.only(top: 15),
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: i < current ? AppColors.pink : Colors.white.withOpacity(.16),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            SizedBox(
              width: 64,
              child: Column(
                children: [
                  _Dot(index: i + 1, state: i + 1 < current ? _S.done : (i + 1 == current ? _S.now : _S.next)),
                  const SizedBox(height: 6),
                  Text(
                    _labels[i],
                    textAlign: TextAlign.center,
                    style: text.bodySmall?.copyWith(color: i + 1 <= current ? Colors.white : Colors.white.withOpacity(.55)),
                  ),
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
  const _Dot({required this.index, required this.state});
  final int index;
  final _S state;

  @override
  Widget build(BuildContext context) {
    final filled = state != _S.next;
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? AppColors.pink : Colors.white.withOpacity(.12),
        boxShadow: state == _S.now ? [BoxShadow(color: AppColors.pink.withOpacity(.35), spreadRadius: 5)] : null,
      ),
      child: state == _S.done
          ? const Icon(Icons.check_rounded, size: 20, color: AppColors.ink)
          : Text(
              '$index',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(color: filled ? AppColors.ink : Colors.white.withOpacity(.7)),
            ),
    );
  }
}
