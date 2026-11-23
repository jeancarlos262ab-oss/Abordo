import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/labeled_field.dart';
import '../../../core/widgets/page_scaffold.dart';
import '../../../core/widgets/submit_mixin.dart';
import '../domain/session.dart';
import '../state/session_controller.dart';
import 'register_owner_page.dart';

/// Inicio de sesión para chofer o dueño. Misma pantalla, textos distintos:
/// el chofer usa usuario + PIN numérico; el dueño, usuario + contraseña.
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key, required this.role});
  final Role role;

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> with SubmitMixin<LoginPage> {
  final _login = TextEditingController();
  final _secret = TextEditingController();

  bool get _isDriver => widget.role == Role.driver;

  @override
  void dispose() {
    _login.dispose();
    _secret.dispose();
    super.dispose();
  }

  // Al iniciar sesión, AuthGate cambia la pantalla raíz y cierra esta página.
  Future<void> _submit() => submit(() => ref.read(sessionProvider.notifier).login(login: _login.text, secret: _secret.text));

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return PageScaffold(
      title: _isDriver ? 'Soy chofer' : 'Soy dueño',
      hero: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_isDriver ? 'Entra a tu turno' : 'Entra a tu panel', style: text.headlineMedium),
          const SizedBox(height: 6),
          Text(_isDriver ? 'Usa el usuario y el PIN que te dio tu dueño.' : 'Con tu usuario y contraseña.', style: text.bodyLarge?.copyWith(color: AppColors.silver)),
        ],
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LabeledField(
              label: 'Tu usuario',
              controller: _login,
              autofocus: true,
              autofillHints: const [AutofillHints.username],
              validator: Validators.minLength(3, 'El usuario'),
            ),
            LabeledField(
              label: _isDriver ? 'Tu PIN' : 'Tu contraseña',
              controller: _secret,
              obscure: true,
              digitsOnly: _isDriver,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onSubmitted: (_) => _submit(),
              validator: _isDriver ? Validators.digits(4, 6, 'El PIN') : Validators.minLength(4, 'La contraseña'),
            ),
            const SizedBox(height: 8),
            AppButton(label: 'Entrar', icon: Icons.login_rounded, loading: busy, onPressed: _submit),
            if (!_isDriver) ...[
              const SizedBox(height: 12),
              AppButton(
                label: 'Crear mi cuenta',
                kind: ButtonKind.text,
                onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const RegisterOwnerPage())),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
