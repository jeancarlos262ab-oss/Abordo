import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/labeled_field.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/submit_mixin.dart';
import '../../auth/state/session_controller.dart';
import '../../auth/ui/logout_button.dart';
import '../domain/owner_models.dart';
import '../state/owner_providers.dart';

/// Cuenta donde caen los cobros y llaves de pey. Muestra claramente si ya se puede cobrar.
class SettingsTab extends ConsumerWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider).valueOrNull?.user;
    return ListView(
      padding: const EdgeInsets.fromLTRB(Dimens.pagePadding, 0, Dimens.pagePadding, 32),
      children: [
        if (user != null) ...[
          _ProfileCard(name: user.name, login: user.login),
          const SizedBox(height: 16),
        ],
        AsyncValueView<OwnerSettings>(
          value: ref.watch(settingsProvider),
          onRetry: () => ref.invalidate(settingsProvider),
          data: (s) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ReadyBanner(settings: s),
              const SizedBox(height: 28),
              _SettingsForm(settings: s, key: ValueKey('${s.clabe}${s.peyKeyHint}${s.businessName}')),
            ],
          ),
        ),
        const SizedBox(height: 28),
        AppButton(label: 'Cerrar sesión', icon: Icons.logout_rounded, kind: ButtonKind.dangerSoft, onPressed: () => confirmLogout(context, ref)),
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.name, required this.login});
  final String name;
  final String login;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.pink),
            child: ExcludeSemantics(child: Text(initial, style: text.headlineSmall?.copyWith(color: AppColors.ink))),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: text.titleLarge, overflow: TextOverflow.ellipsis),
                Text('@$login · Dueño', style: text.bodyMedium?.copyWith(color: p.muted), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadyBanner extends StatelessWidget {
  const _ReadyBanner({required this.settings});
  final OwnerSettings settings;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final ready = settings.ready;
    return AppCard(
      color: ready ? p.successSoft : p.accentSoft,
      shadow: false,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(shape: BoxShape.circle, color: ready ? AppColors.success : AppColors.pink),
            child: Icon(ready ? Icons.check_rounded : Icons.priority_high_rounded, size: 26, color: ready ? Colors.white : AppColors.ink),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ready ? 'Todo listo' : 'Falta un paso', style: text.titleLarge),
                  const SizedBox(height: 2),
                  Text(
                    ready ? 'Tus unidades ya pueden cobrar con CoDi.' : 'Para empezar a cobrar falta: ${settings.missing.join(' y ')}.',
                    style: text.bodyLarge,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsForm extends ConsumerStatefulWidget {
  const _SettingsForm({super.key, required this.settings});
  final OwnerSettings settings;

  @override
  ConsumerState<_SettingsForm> createState() => _SettingsFormState();
}

class _SettingsFormState extends ConsumerState<_SettingsForm> with SubmitMixin<_SettingsForm> {
  late final _business = TextEditingController(text: widget.settings.businessName);
  late final _clabe = TextEditingController(text: widget.settings.clabe);
  final _key = TextEditingController();
  final _secret = TextEditingController();

  @override
  void dispose() {
    _business.dispose();
    _clabe.dispose();
    _key.dispose();
    _secret.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final ok = await submit(
      () => ref.read(ownerRepositoryProvider).saveSettings(
            businessName: _business.text,
            clabe: _clabe.text,
            peyApiKey: _key.text,
            peyApiSecret: _secret.text,
          ),
    );
    if (ok && mounted) {
      ref.invalidate(settingsProvider);
      showMessage(context, 'Guardamos tus datos.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final hint = widget.settings.peyConfigured ? 'Ya guardada ${widget.settings.peyKeyHint}. Escribe otra solo para cambiarla.' : 'Cópiala de tu cuenta de pey.';
    return Form(
      key: formKey,
      child: AppCard(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Mis datos de cobro', style: text.headlineSmall),
            const SizedBox(height: 20),
            LabeledField(label: 'Nombre de tu negocio', icon: Icons.storefront_rounded, controller: _business),
            LabeledField(
              label: 'Tu cuenta CLABE',
              helper: 'Aquí caen los pasajes. Son 18 números.',
              icon: Icons.account_balance_rounded,
              controller: _clabe,
              digitsOnly: true,
              maxLength: 18,
              validator: Validators.optional(Validators.digits(18, 18, 'La CLABE')),
            ),
            LabeledField(
              label: 'Llave de pey',
              helper: hint,
              icon: Icons.key_rounded,
              controller: _key,
              obscure: true,
              validator: Validators.optional(Validators.minLength(8, 'La llave')),
            ),
            LabeledField(
              label: 'Llave secreta de pey',
              helper: 'Se guarda cifrada y nunca se muestra.',
              icon: Icons.lock_outline_rounded,
              controller: _secret,
              obscure: true,
              textInputAction: TextInputAction.done,
              validator: Validators.optional(Validators.minLength(8, 'La llave secreta')),
            ),
            const SizedBox(height: 4),
            AppButton(label: 'Guardar', icon: Icons.check_rounded, loading: busy, onPressed: _save),
          ],
        ),
      ),
    );
  }
}
