import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/dates.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/page_scaffold.dart';
import '../../../core/widgets/pulse_dot.dart';
import '../../../core/widgets/state_views.dart';
import '../../auth/state/session_controller.dart';
import '../../auth/ui/logout_button.dart';
import '../domain/driver_models.dart';
import '../state/driver_providers.dart';
import 'active_shift_view.dart';
import 'unit_picker.dart';

/// Pantalla del chofer: o elige unidad para empezar, o ve su turno en marcha.
class DriverHomePage extends ConsumerWidget {
  const DriverHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(sessionProvider).valueOrNull?.user.firstName ?? '';
    final shift = ref.watch(shiftProvider);
    return PageScaffold(
      title: 'Hola, $name',
      showBack: false,
      actions: const [LogoutAction()],
      hero: _ShiftHero(shift: shift.valueOrNull),
      child: AsyncValueView<ShiftState>(
        value: shift,
        onRetry: () => ref.invalidate(shiftProvider),
        data: (s) => s.isActive ? ActiveShiftView(shift: s) : const UnitPicker(),
      ),
    );
  }
}

/// Cifra principal del turno en la cabecera: es lo único que el chofer necesita de un vistazo.
class _ShiftHero extends StatelessWidget {
  const _ShiftHero({required this.shift});
  final ShiftState? shift;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final s = shift;
    if (s == null || !s.isActive) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Listo para\nempezar', style: text.headlineMedium),
          const SizedBox(height: 6),
          Text('Elige tu unidad para abrir turno.', style: text.bodyLarge?.copyWith(color: AppColors.silver)),
        ],
      );
    }
    return Semantics(
      label: 'En turno ${s.unit!.label}. Cobrado ${Money.format(s.amountCents)}, ${s.count} pasajeros.',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const PulseDot(),
              const SizedBox(width: 4),
              Expanded(child: Text('En turno · ${s.unit!.label} · ${s.unit!.route}', style: text.titleMedium, overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(Money.format(s.amountCents), style: text.displaySmall?.copyWith(fontSize: 46))),
          Text('${s.count} ${s.count == 1 ? 'pasajero' : 'pasajeros'} · desde las ${AppDates.time(s.startedAt!)}', style: text.bodyLarge?.copyWith(color: AppColors.silver)),
        ],
      ),
    );
  }
}
