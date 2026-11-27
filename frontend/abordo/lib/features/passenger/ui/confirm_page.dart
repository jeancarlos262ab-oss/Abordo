import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/labeled_field.dart';
import '../../../core/widgets/page_scaffold.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../core/widgets/submit_mixin.dart';
import '../../../core/widgets/ticket_card.dart';
import '../../auth/domain/session.dart';
import '../../auth/state/session_controller.dart';
import '../domain/passenger_models.dart';
import '../state/passenger_providers.dart';
import 'pay_page.dart';
import '../../../core/theme/app_icons.dart';

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
          Text('Confirma\ntu pasaje', style: text.headlineMedium?.copyWith(color: AppColors.ink)),
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
  bool _wantsPhone = false;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  void _togglePhone(bool on) {
    setState(() => _wantsPhone = on);
    if (!on) _phone.clear(); // oculto = no se envía ningún número
  }

  Future<void> _pay() async {
    Charge? charge;
    final ok = await submit(() async {
      // Sin número escrito, un pasajero con sesión paga con el celular de su cuenta vinculada.
      var phone = _phone.text.trim();
      if (phone.isEmpty && ref.read(sessionProvider).valueOrNull?.user.role == Role.passenger) {
        final linked = ref.read(passengerProfileProvider).valueOrNull?.account?.phone ?? '';
        if (RegExp(r'^\d{10}$').hasMatch(linked)) phone = linked;
      }
      charge = await ref.read(passengerRepositoryProvider).createCharge(widget.unit.code, payerPhone: phone);
    });
    if (ok && mounted) {
      await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => PayPage(initial: charge!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final u = widget.unit;
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            label: '${u.label}, ${u.route}, pasaje de ${Money.spoken(u.fareCents)}',
            excludeSemantics: true,
            child: TicketCard(
              strip: Row(
                children: [
                  Expanded(child: Text(u.label, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800), overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 10),
                  Text('CoDi', style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                ],
              ),
              top: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('TU UNIDAD', style: text.labelSmall?.copyWith(color: p.muted)),
                        const SizedBox(height: 2),
                        Text(u.label, style: text.titleLarge),
                        Text(u.route, style: text.bodyMedium?.copyWith(color: p.muted)),
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
                        Text('PASAJE', style: text.labelSmall?.copyWith(color: p.muted)),
                        const SizedBox(height: 2),
                        FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(Money.format(u.fareCents), style: text.displayMedium)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const StatusChip(label: 'Sin comisión', good: true),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (!u.acceptsPayments)
            AppCard(
              color: p.dangerSoft,
              shadow: false,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(AppIcons.info, color: p.danger),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Esta unidad todavía no recibe pagos con CoDi. Paga en efectivo con el chofer.', style: text.bodyLarge)),
                ],
              ),
            )
          else ...[
            _PhoneOption(
              expanded: _wantsPhone,
              onChanged: _togglePhone,
              field: LabeledField(
                label: 'Tu número de celular',
                helper: 'Te llegará el aviso de pago a tu app del banco.',
                icon: AppIcons.phone,
                controller: _phone,
                digitsOnly: true,
                maxLength: 10,
                textInputAction: TextInputAction.done,
                validator: Validators.optional(Validators.digits(10, 10, 'El celular')),
              ),
            ),
            const SizedBox(height: 20),
            AppButton(label: 'Pagar ${Money.format(u.fareCents)} con CoDi', icon: AppIcons.money, loading: busy, onPressed: _pay),
          ],
        ],
      ),
    );
  }
}

/// Opción para recibir el cobro en el celular: interruptor claro y el campo aparece debajo.
class _PhoneOption extends StatelessWidget {
  const _PhoneOption({required this.expanded, required this.onChanged, required this.field});
  final bool expanded;
  final ValueChanged<bool> onChanged;
  final Widget field;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            toggled: expanded,
            label: '¿Prefieres recibir el cobro en tu celular?',
            child: InkWell(
              borderRadius: BorderRadius.circular(Dimens.rSm),
              onTap: () => onChanged(!expanded),
              child: Row(
                children: [
                  Expanded(child: Text('¿Prefieres recibir el cobro en tu celular?', style: text.titleMedium)),
                  const SizedBox(width: 8),
                  ExcludeSemantics(child: Switch(value: expanded, onChanged: onChanged)),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: expanded
                ? Padding(padding: const EdgeInsets.only(top: 16, right: 4), child: field)
                : const SizedBox(width: double.infinity),
          ),
          if (!expanded) Padding(padding: const EdgeInsets.only(right: 56), child: Text('Opcional', style: text.bodySmall?.copyWith(color: p.muted))),
        ],
      ),
    );
  }
}
