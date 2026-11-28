import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_icons.dart';


/// Campo con la etiqueta SIEMPRE visible arriba (no desaparece al escribir) y letra grande.
/// Los campos ocultos (PIN, contraseña) traen un ojo para ver lo que se escribe.
class LabeledField extends StatefulWidget {
  const LabeledField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.helper,
    this.icon,
    this.validator,
    this.keyboardType,
    this.obscure = false,
    this.digitsOnly = false,
    this.maxLength,
    this.autofocus = false,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
    this.autofillHints,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final String? helper;
  final IconData? icon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscure;
  final bool digitsOnly;
  final int? maxLength;
  final bool autofocus;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;

  @override
  State<LabeledField> createState() => _LabeledFieldState();
}

class _LabeledFieldState extends State<LabeledField> {
  late bool _hidden = widget.obscure;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.label, style: text.titleMedium),
          if (widget.helper != null) ...[
            const SizedBox(height: 2),
            Text(widget.helper!, style: text.bodySmall?.copyWith(color: muted)),
          ],
          const SizedBox(height: 10),
          TextFormField(
            controller: widget.controller,
            validator: widget.validator,
            obscureText: _hidden,
            autofocus: widget.autofocus,
            maxLength: widget.maxLength,
            style: text.titleMedium,
            keyboardType: widget.keyboardType ?? (widget.digitsOnly ? TextInputType.number : null),
            inputFormatters: widget.digitsOnly ? [FilteringTextInputFormatter.digitsOnly] : null,
            textInputAction: widget.textInputAction,
            onFieldSubmitted: widget.onSubmitted,
            autofillHints: widget.autofillHints,
            decoration: InputDecoration(
              hintText: widget.hint,
              counterText: '',
              prefixIcon: widget.icon == null ? null : Icon(widget.icon, size: 22),
              suffixIcon: widget.obscure
                  ? IconButton(
                      tooltip: _hidden ? 'Mostrar' : 'Ocultar',
                      onPressed: () => setState(() => _hidden = !_hidden),
                      style: IconButton.styleFrom(backgroundColor: Colors.transparent, foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant),
                      icon: Icon(_hidden ? AppIcons.eye : AppIcons.eyeOff, size: 22),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// Aviso corto con icono de información, para pistas que no son parte de un campo.
class InfoNote extends StatelessWidget {
  const InfoNote({super.key, required this.message, this.icon = AppIcons.info});
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.only(top: 2), child: Icon(icon, size: 20, color: muted)),
        const SizedBox(width: 10),
        Expanded(child: Text(message, style: text.bodyMedium?.copyWith(color: muted))),
      ],
    );
  }
}
