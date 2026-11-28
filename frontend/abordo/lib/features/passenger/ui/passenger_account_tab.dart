import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/labeled_field.dart';
import '../../../core/widgets/submit_mixin.dart';
import '../../auth/state/session_controller.dart';
import '../../auth/ui/logout_button.dart';
import '../../owner/ui/owner_widgets.dart';
import '../domain/passenger_models.dart';
import '../state/passenger_providers.dart';

const _banks = ['BBVA', 'Banorte', 'Santander', 'Banamex', 'HSBC', 'Scotiabank', 'Nu', 'Mercado Pago', 'Otro'];

/// Cuenta del pasajero: perfil, el celular/banco que vincula para pagar con CoDi y la salida.
/// Mismo estilo que los ajustes del dueño: secciones abiertas, campos con relleno suave y líneas finas.
class PassengerAccountTab extends ConsumerWidget {
  const PassengerAccountTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider).valueOrNull?.user;
    return ListView(
      padding: const EdgeInsets.fromLTRB(Dimens.pagePadding, 0, Dimens.pagePadding, 32),
      children: [
        if (user != null) ...[
          _Profile(name: user.name, login: user.login),
          const SizedBox(height: 26),
        ],
        OwnerAsync<PassengerProfile>(
          value: ref.watch(passengerProfileProvider),
          onRetry: () => ref.invalidate(passengerProfileProvider),
          data: (profile) => _AccountSection(profile: profile, key: ValueKey('${profile.account?.phone}${profile.account?.bank}')),
        ),
        const SizedBox(height: 8),
        const OwnerDivider(),
        _LogoutRow(onTap: () => confirmLogout(context, ref)),
      ],
    );
  }
}

class _Profile extends StatelessWidget {
  const _Profile({required this.name, required this.login});
  final String name;
  final String login;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      label: '$name, usuario $login, pasajero',
      child: ExcludeSemantics(
        child: Column(
          children: [
            InitialsAvatar(name: name, size: 84, letters: 1),
            const SizedBox(height: 14),
            Text(name, style: text.headlineMedium, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text('@$login', style: text.bodyMedium?.copyWith(color: context.palette.muted), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 14),
            const OutlineChip(icon: AppIcons.ticket, label: 'Pasajero'),
          ],
        ),
      ),
    );
  }
}

/// Si ya hay cuenta vinculada la muestra con sus acciones; si no (o al cambiarla), el formulario.
class _AccountSection extends ConsumerStatefulWidget {
  const _AccountSection({super.key, required this.profile});
  final PassengerProfile profile;

  @override
  ConsumerState<_AccountSection> createState() => _AccountSectionState();
}

class _AccountSectionState extends ConsumerState<_AccountSection> with SubmitMixin<_AccountSection> {
  late final _holder = TextEditingController(text: widget.profile.account?.holder ?? widget.profile.name);
  final _phone = TextEditingController();
  late String _bank = widget.profile.account?.bank ?? '';
  late bool _editing = !widget.profile.linked;

  @override
  void dispose() {
    _holder.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_bank.isEmpty) {
      showMessage(context, 'Elige tu banco.', error: true);
      return;
    }
    final ok = await submit(
      () => ref.read(passengerRepositoryProvider).linkAccount(holder: _holder.text.trim(), phone: _phone.text.trim(), bank: _bank),
    );
    if (ok && mounted) {
      ref.invalidate(passengerProfileProvider);
      showMessage(context, 'Vinculamos tu cuenta.');
    }
  }

  Future<void> _unlink() async {
    final yes = await confirm(
      context,
      title: '¿Quitar tu cuenta?',
      message: 'Ya no pagaremos con este celular. Tu historial se conserva.',
      confirmLabel: 'Sí, quitar',
      danger: true,
      icon: AppIcons.trash,
    );
    if (!yes || !mounted) return;
    try {
      await ref.read(passengerRepositoryProvider).unlinkAccount();
      if (mounted) {
        ref.invalidate(passengerProfileProvider);
        showMessage(context, 'Quitamos tu cuenta.');
      }
    } catch (e) {
      if (mounted) showMessage(context, friendlyError(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted = context.palette.muted;
    final account = widget.profile.account;

    Widget header(String title, String subtitle) => Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(shape: BoxShape.circle, color: context.inkAt(.08)),
              child: ExcludeSemantics(child: Icon(AppIcons.bank, size: 20, color: context.inkColor)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(header: true, child: Text(title, style: text.titleLarge)),
                  Text(subtitle, style: text.bodySmall?.copyWith(color: muted)),
                ],
              ),
            ),
          ],
        );

    if (account != null && !_editing) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            container: true,
            label: 'Cuenta vinculada. ${account.bank}, celular terminado en ${account.phone.length >= 4 ? account.phone.substring(account.phone.length - 4) : ''}, a nombre de ${account.holder}.',
            child: ExcludeSemantics(
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.success),
                    child: const Icon(AppIcons.check, size: 24, color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Cuenta vinculada', style: text.titleLarge),
                        Text('${account.bank} · ${account.phoneHint}', style: text.bodyMedium?.copyWith(color: muted)),
                        if (account.holder.isNotEmpty) Text(account.holder, style: text.bodySmall?.copyWith(color: muted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              PillButton(label: 'Cambiar', icon: AppIcons.pencil, filled: true, onPressed: () => setState(() => _editing = true)),
              const SizedBox(width: 10),
              PillButton(label: 'Quitar', icon: AppIcons.trash, onPressed: _unlink),
            ],
          ),
        ],
      );
    }

    return Theme(
      data: Theme.of(context).copyWith(inputDecorationTheme: ownerInputTheme(context)),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header('Vincula tu cuenta', 'El celular que tienes registrado en tu banco para CoDi.'),
            const SizedBox(height: 18),
            LabeledField(label: 'Nombre del titular', icon: AppIcons.user, controller: _holder, validator: Validators.minLength(2, 'El nombre')),
            LabeledField(
              label: 'Tu celular',
              helper: 'El de tu app del banco. Son 10 números.',
              icon: AppIcons.phone,
              controller: _phone,
              digitsOnly: true,
              maxLength: 10,
              textInputAction: TextInputAction.done,
              validator: Validators.digits(10, 10, 'El celular'),
            ),
            Text('Tu banco', style: text.titleMedium),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [for (final b in _banks) _BankChip(label: b, selected: _bank == b, onTap: () => setState(() => _bank = b))],
            ),
            const SizedBox(height: 24),
            InkButton(label: 'Vincular cuenta', icon: AppIcons.check, loading: busy, onPressed: _save),
            if (account != null) ...[
              const SizedBox(height: 10),
              Center(child: PillButton(label: 'Cancelar', onPressed: () => setState(() => _editing = false))),
            ],
          ],
        ),
      ),
    );
  }
}

class _BankChip extends StatelessWidget {
  const _BankChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: selected ? context.buttonBg : context.buttonBg.withOpacity(.55),
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: context.buttonFg)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoutRow extends StatelessWidget {
  const _LogoutRow({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Cerrar sesión',
      excludeSemantics: true,
      child: Material(
        color: AppColors.pinkDeep,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(AppIcons.signOut, size: 22, color: AppColors.ink),
                const SizedBox(width: 12),
                Text('Cerrar sesión', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.ink, fontSize: 15)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
