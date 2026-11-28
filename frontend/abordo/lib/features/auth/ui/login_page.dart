import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/mascot.dart';
import '../domain/session.dart';
import '../state/session_controller.dart';
import 'auth_widgets.dart';

/// Entrada para chofer, dueño o pasajero, con la mascota arriba que reacciona al escribir.
/// El chofer usa usuario + PIN; el dueño, usuario + contraseña, y puede crear su cuenta
/// sin salir de esta pantalla (el formulario cambia con una transición suave).
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key, required this.role, this.startOnRegister = false});
  final Role role;

  /// Abre directo el formulario de crear cuenta (dueño y pasajero).
  final bool startOnRegister;

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _mascot = MascotController();
  late bool _showLogin = !widget.startOnRegister || widget.role == Role.driver;

  bool get _isDriver => widget.role == Role.driver;
  bool get _isPassenger => widget.role == Role.passenger;

  @override
  void dispose() {
    _mascot.dispose();
    super.dispose();
  }

  void _switchTo(bool login) {
    setState(() => _showLogin = login);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    // Con el teclado abierto la mascota se encoge para dejar sitio al formulario.
    final mascotH = keyboardOpen ? 150.0 : 270.0;

    final roleTitle = switch (widget.role) { Role.driver => 'Chofer', Role.owner => 'Dueño', Role.passenger => null };
    final title = _showLogin ? 'Bienvenido\n' : 'Crea tu cuenta\n';
    final subtitle = _showLogin
        ? (_isDriver
            ? 'Entra a tu turno con el PIN que te dio tu dueño.'
            : _isPassenger
                ? 'Entra para pagar tu pasaje y ver tu historial.'
                : 'Entra a tu panel con tu usuario y contraseña.')
        : (_isPassenger ? 'Vincula tu cuenta y paga tu pasaje con CoDi en segundos.' : 'Cobra el pasaje con CoDi y ve tu cuadre del día.');

    return Scaffold(
      backgroundColor: p.background,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        // Iconos del celular en negro sobre el rosa (no heredan el blanco del inicio).
        value: (Theme.of(context).brightness == Brightness.dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark).copyWith(statusBarColor: Colors.transparent),
        child: SafeArea(
        child: Column(
          children: [
            // Cabecera: título y mascota, directo sobre el fondo rosa.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(8, 4, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    tooltip: 'Volver',
                    onPressed: () => Navigator.of(context).maybePop(),
                    style: IconButton.styleFrom(backgroundColor: Colors.transparent, foregroundColor: p.text),
                    icon: Icon(AppIcons.back, color: p.text),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                child: Text.rich(
                                  key: ValueKey(_showLogin),
                                  TextSpan(children: [
                                    TextSpan(text: title, style: text.headlineMedium?.copyWith(height: 1.05, letterSpacing: -.8)),
                                    if (_showLogin) TextSpan(text: 'ABORDO', style: text.headlineMedium?.copyWith(height: 1.05, letterSpacing: -.8, color: AppColors.ink)),
                                  ]),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(subtitle, style: text.bodyMedium?.copyWith(color: p.muted)),
                            ],
                          ),
                        ),
                        // Título del rol, hasta la derecha. El pasajero (usuario) no lleva ninguno.
                        if (roleTitle != null) ...[
                          const SizedBox(width: 12),
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(roleTitle, style: text.titleMedium?.copyWith(color: p.text, fontWeight: FontWeight.w800)),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    child: Center(child: Mascot(
                      controller: _mascot,
                      height: mascotH,
                      kind: switch (widget.role) { Role.owner => MascotKind.owner, Role.driver => MascotKind.driver, Role.passenger => MascotKind.passenger },
                    )),
                  ),
                ],
              ),
            ),
            // Formulario: también sobre el fondo rosa.
            Expanded(
              child: ColoredBox(
                color: Colors.transparent,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 380),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  layoutBuilder: (current, previous) => Stack(alignment: Alignment.topCenter, children: [...previous, if (current != null) current]),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(position: Tween<Offset>(begin: const Offset(0, .025), end: Offset.zero).animate(anim), child: child),
                  ),
                  child: _showLogin
                      ? _LoginForm(key: const ValueKey('login'), role: widget.role, mascot: _mascot, onSwitch: _isDriver ? null : () => _switchTo(false))
                      : _RegisterForm(key: const ValueKey('register'), role: widget.role, mascot: _mascot, onSwitch: () => _switchTo(true)),
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

/// Lo común de ambos formularios: errores, "cargando" y reacciones de la mascota.
mixin _FormBase<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  final formKey = GlobalKey<FormState>();
  final secretFocus = FocusNode();
  bool loading = false;
  String? error;

  MascotController get mascot;

  @override
  void dispose() {
    secretFocus.dispose();
    super.dispose();
  }

  Future<void> send(Future<void> Function() action) async {
    if (loading || !(formKey.currentState?.validate() ?? false)) return;
    secretFocus.unfocus();
    setState(() {
      loading = true;
      error = null;
    });
    try {
      await action(); // al entrar, AuthGate cambia la pantalla raíz y cierra esta
      if (mounted) mascot.triggerSuccess();
    } catch (e) {
      if (!mounted) return;
      setState(() => error = friendlyError(e));
      mascot.triggerFail();
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }
}

