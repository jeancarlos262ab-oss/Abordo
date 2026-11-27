import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/fade_slide_in.dart';
import '../../../core/widgets/logo.dart';
import '../../../core/widgets/mascot.dart';
import '../domain/session.dart';
import 'login_page.dart';

/// Primera pantalla: ¿cómo vas a entrar? Usuario, chofer o dueño; cada uno lleva a su propio login.
class RoleSelectPage extends StatelessWidget {
  const RoleSelectPage({super.key});

  void _open(BuildContext context, Role role) {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => LoginPage(role: role)));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: p.background,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, viewport) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: viewport.maxHeight),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: Dimens.maxContentWidth),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Dimens.pagePadding, vertical: 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Center(child: Mascot(height: 230)),
                          const SizedBox(height: 14),
                          Center(child: Logo(size: 30, color: AppColors.ink)),
                          const SizedBox(height: 8),
                          Text('¿Cómo vas a entrar?', textAlign: TextAlign.center, style: text.titleLarge?.copyWith(color: p.muted)),
                          const SizedBox(height: 26),
                          FadeSlideIn(
                            child: _RoleRow(
                              icon: AppIcons.user,
                              title: 'Soy usuario',
                              subtitle: 'Paga tu pasaje con CoDi',
                              onTap: () => _open(context, Role.passenger),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _RoleRow(
                            icon: AppIcons.bus,
                            title: 'Soy chofer',
                            subtitle: 'Entra a tu turno con tu PIN',
                            onTap: () => _open(context, Role.driver),
                          ),
                          const SizedBox(height: 12),
                          _RoleRow(
                            icon: AppIcons.storefront,
                            title: 'Soy dueño',
                            subtitle: 'Administra tus unidades y cobros',
                            onTap: () => _open(context, Role.owner),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Opción sin relleno, solo borde (como el resto de los contenedores de la app).
class _RoleRow extends StatelessWidget {
  const _RoleRow({required this.icon, required this.title, required this.subtitle, required this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label: '$title. $subtitle',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimens.rLg), side: BorderSide(color: p.outline)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 76),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.ink.withOpacity(.08)),
                    child: Icon(icon, size: 24, color: AppColors.ink),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: text.titleLarge),
                        Text(subtitle, style: text.bodyMedium?.copyWith(color: p.muted)),
                      ],
                    ),
                  ),
                  Icon(AppIcons.caretRight, size: 20, color: p.muted),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
