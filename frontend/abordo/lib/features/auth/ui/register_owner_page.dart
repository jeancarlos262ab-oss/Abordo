import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/labeled_field.dart';
import '../../../core/widgets/page_scaffold.dart';
import '../../../core/widgets/submit_mixin.dart';
import '../state/session_controller.dart';

class RegisterOwnerPage extends ConsumerStatefulWidget {
  const RegisterOwnerPage({super.key});

  @override
  ConsumerState<RegisterOwnerPage> createState() => _RegisterOwnerPageState();
}

class _RegisterOwnerPageState extends ConsumerState<RegisterOwnerPage> with SubmitMixin<RegisterOwnerPage> {
  final _name = TextEditingController();
  final _login = TextEditingController();
  final _secret = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _login.dispose();
    _secret.dispose();
    super.dispose();
  }

  Future<void> _submit() => submit(
        () => ref.read(sessionProvider.notifier).registerOwner(name: _name.text, login: _login.text, secret: _secret.text),
      );

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return PageScaffold(
      title: 'Crear mi cuenta',
      hero: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cobra el pasaje\ncon CoDi', style: text.headlineMedium),
          const SizedBox(height: 6),
          Text('Registra tus unidades y ve tu cuadre del día.', style: text.bodyLarge?.copyWith(color: AppColors.silver)),
        ],
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LabeledField(label: 'Tu nombre', controller: _name, autofocus: true, validator: Validators.minLength(2, 'El nombre')),
            LabeledField(
              label: 'Tu usuario',
              helper: 'Con este usuario entrarás después.',
              controller: _login,
              validator: Validators.minLength(3, 'El usuario'),
            ),
            LabeledField(
              label: 'Tu contraseña',
              helper: 'Mínimo 8 caracteres.',
              controller: _secret,
              obscure: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              validator: Validators.minLength(8, 'La contraseña'),
            ),
            AppButton(label: 'Crear cuenta', icon: Icons.check_rounded, loading: busy, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