class _LoginForm extends ConsumerStatefulWidget {
  const _LoginForm({super.key, required this.role, required this.mascot, required this.onSwitch});
  final Role role;
  final MascotController mascot;
  final VoidCallback? onSwitch;

  @override
  ConsumerState<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<_LoginForm> with _FormBase<_LoginForm> {
  final _login = TextEditingController();
  final _secret = TextEditingController();

  bool get _isDriver => widget.role == Role.driver;

  @override
  MascotController get mascot => widget.mascot;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _login.dispose();
    _secret.dispose();
    super.dispose();
  }

  Future<void> _submit() => send(() => ref.read(sessionProvider.notifier).login(login: _login.text, secret: _secret.text, role: widget.role));

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  if (error != null) ...[AuthErrorBanner(error!), const SizedBox(height: 12)],
                  const AuthLabel('Tu usuario'),
                  const SizedBox(height: 6),
                  AuthField(
                    controller: _login,
                    hint: 'Tu usuario',
                    autofillHints: const [AutofillHints.username],
                    validator: Validators.minLength(3, 'El usuario'),
                  ),
                  const SizedBox(height: 14),
                  AuthLabel(_isDriver ? 'Tu PIN' : 'Tu contraseña'),
                  const SizedBox(height: 6),
                  AuthField(
                    controller: _secret,
                    focusNode: secretFocus,
                    hint: _isDriver ? 'PIN de 4 a 6 números' : 'Tu contraseña',
                    obscure: true,
                    digitsOnly: _isDriver,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    onSubmitted: (_) => _submit(),
                    validator: _isDriver ? Validators.digits(4, 6, 'El PIN') : Validators.minLength(4, 'La contraseña'),
                  ),
                  const SizedBox(height: 22),
                  AuthPillButton(label: 'Entrar', loading: loading, onTap: _submit),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 16),
          child: widget.onSwitch == null
              ? Text('¿Olvidaste tu PIN? Pídele a tu dueño que te asigne uno nuevo.', textAlign: TextAlign.center, style: text.bodyMedium?.copyWith(color: p.muted))
              : _SwitchLink(lead: '¿No tienes cuenta? ', action: 'Regístrate', onTap: widget.onSwitch!),
        ),
      ],
    );
  }
}

class _RegisterForm extends ConsumerStatefulWidget {
  const _RegisterForm({super.key, required this.role, required this.mascot, required this.onSwitch});
  final Role role;
  final MascotController mascot;
  final VoidCallback onSwitch;

  @override
  ConsumerState<_RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends ConsumerState<_RegisterForm> with _FormBase<_RegisterForm> {
  final _name = TextEditingController();
  final _login = TextEditingController();
  final _secret = TextEditingController();

  @override
  MascotController get mascot => widget.mascot;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _name.dispose();
    _login.dispose();
    _secret.dispose();
    super.dispose();
  }

  Future<void> _submit() => send(() {
        final session = ref.read(sessionProvider.notifier);
        return widget.role == Role.passenger
            ? session.registerPassenger(name: _name.text, login: _login.text, secret: _secret.text)
            : session.registerOwner(name: _name.text, login: _login.text, secret: _secret.text);
      });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  if (error != null) ...[AuthErrorBanner(error!), const SizedBox(height: 12)],
                  const AuthLabel('Tu nombre'),
                  const SizedBox(height: 6),
                  AuthField(
                    controller: _name,
                    hint: 'Tu nombre',
                    textCapitalization: TextCapitalization.words,
                    validator: Validators.minLength(2, 'El nombre'),
                  ),
                  const SizedBox(height: 14),
                  const AuthLabel('Tu usuario (con él entrarás después)'),
                  const SizedBox(height: 6),
                  AuthField(controller: _login, hint: 'Tu usuario', validator: Validators.minLength(3, 'El usuario')),
                  const SizedBox(height: 14),
                  const AuthLabel('Tu contraseña (mínimo 8 caracteres)'),
                  const SizedBox(height: 6),
                  AuthField(
                    controller: _secret,
                    focusNode: secretFocus,
                    hint: 'Tu contraseña',
                    obscure: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                    validator: Validators.minLength(8, 'La contraseña'),
                  ),
                  const SizedBox(height: 22),
                  AuthPillButton(label: 'Crear cuenta', loading: loading, onTap: _submit),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 16),
          child: _SwitchLink(lead: '¿Ya tienes cuenta? ', action: 'Entrar', onTap: widget.onSwitch),
        ),
      ],
    );
  }
}

class _SwitchLink extends StatelessWidget {
  const _SwitchLink({required this.lead, required this.action, required this.onTap});
  final String lead;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Dimens.rSm),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: Dimens.minTap),
        child: Center(
          child: Text.rich(
            TextSpan(text: lead, style: text.bodyMedium?.copyWith(color: p.muted), children: [
              TextSpan(text: action, style: text.labelLarge?.copyWith(color: AppColors.ink, decoration: TextDecoration.underline)),
            ]),
          ),
        ),
      ),
    );
  }
}
