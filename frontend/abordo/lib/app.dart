import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'core/widgets/state_views.dart';
import 'features/auth/domain/session.dart';
import 'features/auth/state/session_controller.dart';
import 'features/driver/ui/driver_home_page.dart';
import 'features/auth/ui/role_select_page.dart';
import 'features/home/ui/home_page.dart';
import 'features/owner/ui/owner_shell.dart';

class AbordoApp extends StatelessWidget {
  const AbordoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ABORDO',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      // La app es rosa y blanco: siempre usa el tema claro.
      themeMode: ThemeMode.light,
      locale: const Locale('es', 'MX'),
      supportedLocales: const [Locale('es', 'MX'), Locale('es')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // El tamaño de letra es exactamente el del sistema (sin forzar mínimo ni máximo).
      home: const AuthGate(),
    );
  }
}

/// Decide la pantalla raíz según la sesión: sin sesión -> elegir rol; usuario -> ciudad con el bus;
/// chofer -> turno; dueño -> panel.
/// Cuando la sesión cambia (entrar, salir o vencerse) cierra cualquier pantalla abierta encima.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<Session?>>(sessionProvider, (prev, next) {
      final changed = (prev?.valueOrNull?.user.id) != (next.valueOrNull?.user.id);
      if (changed) Navigator.of(context).popUntil((r) => r.isFirst);
    });

    final home = ref.watch(sessionProvider).when(
          loading: () => const Scaffold(key: ValueKey('loading'), body: LoadingView()),
          error: (_, __) => const RoleSelectPage(key: ValueKey('roles')),
          data: (session) => switch (session?.user.role) {
            Role.owner => const OwnerShell(key: ValueKey('owner')),
            Role.driver => const DriverHomePage(key: ValueKey('driver')),
            Role.passenger => const HomePage(key: ValueKey('home')),
            null => const RoleSelectPage(key: ValueKey('roles')),
          },
        );

    // Cambio de pantalla raíz con el mismo deslizamiento que el resto de la app.
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => SlideTransition(
        position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(animation),
        child: child,
      ),
      layoutBuilder: (current, previous) => Stack(children: [...previous, if (current != null) current]),
      child: home,
    );
  }
}
