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
import '../../auth/ui/logout_button.dart';
import '../domain/owner_models.dart';
import '../state/owner_providers.dart';

/// Cuenta donde caen los cobros y llaves de pey. Muestra claramente si ya se puede cobrar.
class SettingsTab extends ConsumerWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(Dimens.pagePadding, 8, Dimens.pagePadding, 32),
      children: [
        AsyncValueView<OwnerSettings>(
          value: ref.watch(settingsProvider),
          onRetry: () => ref.invalidate(settingsProvider),
          data: (s) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ReadyBanner(settings: s),
              const SizedBox(height: 24),
              _SettingsForm(settings: s, key: ValueKey('${s.clabe}${s.peyKeyHint}${s.businessName}')),
            ],
          ),
        ),
        const SizedBox(height: 32),
        AppButton(label: 'Cerrar sesión', icon: Icons.logout_rounded, kind: ButtonKind.secondary, onPressed: () => confirmLogout(context, ref)),
      ],
    );
  }
}

class _ReadyBanner extends StatelessWidget {
  const _ReadyBanner({required this.settings});
  final OwnerSettings settings;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final ready = settings.ready;
    return AppCard(
      color: (ready ? AppColors.success : AppColors.pink).withOpacity(.18),
      child: Row(
        children: [
          Icon(ready ? Icons.check_circle_rounded : Icons.info_rounded, size: 40, color: ready ? AppColors.success : Theme.of(context).colorScheme.onSurface),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              ready ? 'Todo listo. Tus unidades ya pueden cobrar con CoDi.' : 'Para empezar a cobrar falta: ${settings.missing.join(' y ')}.',
              style: text.titleMedium,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mis datos de cobro', style: text.headlineSmall),
          const SizedBox(height: 16),
          LabeledField(label: 'Nombre de tu negocio', controller: _business),
          LabeledField(
            label: 'Tu cuenta CLABE',
            helper: 'Aquí caen los pasajes. Son 18 números.',
            controller: _clabe,
            digitsOnly: true,
            maxLength: 18,
            validator: Validators.optional(Validators.digits(18, 18, 'La CLABE')),
          ),
          LabeledField(
            label: 'Llave de pey',
            helper: hint,
            controller: _key,
            obscure: true,
            validator: Validators.optional(Validators.minLength(8, 'La llave')),
          ),
          LabeledField(
            label: 'Llave secreta de pey',
            helper: 'Se guarda cifrada y nunca se muestra.',
            controller: _secret,
            obscure: true,
            textInputAction: TextInputAction.done,
            validator: Validators.optional(Validators.minLength(8, 'La llave secreta')),
          ),
          AppButton(label: 'Guardar', icon: Icons.check_rounded, loading: busy, onPressed: _save),
        ],
      ),
    );
  }
}
