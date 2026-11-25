import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/action_card.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/fade_slide_in.dart';
import '../../../core/widgets/logo.dart';
import '../../../core/widgets/page_scaffold.dart';
import '../../auth/domain/session.dart';
import '../../auth/ui/login_page.dart';
import '../../passenger/ui/unit_entry_page.dart';

/// Primera pantalla. La cabecera dice la idea (pagar con CoDi); abajo, la acción más usada
/// —pagar el pasaje, sin cuenta— destacada, y el acceso de chofer y dueño como filas.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _open(BuildContext context, Widget page) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return PageScaffold(
      hero: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Logo(size: 20, color: Colors.white),
          const SizedBox(height: 28),
          Text('Paga tu pasaje\ncon CoDi', style: text.displaySmall?.copyWith(color: Colors.white)),
          const SizedBox(height: 14),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Perk(icon: Icons.currency_exchange_rounded, label: 'Sin cambio'),
              _Perk(icon: Icons.percent_rounded, label: 'Sin comisión'),
              _Perk(icon: Icons.bolt_rounded, label: 'En segundos'),
            ],
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FadeSlideIn(
            child: FeatureCard(
              eyebrow: 'Sin crear cuenta',
              title: 'Pagar mi pasaje',
              subtitle: 'Escanea el código de la unidad.',
              actionLabel: 'Empezar',
              onTap: () => _open(context, const UnitEntryPage()),
            ),
          ),
          const SizedBox(height: 32),
          const SectionLabel('Para choferes y dueños'),
          FadeSlideIn(
            delay: const Duration(milliseconds: 90),
            child: ActionCard(
              icon: Icons.directions_bus_rounded,
              title: 'Soy chofer',
              subtitle: 'Mis cobros del turno',
              onTap: () => _open(context, const LoginPage(role: Role.driver)),
            ),
          ),
          const SizedBox(height: 12),
          FadeSlideIn(
            delay: const Duration(milliseconds: 180),
            child: ActionCard(
              icon: Icons.storefront_rounded,
              title: 'Soy dueño',
              subtitle: 'Mis unidades y mi cuadre',
              onTap: () => _open(context, const LoginPage(role: Role.owner)),
            ),
          ),
          const SizedBox(height: 32),
          const SectionLabel('Así de fácil'),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _HowStep(number: 1, icon: Icons.qr_code_scanner_rounded, label: 'Escanea')),
              SizedBox(width: 10),
              Expanded(child: _HowStep(number: 2, icon: Icons.fact_check_rounded, label: 'Confirma')),
              SizedBox(width: 10),
              Expanded(child: _HowStep(number: 3, icon: Icons.payments_rounded, label: 'Paga')),
            ],
          ),
        ],
      ),
    );
  }
}

/// Ventaja en forma de píldora translúcida sobre el hero.
class _Perk extends StatelessWidget {
  const _Perk({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 7, 14, 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.1),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white.withOpacity(.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.pink),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white)),
        ],
      ),
    );
  }
}

class _HowStep extends StatelessWidget {
  const _HowStep({required this.number, required this.icon, required this.label});
  final int number;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Semantics(
      label: 'Paso $number: $label',
      excludeSemantics: true,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: p.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: p.border),
            ),
            child: Icon(icon, size: 30, color: p.accent),
          ),
          const SizedBox(height: 10),
          Text('$number. $label', textAlign: TextAlign.center, style: text.labelMedium),
        ],
      ),
    );
  }
}
