import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/labeled_field.dart';
import '../../../core/widgets/submit_mixin.dart';
import '../../auth/state/session_controller.dart';
import '../../auth/ui/logout_button.dart';
import '../../auth/ui/profile_header.dart';
import '../domain/owner_models.dart';
import '../state/owner_providers.dart';
import 'owner_widgets.dart';

/// Cuenta donde caen los cobros y llaves de pey. Perfil arriba, estado de "¿ya puedo cobrar?",
/// datos en secciones abiertas (campos con relleno suave, no blancos) y la salida al final.
class SettingsTab extends ConsumerWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider).valueOrNull?.user;
    return ListView(
      padding: const EdgeInsets.fromLTRB(Dimens.pagePadding, 0, Dimens.pagePadding, 32),
      children: [
        if (user != null) ...[
          _Profile(
            name: user.name,
            login: user.login,
            business: ref.watch(settingsProvider).valueOrNull?.businessName,
            units: ref.watch(unitsProvider).valueOrNull,
            drivers: ref.watch(driversProvider).valueOrNull,
          ),
          const SizedBox(height: 26),
        ],
        OwnerAsync<OwnerSettings>(
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
        const SizedBox(height: 8),
        const OwnerDivider(),
        _LogoutRow(onTap: () => confirmLogout(context, ref)),
      ],
    );
  }
}

/// Perfil del dueño: cabecera compartida con su mascota, el negocio y tres datos (unidades,
/// cobrando y choferes).
class _Profile extends StatelessWidget {
  const _Profile({required this.name, required this.login, this.business, this.units, this.drivers});
  final String name;
  final String login;
  final String? business;
  final List<OwnerUnit>? units;
  final List<DriverItem>? drivers;

  @override
  Widget build(BuildContext context) {
    final hasBusiness = business != null && business!.trim().isNotEmpty;
    String n(int? v) => v == null ? '—' : '$v';
    return ProfileHeader(
      name: name,
      login: login,
      roleLabel: 'Dueño',
      roleIcon: AppIcons.shield,
      chips: [if (hasBusiness) OutlineChip(icon: AppIcons.storefront, label: business!.trim())],
      stats: [
        ProfileStat(n(units?.length), units?.length == 1 ? 'Unidad' : 'Unidades'),
        ProfileStat(n(units?.where((u) => u.active).length), 'Cobrando'),
        ProfileStat(n(drivers?.length), drivers?.length == 1 ? 'Chofer' : 'Choferes'),
      ],
    );
  }
}

/// ¿Ya se puede cobrar? Si falta algo, un panel oscuro con los pasos pendientes (llama la atención
/// sin ser blanco); si todo está listo, una fila tranquila con palomita verde.
class _ReadyBanner extends StatelessWidget {
  const _ReadyBanner({required this.settings});
  final OwnerSettings settings;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted = context.palette.muted;
    final ready = settings.ready;

    if (ready) {
      return Semantics(
        container: true,
        label: 'Todo listo. Tus unidades ya pueden cobrar con CoDi.',
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
                    Text('Todo listo', style: text.titleLarge),
                    Text('Tus unidades ya pueden cobrar con CoDi.', style: text.bodyMedium?.copyWith(color: muted)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final steps = [
      (label: 'Tu cuenta CLABE', done: settings.clabe.isNotEmpty),
      (label: 'Tus llaves de pey', done: settings.peyConfigured),
    ];
    final doneCount = steps.where((s) => s.done).length;
    final missing = steps.length - doneCount;
    final soft = Colors.white.withOpacity(.65);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
      decoration: BoxDecoration(color: context.panelColor, borderRadius: BorderRadius.circular(Dimens.rXl)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.rose),
                child: const Icon(AppIcons.flag, size: 22, color: AppColors.ink),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(missing == 1 ? 'Falta un paso' : 'Faltan $missing pasos', style: text.titleLarge?.copyWith(color: Colors.white)),
                    Text('Completa estos datos para empezar a cobrar.', style: text.bodyMedium?.copyWith(color: soft)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text('$doneCount/${steps.length}', style: tabular(text.titleMedium?.copyWith(color: AppColors.rose))),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: doneCount / steps.length,
              minHeight: 8,
              color: AppColors.rose,
              backgroundColor: Colors.white.withOpacity(.14),
            ),
          ),
          const SizedBox(height: 8),
          for (final st in steps)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                children: [
                  Icon(st.done ? AppIcons.checkCircle : AppIcons.circleEmpty, size: 22, color: st.done ? AppColors.rose : Colors.white.withOpacity(.45)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(st.label, style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w600, color: Colors.white))),
                  Text(st.done ? 'Listo' : 'Pendiente', style: text.labelMedium?.copyWith(color: st.done ? AppColors.rose : soft)),
                ],
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
    final hint = widget.settings.peyConfigured ? 'Ya guardada ${widget.settings.peyKeyHint}. Escribe otra solo para cambiarla.' : 'Cópiala de tu cuenta de pey.';
    return Theme(
      // Los campos de esta pantalla usan un relleno suave de tinta en vez de blanco.
      data: Theme.of(context).copyWith(inputDecorationTheme: ownerInputTheme(context)),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _FormSection(
              icon: AppIcons.bank,
              title: 'Mis datos de cobro',
              subtitle: 'Dónde caen los pasajes.',
              children: [
                LabeledField(label: 'Nombre de tu negocio', icon: AppIcons.storefront, controller: _business),
                LabeledField(
                  label: 'Tu cuenta CLABE',
                  helper: 'Aquí caen los pasajes. Son 18 números.',
                  icon: AppIcons.bank,
                  controller: _clabe,
                  digitsOnly: true,
                  maxLength: 18,
                  validator: Validators.optional(Validators.digits(18, 18, 'La CLABE')),
                ),
              ],
            ),
            const OwnerDivider(),
            const SizedBox(height: 24),
            _FormSection(
              icon: AppIcons.key,
              title: 'Conexión con pey',
              subtitle: 'Las llaves se guardan cifradas.',
              children: [
                LabeledField(
                  label: 'Llave de pey',
                  helper: hint,
                  icon: AppIcons.key,
                  controller: _key,
                  obscure: true,
                  validator: Validators.optional(Validators.minLength(8, 'La llave')),
                ),
                LabeledField(
                  label: 'Llave secreta de pey',
                  helper: 'Se guarda cifrada y nunca se muestra.',
                  icon: AppIcons.lock,
                  controller: _secret,
                  obscure: true,
                  textInputAction: TextInputAction.done,
                  validator: Validators.optional(Validators.minLength(8, 'La llave secreta')),
                ),
              ],
            ),
            const SizedBox(height: 4),
            InkButton(label: 'Guardar cambios', icon: AppIcons.check, loading: busy, onPressed: _save),
          ],
        ),
      ),
    );
  }
}

/// Sección abierta: icono en círculo suave, título y frase corta, y los campos debajo.
class _FormSection extends StatelessWidget {
  const _FormSection({required this.icon, required this.title, required this.subtitle, required this.children});
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(shape: BoxShape.circle, color: context.inkAt(.08)),
              child: ExcludeSemantics(child: Icon(icon, size: 20, color: context.inkColor)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(header: true, child: Text(title, style: text.titleLarge)),
                  Text(subtitle, style: text.bodySmall?.copyWith(color: context.palette.muted)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        ...children,
      ],
    );
  }
}

/// Salir: fila de texto en rojo, sin botón relleno.
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
