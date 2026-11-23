import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/labeled_field.dart';
import '../../../core/widgets/resource_list_view.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../core/widgets/submit_mixin.dart';
import '../domain/owner_models.dart';
import '../state/owner_providers.dart';
import 'unit_qr_page.dart';

Future<void> _openForm(BuildContext context, {OwnerUnit? unit}) => showFormSheet<void>(
      context,
      title: unit == null ? 'Nueva unidad' : 'Editar unidad',
      builder: (_) => _UnitForm(unit: unit),
    );

class UnitsTab extends ConsumerWidget {
  const UnitsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => ResourceListView<OwnerUnit>(
        value: ref.watch(unitsProvider),
        onRefresh: () async => ref.invalidate(unitsProvider),
        emptyIcon: Icons.directions_bus_outlined,
        emptyMessage: 'Aún no tienes unidades. Agrega la primera para generar su código QR.',
        addLabel: 'Agregar unidad',
        onAdd: () => _openForm(context),
        itemBuilder: (ctx, u) => _UnitCard(unit: u),
      );
}

class _UnitCard extends StatelessWidget {
  const _UnitCard({required this.unit});
  final OwnerUnit unit;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: AppColors.pink),
                child: ExcludeSemantics(child: QrImageView(data: unit.qrContent, size: 60, backgroundColor: AppColors.pink)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(unit.label, style: text.titleLarge),
                    Text(unit.route, style: text.bodyLarge),
                    const SizedBox(height: 6),
                    Text('${Money.format(unit.fareCents)} · Código ${unit.spacedCode}', style: text.bodyMedium),
                    const SizedBox(height: 10),
                    StatusChip(label: unit.active ? 'Cobrando' : 'Apagada', good: unit.active),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Ver QR',
                  icon: Icons.qr_code_2_rounded,
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => UnitQrPage(unit: unit))),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: AppButton(label: 'Editar', icon: Icons.edit_rounded, kind: ButtonKind.secondary, onPressed: () => _openForm(context, unit: unit))),
            ],
          ),
        ],
      ),
    );
  }
}

class _UnitForm extends ConsumerStatefulWidget {
  const _UnitForm({this.unit});
  final OwnerUnit? unit;

  @override
  ConsumerState<_UnitForm> createState() => _UnitFormState();
}

class _UnitFormState extends ConsumerState<_UnitForm> with SubmitMixin<_UnitForm> {
  late final _label = TextEditingController(text: widget.unit?.label);
  late final _route = TextEditingController(text: widget.unit?.route);
  late final _fare = TextEditingController(text: widget.unit == null ? '12' : (widget.unit!.fareCents / 100).toStringAsFixed(widget.unit!.fareCents % 100 == 0 ? 0 : 2));
  late bool _active = widget.unit?.active ?? true;

  @override
  void dispose() {
    _label.dispose();
    _route.dispose();
    _fare.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final repo = ref.read(ownerRepositoryProvider);
    final fare = Money.parseToCents(_fare.text)!;
    final ok = await submit(() async {
      final u = widget.unit;
      if (u == null) {
        await repo.createUnit(label: _label.text.trim(), route: _route.text.trim(), fareCents: fare);
      } else {
        await repo.updateUnit(u.id, label: _label.text.trim(), route: _route.text.trim(), fareCents: fare, active: _active);
      }
    });
    if (ok && mounted) {
      ref.invalidate(unitsProvider);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          LabeledField(label: 'Nombre de la unidad', hint: 'Unidad 14', controller: _label, validator: Validators.notEmpty('el nombre')),
          LabeledField(label: 'Ruta', hint: 'Ruta 52', controller: _route, validator: Validators.notEmpty('la ruta')),
          LabeledField(
            label: 'Precio del pasaje (pesos)',
            controller: _fare,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.done,
            validator: Validators.money('El precio'),
          ),
          if (widget.unit != null)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Cobrando con CoDi', style: Theme.of(context).textTheme.titleMedium),
              subtitle: const Text('Apágala si la unidad no está en servicio.'),
              value: _active,
              onChanged: (v) => setState(() => _active = v),
            ),
          const SizedBox(height: 8),
          AppButton(label: 'Guardar', icon: Icons.check_rounded, loading: busy, onPressed: _save),
        ],
      ),
    );
  }
}
