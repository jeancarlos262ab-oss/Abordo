import 'package:flutter/material.dart';

import '../utils/cover_scene.dart';

/// PNG del bus para los boletos (decláralo en pubspec.yaml: `assets/bus/`).
const busTicketAsset = 'assets/bus/bus.png';

/// PNG del bus de perfil para la ciudad de la portada.
const busCityAsset = 'assets/bus/bus_perfil.png';

/// Bus a partir de un PNG: [busTicketAsset] en los boletos y [busCityAsset] en la portada.
///
/// * En los boletos se usa tal cual (sin [scene]).
/// * En la portada (`BusImage.city`) recibe la [scene] del momento y se tiñe con la luz del día. El tinte es
///   *multiplicativo* (BlendMode.modulate): oscurece y da un toque del color del cielo, pero conserva
///   las ventanas, las ruedas y los detalles, así que el bus nunca se vuelve de un solo color.
class BusImage extends StatelessWidget {
  /// Bus de los boletos (sin tinte).
  const BusImage({super.key, this.width = 190})
      : asset = busTicketAsset,
        scene = null,
        repaint = null;

  /// Bus de perfil de la portada, teñido con la luz de la [scene].
  const BusImage.city({super.key, this.width = 190, required this.scene, this.repaint}) : asset = busCityAsset;

  final String asset;
  final double width;

  /// Escena de la hora del día (la misma de la portada). Sin ella, el bus se ve con sus colores originales.
  final CoverScene Function()? scene;

  /// Avisa cuándo recalcular el tinte (transición de la escena).
  final Listenable? repaint;

  /// Color por el que se multiplica la imagen: casi blanco de día, un toque cálido o frío
  /// con el cielo, y azul oscuro de noche (pero nunca negro, para que se siga viendo el bus).
  static Color tint(CoverScene sc) {
    final sky = Color.lerp(Colors.white, sc.skyBottom, .18)!;
    return Color.lerp(sky, const Color(0xFF5A5878), (.62 * sc.night).clamp(0.0, 1.0))!;
  }

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      asset,
      width: width,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => SizedBox(width: width, height: width * .4), // sin el PNG, solo deja el espacio
    );

    final get = scene;
    if (get == null) return ExcludeSemantics(child: image);

    final listenable = repaint;
    Widget tinted(Widget? child) {
      final sc = get();
      return Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Sombra en el suelo (más marcada de noche).
          Positioned(
            left: width * .08,
            right: width * .08,
            bottom: 0,
            height: width * .045,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(.12 + .13 * sc.night),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          ColorFiltered(colorFilter: ColorFilter.mode(tint(sc), BlendMode.modulate), child: child),
        ],
      );
    }

    return ExcludeSemantics(
      child: listenable == null ? tinted(image) : AnimatedBuilder(animation: listenable, child: image, builder: (_, child) => tinted(child)),
    );
  }
}
