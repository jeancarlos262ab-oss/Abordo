import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'core/widgets/state_views.dart';
import 'features/auth/domain/session.dart';
import 'features/auth/state/session_controller.dart';
import 'features/driver/ui/driver_home_page.dart';
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
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      locale: const Locale('es', 'MX'),
      supportedLocales: const [Locale('es', 'MX'), Locale('es')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Respeta el tamaño de letra del sistema (mucha gente mayor lo agranda), con un tope
      // para que los botones y tarjetas no se rompan.
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: MediaQuery.textScalerOf(context).clamp(minScaleFactor: 1, maxScaleFactor: 1.5),
        ),
        child: child!,
      ),
      home: const AuthGate(),
    );
  }
}

/// Decide la pantalla raíz según la sesión: sin sesión -> inicio; chofer -> turno; dueño -> panel.
/// Cuando la sesión cambia (entrar, salir o vencerse) cierra cualquier pantalla abierta encima.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<Session?>>(sessionProvider, (prev, next) {
      final changed = (prev?.valueOrNull?.user.id) != (next.valueOrNull?.user.id);
      if (changed) Navigator.of(context).popUntil((r) => r.isFirst);
    });

    return ref.watch(sessionProvider).when(
          loading: () => const Scaffold(body: LoadingView()),
          error: (_, __) => const HomePage(),
          data: (session) => switch (session?.user.role) {
            Role.owner => const OwnerShell(),
            Role.driver => const DriverHomePage(),
            null => const HomePage(),
          },
        );
  }
}
