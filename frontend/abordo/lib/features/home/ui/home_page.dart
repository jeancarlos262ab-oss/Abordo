import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/cover_scene.dart';
import '../../../core/widgets/cover_image.dart';
import '../../../core/widgets/fade_slide_in.dart';
import '../../../core/widgets/logo.dart';
import '../../../core/widgets/route_map.dart';
import '../../auth/state/session_controller.dart';
import '../../passenger/ui/passenger_shell.dart';
import '../../passenger/ui/unit_entry_page.dart';
import '../../../core/theme/app_icons.dart';

/// Primera pantalla. La cabecera dice la idea (pagar con CoDi); abajo, la acción más usada
/// —pagar el pasaje, sin cuenta— destacada, y el acceso de chofer y dueño como filas.
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  // El fondo es el asfalto de la carretera donde va el bus: cambia con la hora igual que la portada.
  Color _road = CoverScene.at(DateTime.now()).road;
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 20), (_) {
      final next = CoverScene.at(DateTime.now()).road;
      if (mounted && next != _road) setState(() => _road = next);
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  void _open(BuildContext context, Widget page) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final coverH = 170.0 + top;
    final name = ref.watch(sessionProvider).valueOrNull?.user.firstName ?? '';

    // Contenido centrado con el ancho máximo de la app y sus márgenes laterales.
    Widget centered(Widget child) => Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Dimens.maxContentWidth),
            child: Padding(padding: const EdgeInsets.symmetric(horizontal: Dimens.pagePadding), child: child),
          ),
        );

    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(end: _road),
      duration: const Duration(milliseconds: 2400),
      builder: (context, bg, child) => Scaffold(backgroundColor: bg ?? _road, body: child),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: LayoutBuilder(
          builder: (context, viewport) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: viewport.maxHeight),
              child: IntrinsicHeight(
                child: Stack(
            children: [
              // Portada: ilustración dibujada o la foto que el usuario eligió.
              Positioned(top: 0, left: 0, right: 0, height: coverH, child: const CoverImage(busScale: .75)),
              Positioned(
                top: top + 14,
                left: Dimens.pagePadding,
                right: Dimens.pagePadding,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name.isEmpty ? 'Hola,' : 'Hola, $name',
                            style: text.headlineMedium?.copyWith(color: Colors.white),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(AppIcons.mapPin, size: 14, color: Colors.white),
                              const SizedBox(width: 6),
                              Flexible(child: Text('Paga tu pasaje con CoDi', style: text.bodyMedium?.copyWith(color: Colors.white), overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const CoverButton(),
                    // Mi cuenta: vincular el pago, ver el historial y cerrar sesión.
                    IconButton(
                      tooltip: 'Mi cuenta',
                      onPressed: () => _open(context, const PassengerShell()),
                      icon: const Icon(AppIcons.user, color: Colors.white, size: 24),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: coverH + 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    centered(FadeSlideIn(child: _PayCard(onOpen: () => _open(context, const UnitEntryPage())))),
                    const SizedBox(height: 28),
                    // Lo que sigue queda siempre pegado al final de la pantalla.
                    const Spacer(),
                    centered(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Las rutas se ven en el mapa completo, que se abre desde este botón.
                          SizedBox(
                            height: Dimens.buttonHeight,
                            child: FilledButton.icon(
                              onPressed: () => _open(context, const RouteMapPage(title: 'Rutas con CoDi')),
                              icon: const Icon(AppIcons.mapPin, size: 20),
                              label: const Text('Ver rutas que usan CoDi'),
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(.14),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: const StadiumBorder(),
                                textStyle: text.labelLarge,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 28 + bottom),
                  ],
                ),
              ),
            ],
          ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bloque principal sin contenedor: los datos van directo sobre el fondo (el color de la carretera),
/// debajo de la portada. Letra grande y blanca de alto contraste, tres pasos claros y un único botón.
class _PayCard extends StatelessWidget {
  const _PayCard({required this.onOpen});
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    Widget step(String n, String title, String detail) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 38,
              child: Text(n, style: text.headlineLarge?.copyWith(color: AppColors.roseLight, fontWeight: FontWeight.w800, height: 1.0)),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: text.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w700, height: 1.2)),
                  const SizedBox(height: 3),
                  Text(detail, style: text.bodyLarge?.copyWith(color: Colors.white70, height: 1.3)),
                ],
              ),
            ),
          ],
        );

    return Semantics(
      container: true,
      label: 'Paga tu pasaje en tres pasos. Uno: busca el código. Dos: escanéalo. Tres: paga con tu app del banco.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text('Paga tu pasaje en 3 pasos', maxLines: 1, softWrap: false, style: text.headlineLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w800, height: 1.15)),
          ),
          const SizedBox(height: 24),
          step('1', 'Busca el código', 'Está junto a la puerta o cerca del chofer.'),
          const SizedBox(height: 20),
          step('2', 'Escanéalo', 'Apunta la cámara de tu celular al código.'),
          const SizedBox(height: 20),
          step('3', 'Paga con tu banco', 'Se abre tu app del banco. Confirma y listo.'),
          const SizedBox(height: 26),
          SizedBox(
            height: Dimens.buttonHeight + 4,
            child: FilledButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                onOpen();
              },
              icon: const Icon(AppIcons.scan, size: 22),
              label: const Text('Pagar mi pasaje'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.rose,
                foregroundColor: AppColors.ink,
                elevation: 0,
                shape: const StadiumBorder(),
                textStyle: text.labelLarge,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text('Sin comisión · Sin efectivo', textAlign: TextAlign.center, style: text.bodyMedium?.copyWith(color: Colors.white70)),
        ],
      ),
    );
  }
}
