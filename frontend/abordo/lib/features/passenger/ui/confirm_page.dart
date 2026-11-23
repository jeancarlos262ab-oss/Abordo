import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../core/widgets/step_progress.dart';
import '../../../core/widgets/ticket_card.dart';
import '../../../core/widgets/labeled_field.dart';
import '../../../core/widgets/page_scaffold.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/submit_mixin.dart';
import '../domain/passenger_models.dart';
import '../state/passenger_providers.dart';
import 'pay_page.dart';

/// Paso 2: confirmar unidad y precio. Un solo botón principal.
class ConfirmPage extends ConsumerWidget {
  const ConfirmPage({super.key, required this.code});
  final String code;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unit = ref.watch(unitProvider(code));
    final text = Theme.of(context).textTheme;
    return PageScaffold(
      title: 'Pagar mi pasaje',
      hero: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Confirma\ntu pasaje', style: text.headlineMedium),
          const SizedBox(height: 22),
          const StepProgress(current: 2),
        ],
      ),
      child: AsyncValueView<UnitInfo>(
        value: unit,
        onRetry: () => ref.invalidate(unitProvider(code)),
        data: (u) => _Confirm(unit: u),
      ),
    );
  }
}

class _Confirm extends ConsumerStatefulWidget {
  const _Confirm({required this.unit});
  final UnitInfo unit;

  @override
  ConsumerState<_Confirm> createState() => _ConfirmState();
}

class _ConfirmState extends ConsumerState<_Confirm> with SubmitMixin<_Confirm> {
  final _phone = TextEditingController();

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    Charge? charge;
    final ok = await submit(() async {
      charge = await ref.read(passengerRepositoryProvider).createCharge(widget.unit.code, payerPhone: _phone.text.trim());
    });
    if (ok && mounted) {
      await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => PayPage(initial: charge!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final u = widget.unit;
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            label: '${u.label}, ${u.route}, pasaje de ${Money.spoken(u.fareCents)}',
            excludeSemantics: true,
            child: TicketCard(
              top: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(color: AppColors.graphite),
                    child: Icon(Icons.directions_bus_rounded, size: 26, color: scheme.onSurface),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(u.label, style: text.titleLarge),
                        Text(u.route, style: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ],
              ),
              bottom: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Pasaje', style: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant)),
                        Text(Money.format(u.fareCents), style: text.displaySmall),
                      ],
                    ),
                  ),
                  const StatusChip(label: 'Sin comisión', good: true),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (!u.acceptsPayments)
            Text('Esta unidad todavía no recibe pagos con CoDi. Paga en efectivo con el chofer.', style: text.bodyLarge)
          else ...[
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text('¿Prefieres recibir el cobro en tu celular?', style: text.titleMedium),
                childrenPadding: const EdgeInsets.only(top: 8),
                children: [
                  LabeledField(
                    label: 'Tu número de celular',
                    helper: 'Te llegará el aviso de pago a tu app del banco.',
                    controller: _phone,
                    digitsOnly: true,
                    maxLength: 10,
                    textInputAction: TextInputAction.done,
                    validator: Validators.optional(Validators.digits(10, 10, 'El celular')),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AppButton(label: 'Pagar ${Money.format(u.fareCents)} con CoDi', icon: Icons.payments_rounded, loading: busy, onPressed: _pay),
          ],
        ],
      ),
    );
  }
}
