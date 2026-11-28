import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/labeled_field.dart';
import '../../../core/widgets/submit_mixin.dart';
import '../domain/owner_models.dart';
import '../state/owner_providers.dart';
import 'owner_widgets.dart';

Future<void> _openForm(BuildContext context, {DriverItem? driver}) => showFormSheet<void>(
      context,
      title: driver == null ? 'Nuevo chofer' : 'Editar chofer',
      builder: (_) => _DriverForm(driver: driver),
    );

class DriversTab extends ConsumerWidget {
  const DriversTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => OwnerList<DriverItem>(
        value: ref.watch(driversProvider),
        onRefresh: () async => ref.invalidate(driversProvider),
        emptyIcon: AppIcons.groupsOutlined,
        emptyMessage: 'Aún no tienes choferes. Agrega uno para que pueda entrar y ver sus cobros.',
        addLabel: 'Agregar chofer',
        onAdd: () => _openForm(context),
        header: (ctx, items) {
          final on = items.where((d) => d.active).length;
          final off = items.length - on;
          return OwnerListHeader(
            title: '${items.length} ${items.length == 1 ? 'chofer' : 'choferes'}',
            subtitle: off == 0
                ? (on == 1 ? '1 con acceso a la app' : '$on con acceso a la app')
                : '$on con acceso · $off sin acceso',
          );
        },
        itemBuilder: (ctx, d) => _DriverRow(driver: d),
      );
}

/// Chofer como fila abierta: avatar con iniciales, nombre y usuario, el interruptor de acceso a la
/// derecha y, debajo, las acciones. Sin tarjeta: solo el fondo y una línea fina entre filas.
class _DriverRow extends ConsumerStatefulWidget {
  const _DriverRow({required this.driver});
  final DriverItem driver;

  @override
  ConsumerState<_DriverRow> createState() => _DriverRowState();
}

class _DriverRowState extends ConsumerState<_DriverRow> {
  bool _busy = false;

  Future<void> _toggle(bool on) async {
    setState(() => _busy = true);
    try {
      await ref.read(ownerRepositoryProvider).updateDriver(widget.driver.id, active: on);
      ref.invalidate(driversProvider);
    } catch (e) {
      if (mounted) showMessage(context, friendlyError(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted = context.palette.muted;
    final d = widget.driver;

    return Semantics(
      container: true,
      label: '${d.name}, usuario ${d.login}, ${d.active ? 'con acceso' : 'sin acceso'}.',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                InitialsAvatar(name: d.name, size: 56, active: d.active),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d.name, style: text.headlineSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text('@${d.login}', style: text.bodyMedium?.copyWith(color: muted), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 6),
                      StateTag(label: d.active ? 'Puede cobrar' : 'Sin acceso', on: d.active),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Semantics(
                  label: 'Acceso a la app de ${d.name}',
                  child: Switch(value: d.active, onChanged: _busy ? null : _toggle),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 70),
              child: Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  PillButton(label: 'Editar', icon: AppIcons.pencil, onPressed: () => _openForm(context, driver: d)),
                  PillButton(label: 'Nuevo PIN', icon: AppIcons.hash, onPressed: () => _openForm(context, driver: d)),
                ],
              ),
            ),
          ],
        ),
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
          LabeledField(label: 'Nombre del chofer', icon: AppIcons.badge, controller: _name, validator: Validators.minLength(2, 'El nombre')),
          if (!_editing)
            LabeledField(
              label: 'Usuario',
              helper: 'Con este usuario entrará a la app.',
              icon: AppIcons.user,
              controller: _login,
              validator: Validators.all([
                Validators.minLength(3, 'El usuario'),
                (v) => RegExp(r'^[\w.@-]+$').hasMatch(v!.trim()) ? null : 'Usa letras, números, punto o guion, sin espacios.',
                // No se permiten usuarios repetidos (sin importar mayúsculas o minúsculas).
                (v) {
                  final taken = ref.read(driversProvider).valueOrNull ?? const <DriverItem>[];
                  final wanted = v!.trim().toLowerCase();
                  return taken.any((d) => d.login.trim().toLowerCase() == wanted) ? 'Ese usuario ya existe. Elige otro.' : null;
                },
              ]),
            ),
          LabeledField(
            label: _editing ? 'PIN nuevo (opcional)' : 'PIN',
            helper: _editing ? 'Déjalo vacío para conservar el actual.' : 'De 4 a 6 números.',
            icon: AppIcons.hash,
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
          AppButton(label: 'Guardar', icon: AppIcons.check, loading: busy, onPressed: _save),
        ],
      ),
    );
  }
}
