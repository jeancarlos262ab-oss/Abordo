import 'dart:async';

import 'package:animated_background/animated_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/cover_scene.dart';
import '../../../core/utils/motion.dart';
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
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: coverH + 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    centered(FadeSlideIn(child: _PayCard(onOpen: () => _open(context, const UnitEntryPage())))),
                    // Lo que sigue queda pegado al final de la pantalla.
                    const Spacer(),
                    const SizedBox(height: 28),
                    // Las rutas se ven en el mapa completo, que se abre desde este botón.
                    centered(
                      SizedBox(
                        width: double.infinity,
                        height: Dimens.buttonHeight,
                        child: FilledButton.icon(
                          onPressed: () => _open(context, const RouteMapPage(title: 'Rutas con CoDi')),
                          icon: const Icon(AppIcons.mapPin, size: 20),
                          label: const Text('Ver rutas que usan CoDi'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.ink,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: const StadiumBorder(),
                            textStyle: text.labelLarge,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: Dimens.pagePadding),
                    _AccountTile(bottomInset: bottom, onOpen: () => _open(context, const PassengerShell())),
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

/// Bloque principal: un contenedor sin fondo, solo contorno. A la izquierda el título y los tres
/// pasos; a la derecha el botón de pagar, redondo.
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
              width: 28,
              child: Text(n, style: text.titleLarge?.copyWith(color: AppColors.roseLight, fontWeight: FontWeight.w800, height: 1.1)),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: text.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700, height: 1.2)),
                  const SizedBox(height: 2),
                  Text(detail, style: text.bodyMedium?.copyWith(color: Colors.white70, height: 1.25)),
                ],
              ),
            ),
          ],
        );

    return Semantics(
      container: true,
      label: 'Paga tu pasaje en tres pasos. Uno: busca el código. Dos: escanéalo. Tres: paga con tu app del banco.',
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 18, 14, 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(.55), width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Paga tu pasaje en 3 pasos', style: text.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w800, height: 1.15)),
                  const SizedBox(height: 14),
                  step('1', 'Busca el código', 'Junto a la puerta o cerca del chofer.'),
                  const SizedBox(height: 12),
                  step('2', 'Escanéalo', 'Apunta la cámara al código.'),
                  const SizedBox(height: 12),
                  step('3', 'Paga con tu banco', 'Confirma en tu app y listo.'),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Semantics(
              button: true,
              label: 'Pagar mi pasaje',
              excludeSemantics: true,
              child: SizedBox(
                width: 96,
                height: 96,
                child: FilledButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    onOpen();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.rose,
                    foregroundColor: AppColors.ink,
                    elevation: 0,
                    padding: EdgeInsets.zero,
                    shape: const CircleBorder(),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(AppIcons.scan, size: 28),
                      const SizedBox(height: 4),
                      Text('Pagar mi\npasaje', textAlign: TextAlign.center, style: text.labelMedium?.copyWith(fontWeight: FontWeight.w800, height: 1.1)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sección "Mi cuenta" al fondo de la app: franja rosa sólida de lado a lado (sin márgenes), baja,
/// con partículas animadas (paquete animated_background), el perfil en círculo negro y la flecha
/// en círculo blanco. Llega hasta el borde inferior; [bottomInset] es la zona segura del teléfono.
class _AccountTile extends StatefulWidget {
  const _AccountTile({required this.onOpen, this.bottomInset = 0});
  final VoidCallback onOpen;
  final double bottomInset;

  @override
  State<_AccountTile> createState() => _AccountTileState();
}

class _AccountTileState extends State<_AccountTile> with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final still = reduceMotion(context);
    final row = Padding(
      padding: EdgeInsets.fromLTRB(Dimens.pagePadding, 10, Dimens.pagePadding, 10 + widget.bottomInset),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(color: AppColors.ink, shape: BoxShape.circle),
            child: const Icon(AppIcons.user, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text('Mi cuenta', style: text.titleMedium?.copyWith(color: AppColors.ink, fontWeight: FontWeight.w800))),
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: const Icon(Icons.arrow_forward_rounded, color: AppColors.ink, size: 18),
          ),
        ],
      ),
    );

    return Semantics(
      button: true,
      label: 'Mi cuenta. Vincula tu pago, mira tu historial o cierra sesión.',
      excludeSemantics: true,
      child: Material(
        color: AppColors.rose,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            widget.onOpen();
          },
          // El contenido manda el alto; las partículas van detrás y se estiran a su tamaño.
          child: ClipRect(
            child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              if (!still)
                Positioned.fill(
                  child: AnimatedBackground(
                    vsync: this,
                    behaviour: RandomParticleBehaviour(
                      options: const ParticleOptions(
                        baseColor: Colors.white,
                        spawnMinRadius: 2,
                        spawnMaxRadius: 6,
                        spawnMinSpeed: 6,
                        spawnMaxSpeed: 18,
                        minOpacity: .15,
                        maxOpacity: .5,
                        particleCount: 24,
                      ),
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              row,
            ],
          ),
          ),
        ),
      ),
    );
  }
}
