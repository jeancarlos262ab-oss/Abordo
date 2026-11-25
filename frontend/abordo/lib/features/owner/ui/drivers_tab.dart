import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
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
        itemBuilder: (ctx, d) => _DriverCard(driver: d),
      );
}

/// Iniciales sobre un círculo suave: reconocibles de un vistazo sin necesitar foto.
String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  final first = parts.first[0];
  final second = parts.length > 1 ? parts[1][0] : '';
  return (first + second).toUpperCase();
}

class _DriverCard extends StatelessWidget {
  const _DriverCard({required this.driver});
  final DriverItem driver;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final d = driver;
    return AppCard(
      onTap: () => _openForm(context, driver: d),
      semanticLabel: '${d.name}, usuario ${d.login}, ${d.active ? 'activo' : 'apagado'}. Toca para editar.',
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(shape: BoxShape.circle, color: d.active ? p.accentSoft : p.field),
            child: ExcludeSemantics(child: Text(_initials(d.name), style: text.titleMedium?.copyWith(color: d.active ? p.text : p.muted))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d.name, style: text.titleLarge, overflow: TextOverflow.ellipsis),
                Text('@${d.login}', style: text.bodyMedium?.copyWith(color: p.muted), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                StatusChip(label: d.active ? 'Activo' : 'Apagado', good: d.active),
              ],
            ),
          ),
          Icon(Icons.edit_rounded, size: 22, color: p.muted),
        ],
      ),
    );
  }
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LabeledField(label: 'Nombre del chofer', icon: Icons.badge_outlined, controller: _name, validator: Validators.minLength(2, 'El nombre')),
          if (!_editing)
            LabeledField(
              label: 'Usuario',
              helper: 'Con este usuario entrará a la app.',
              icon: Icons.person_outline_rounded,
              controller: _login,
              validator: Validators.all([Validators.minLength(3, 'El usuario'), (v) => RegExp(r'^[\w.@-]+$').hasMatch(v!.trim()) ? null : 'Usa letras, números, punto o guion, sin espacios.']),
            ),
          LabeledField(
            label: _editing ? 'PIN nuevo (opcional)' : 'PIN',
            helper: _editing ? 'Déjalo vacío para conservar el actual.' : 'De 4 a 6 números.',
            icon: Icons.pin_outlined,
            controller: _pin,
            digitsOnly: true,
            obscure: true,
            maxLength: 6,
            textInputAction: TextInputAction.done,
            validator: _editing ? Validators.optional(Validators.digits(4, 6, 'El PIN')) : Validators.digits(4, 6, 'El PIN'),
          ),
          if (_editing) ...[
            AppCard(
              shadow: false,
              onTap: () => setState(() => _active = !_active),
              padding: const EdgeInsets.fromLTRB(18, 12, 12, 12),
              child: Row(
                children: [
                  Expanded(child: Text('Puede entrar a la app', style: Theme.of(context).textTheme.titleMedium)),
                  ExcludeSemantics(child: Switch(value: _active, onChanged: (v) => setState(() => _active = v))),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          const SizedBox(height: 8),
          AppButton(label: 'Guardar', icon: Icons.check_rounded, loading: busy, onPressed: _save),
        ],
      ),
    );
  }
}
