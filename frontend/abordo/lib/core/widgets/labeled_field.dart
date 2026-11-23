import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Campo con la etiqueta SIEMPRE visible arriba (no desaparece al escribir) y letra grande.
class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.helper,
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
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: text.titleMedium),
          if (helper != null) Text(helper!, style: text.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            validator: validator,
            obscureText: obscure,
            autofocus: autofocus,
            maxLength: maxLength,
            style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
            keyboardType: keyboardType ?? (digitsOnly ? TextInputType.number : null),
            inputFormatters: digitsOnly ? [FilteringTextInputFormatter.digitsOnly] : null,
            textInputAction: textInputAction,
            onFieldSubmitted: onSubmitted,
            autofillHints: autofillHints,
            decoration: InputDecoration(hintText: hint, counterText: ''),
          ),
        ],
      ),
    );
  }
}
