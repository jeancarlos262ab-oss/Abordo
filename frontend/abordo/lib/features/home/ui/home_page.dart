import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/action_card.dart';
import '../../../core/widgets/fade_slide_in.dart';
import '../../../core/widgets/logo.dart';
import '../../../core/widgets/page_scaffold.dart';
import '../../../core/widgets/qr_mark.dart';
import '../../auth/domain/session.dart';
import '../../auth/ui/login_page.dart';
import '../../passenger/ui/unit_entry_page.dart';

/// Primera pantalla. La cabecera muestra la idea (QR + pago); abajo, tres opciones enormes.
/// La primera —pagar el pasaje— es la más usada y no pide cuenta.
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
          const Logo(size: 22),
          const SizedBox(height: 26),
          Text('Paga tu pasaje\ncon CoDi', style: text.displaySmall),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: Text('Sin cambio, sin comisión y en segundos.', style: text.bodyLarge?.copyWith(color: AppColors.silver))),
              const SizedBox(width: 16),
              Transform.rotate(angle: 10 * math.pi / 180, child: const QrMark(size: 84)),
            ],
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('¿Qué quieres hacer?', style: text.headlineSmall),
          const SizedBox(height: 16),
          FadeSlideIn(
            child: ActionCard(
              icon: Icons.qr_code_scanner_rounded,
              title: 'Pagar mi pasaje',
              subtitle: 'Escanea el código de la unidad',
              highlighted: true,
              onTap: () => _open(context, const UnitEntryPage()),
            ),
          ),
          const SizedBox(height: 14),
          FadeSlideIn(
            delay: const Duration(milliseconds: 90),
            child: ActionCard(
              icon: Icons.directions_bus_rounded,
              title: 'Soy chofer',
              subtitle: 'Mis cobros del turno',
              onTap: () => _open(context, const LoginPage(role: Role.driver)),
            ),
          ),
          const SizedBox(height: 14),
          FadeSlideIn(
            delay: const Duration(milliseconds: 180),
            child: ActionCard(
              icon: Icons.storefront_rounded,
              title: 'Soy dueño',
              subtitle: 'Mis unidades y mi cuadre',
              onTap: () => _open(context, const LoginPage(role: Role.owner)),
            ),
          ),
        ],
      ),
    );
  }
}
