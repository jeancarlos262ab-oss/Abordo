import 'package:flutter/material.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/unit_code.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/labeled_field.dart';
import '../../../core/widgets/page_scaffold.dart';
import '../../../core/widgets/step_progress.dart';
import 'confirm_page.dart';
import 'scan_page.dart';

/// Paso 1: ¿en qué unidad voy? Primero la cámara (lo más fácil); el número es la alternativa.
class UnitEntryPage extends StatefulWidget {
  const UnitEntryPage({super.key});

  @override
  State<UnitEntryPage> createState() => _UnitEntryPageState();
}

class _UnitEntryPageState extends State<UnitEntryPage> {
  final _form = GlobalKey<FormState>();
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _goTo(String code) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ConfirmPage(code: code)));

  Future<void> _scan() async {
    final code = await Navigator.of(context).push<String>(MaterialPageRoute(builder: (_) => const ScanPage()));
    if (code != null && mounted) _goTo(code);
  }

  void _typed() {
    if (!(_form.currentState?.validate() ?? false)) return;
    final code = UnitCode.parse(_code.text);
    code == null ? showMessage(context, 'Ese número no es válido.', error: true) : _goTo(code);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    return PageScaffold(
      title: 'Pagar mi pasaje',
      hero: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Busca el código\nde la unidad', style: text.headlineMedium?.copyWith(color: Colors.white)),
          const SizedBox(height: 6),
          Text('Está junto a la puerta o cerca del chofer.', style: text.bodyLarge?.copyWith(color: AppColors.silver)),
          const SizedBox(height: 24),
          const StepProgress(current: 1),
        ],
      ),
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppButton(label: 'Escanear el código', icon: Icons.qr_code_scanner_rounded, onPressed: _scan),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(child: Divider(color: p.borderStrong.withOpacity(.5))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text('o escribe el número', style: text.bodyMedium?.copyWith(color: p.muted)),
                ),
                Expanded(child: Divider(color: p.borderStrong.withOpacity(.5))),
              ],
            ),
            const SizedBox(height: 24),
            AppCard(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LabeledField(
                    label: 'Número de la unidad',
                    helper: 'Aparece debajo del código.',
                    icon: Icons.pin_outlined,
                    controller: _code,
                    digitsOnly: true,
                    maxLength: AppConfig.unitCodeMax,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _typed(),
                    validator: (v) => UnitCode.parse(v ?? '') == null ? 'Escribe los números que están debajo del código.' : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppButton(label: 'Continuar', icon: Icons.arrow_forward_rounded, kind: ButtonKind.secondary, onPressed: _typed),
          ],
        ),
      ),
    );
  }
}
