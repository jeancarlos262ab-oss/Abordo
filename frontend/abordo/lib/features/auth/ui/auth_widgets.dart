import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';

/// Etiqueta pequeña sobre un campo.
class AuthLabel extends StatelessWidget {
  const AuthLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: context.palette.muted, letterSpacing: .1));
}

/// Campo relleno con borde fino (mismo estilo que el login de FinKaan). Los campos ocultos traen ojo.
class AuthField extends StatefulWidget {
  const AuthField({
    super.key,
    required this.controller,
    required this.hint,
    this.focusNode,
    this.obscure = false,
    this.digitsOnly = false,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction = TextInputAction.next,
    this.autofillHints,
    this.onSubmitted,
    this.onChanged,
    this.validator,
  });

  final TextEditingController controller;
  final String hint;
  final FocusNode? focusNode;
  final bool obscure;
  final bool digitsOnly;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final TextInputAction textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;

  @override
  State<AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<AuthField> {
  late bool _hidden = widget.obscure;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    OutlineInputBorder border(Color c, [double w = 1]) =>
        OutlineInputBorder(borderRadius: BorderRadius.circular(Dimens.rSm), borderSide: BorderSide(color: c, width: w));
    return TextFormField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      obscureText: _hidden,
      validator: widget.validator,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onSubmitted,
      textCapitalization: widget.textCapitalization,
      textInputAction: widget.textInputAction,
      autofillHints: widget.autofillHints,
      keyboardType: widget.keyboardType ?? (widget.digitsOnly ? TextInputType.number : null),
      inputFormatters: widget.digitsOnly ? [FilteringTextInputFormatter.digitsOnly] : null,
      style: text.titleMedium,
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: text.bodyLarge?.copyWith(color: p.muted.withOpacity(.7)),
        filled: true,
        fillColor: p.text.withOpacity(.06),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        border: border(p.text.withOpacity(.3)),
        enabledBorder: border(p.text.withOpacity(.3)),
        focusedBorder: border(AppColors.ink, 1.5),
        errorBorder: border(p.danger),
        focusedErrorBorder: border(p.danger, 1.5),
        errorStyle: text.bodySmall?.copyWith(color: p.danger),
        suffixIcon: widget.obscure
            ? IconButton(
                tooltip: _hidden ? 'Mostrar' : 'Ocultar',
                onPressed: () => setState(() => _hidden = !_hidden),
                style: IconButton.styleFrom(backgroundColor: Colors.transparent, foregroundColor: p.muted),
                icon: Icon(_hidden ? AppIcons.eye : AppIcons.eyeOff, size: 20, color: p.muted),
              )
            : null,
      ),
    );
  }
}

/// Botón principal en forma de píldora.
class AuthPillButton extends StatelessWidget {
  const AuthPillButton({super.key, required this.label, required this.onTap, this.loading = false});
  final String label;
  final VoidCallback? onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: loading ? null : onTap,
        style: FilledButton.styleFrom(shape: const StadiumBorder(), backgroundColor: AppColors.ink, foregroundColor: Colors.white, disabledBackgroundColor: AppColors.ink.withOpacity(.4), disabledForegroundColor: Colors.white70),
        child: loading
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.6, color: Colors.white))
            : Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white)),
      ),
    );
  }
}

/// Aviso de error dentro del formulario.
class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner(this.message, {super.key});
  final String message;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: p.danger.withOpacity(.1), borderRadius: BorderRadius.circular(Dimens.rSm), border: Border.all(color: p.danger.withOpacity(.4), width: .8)),
        child: Row(
          children: [
            Icon(AppIcons.warningCircle, size: 18, color: p.danger),
            const SizedBox(width: 8),
            Expanded(child: Text(message, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: p.danger))),
          ],
        ),
      ),
    );
  }
}
