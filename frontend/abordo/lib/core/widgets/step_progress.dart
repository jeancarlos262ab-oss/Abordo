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
        children: [
          for (var i = 0; i < 3; i++) ...[
            if (i > 0)
              Expanded(
                child: Container(height: 3, margin: const EdgeInsets.only(bottom: 18), decoration: BoxDecoration(color: i < current ? AppColors.pink : AppColors.graphite)),
              ),
            Column(
              children: [
                _Dot(index: i + 1, state: i + 1 < current ? _S.done : (i + 1 == current ? _S.now : _S.next)),
                const SizedBox(height: 4),
                Text(_labels[i], style: text.bodySmall?.copyWith(color: i + 1 <= current ? Colors.white : AppColors.grey, fontWeight: FontWeight.w700)),
              ],
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
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: filled ? AppColors.pink : AppColors.graphite,
      ),
      child: state == _S.done
          ? const Icon(Icons.check_rounded, size: 18, color: AppColors.ink)
          : Text('$index', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: filled ? AppColors.ink : Colors.white70)),
    );
  }
}
