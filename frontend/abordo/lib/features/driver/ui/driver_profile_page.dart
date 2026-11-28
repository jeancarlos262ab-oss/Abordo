import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/money.dart';
import '../../auth/state/session_controller.dart';
import '../../auth/ui/logout_button.dart';
import '../../auth/ui/profile_header.dart';
import '../state/driver_providers.dart';

/// Perfil del chofer: su cabecera con el turno de hoy y la salida de la cuenta.
class DriverProfilePage extends ConsumerWidget {
  const DriverProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider).valueOrNull?.user;
    final shift = ref.watch(shiftProvider).valueOrNull;
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final active = shift?.isActive ?? false;

    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(Dimens.pagePadding, 4, Dimens.pagePadding, 32),
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Regresar',
                  onPressed: () => Navigator.of(context).maybePop(),
                  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                  icon: const Icon(AppIcons.caretLeft),
                ),
                const SizedBox(width: 4),
                Text('Mi perfil', style: text.titleLarge),
              ],
            ),
            const SizedBox(height: 12),
            if (user != null)
              ProfileHeader(
                name: user.name,
                login: user.login,
                roleLabel: 'Chofer',
                roleIcon: AppIcons.bus,
                stats: [
                  ProfileStat(active ? 'En turno' : 'Sin turno', 'Estado'),
                  ProfileStat(shift == null ? '—' : Money.format(shift.amountCents), 'Cobrado hoy'),
                  ProfileStat(shift == null ? '—' : '${shift.count}', shift?.count == 1 ? 'Pasajero' : 'Pasajeros'),
                ],
              ),
            const SizedBox(height: 28),
            LogoutPill(onTap: () => confirmLogout(context, ref)),
          ],
        ),
      ),
    );
  }
}
