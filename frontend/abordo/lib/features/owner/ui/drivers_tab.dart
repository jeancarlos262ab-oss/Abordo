import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

Future<void> _openForm(BuildContext context, {DriverItem? driver}) => showFormSheet<void>(
      context,
      title: driver == null ? 'Nuevo chofer' : 'Editar chofer',
      builder: (_) => _DriverForm(driver: driver),
    );

class DriversTab extends ConsumerWidget {
  const DriversTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => ResourceListView<DriverItem>(
        value: ref.watch(driversProvider),
        onRefresh: () async => ref.invalidate(driversProvider),
        emptyIcon: Icons.groups_outlined,
        emptyMessage: 'Aún no tienes choferes. Agrega uno para que pueda entrar y ver sus cobros.',
        addLabel: 'Agregar chofer',
        onAdd: () => _openForm(context),
        itemBuilder: (ctx, d) => AppCard(
          onTap: () => _openForm(ctx, driver: d),
          semanticLabel: '${d.name}, usuario ${d.login}, ${d.active ? 'activo' : 'apagado'}. Toca para editar.',
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d.name, style: Theme.of(ctx).textTheme.titleLarge),
                    Text('Usuario: ${d.login}', style: Theme.of(ctx).textTheme.bodyLarge),
                    const SizedBox(height: 10),
                    StatusChip(label: d.active ? 'Activo' : 'Apagado', good: d.active),
                  ],
                ),
              ),
              const Icon(Icons.edit_rounded, size: 28),
            ],
          ),
        ),
      );
}

class _DriverForm extends ConsumerStatefulWidget {
  const _DriverForm({this.driver});
  final DriverItem? driver;

  @override
  ConsumerState<_DriverForm> createState() => _DriverFormState();
}

class _DriverFormState extends ConsumerState<_DriverForm> with SubmitMixin<_DriverForm> {
  late final _name = TextEditingController(text: widget.driver?.name);
  final _login = TextEditingController();
  final _pin = TextEditingController();
  late bool _active = widget.driver?.active ?? true;

  bool get _editing => widget.driver != null;

  @override
  void dispose() {
    _name.dispose();
    _login.dispose();
    _pin.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final repo = ref.read(ownerRepositoryProvider);
    final ok = await submit(() async {
      final d = widget.driver;
      if (d == null) {
        await repo.createDriver(name: _name.text.trim(), login: _login.text.trim(), pin: _pin.text);
      } else {
        await repo.updateDriver(d.id, name: _name.text.trim(), pin: _pin.text, active: _active);
      }
    });
    if (ok && mounted) {
      ref.invalidate(driversProvider);
      final login = _login.text.trim();
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      if (!_editing) showMessageOn(messenger, 'Chofer creado. Dale su usuario "$login" y su PIN.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          LabeledField(label: 'Nombre del chofer', controller: _name, validator: Validators.minLength(2, 'El nombre')),
          if (!_editing)
            LabeledField(
              label: 'Usuario',
              helper: 'Con este usuario entrará a la app.',
              controller: _login,
              validator: Validators.all([Validators.minLength(3, 'El usuario'), (v) => RegExp(r'^[\w.@-]+$').hasMatch(v!.trim()) ? null : 'Usa letras, números, punto o guion, sin espacios.']),
            ),
          LabeledField(
            label: _editing ? 'PIN nuevo (opcional)' : 'PIN',
            helper: _editing ? 'Déjalo vacío para conservar el actual.' : 'De 4 a 6 números.',
            controller: _pin,
            digitsOnly: true,
            obscure: true,
            maxLength: 6,
            textInputAction: TextInputAction.done,
            validator: _editing ? Validators.optional(Validators.digits(4, 6, 'El PIN')) : Validators.digits(4, 6, 'El PIN'),
          ),
          if (_editing)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Puede entrar a la app', style: Theme.of(context).textTheme.titleMedium),
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
