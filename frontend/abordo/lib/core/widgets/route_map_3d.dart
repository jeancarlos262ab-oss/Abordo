import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import '../utils/motion.dart';
import '../utils/route_path.dart';

/// Mapa vectorial con inclinación 3D (edificios en relieve) que muestra el recorrido de una ruta
/// con su salida y su destino. Gira despacio solo (se detiene con "Reducir movimiento").
///
/// Con [interactive] el usuario puede girarlo e inclinarlo con los dedos; sin él es solo de vista.
/// Usa MapLibre con los mapas libres de OpenFreeMap: no necesita llave ni cuenta.
class RouteMap3D extends StatefulWidget {
  const RouteMap3D({
    super.key,
    this.path = RoutePath.demo,
    this.height = 220,
    this.interactive = false,
    this.autoRotate = true,
    this.tilt = 60,
    this.caption,
  });

  final RoutePath path;
  final double height;
  final bool interactive;
  final bool autoRotate;
  final double tilt;

  /// Texto opcional sobre el mapa (p. ej. el nombre de la ruta).
  final String? caption;

  static const styleUrl = 'https://tiles.openfreemap.org/styles/liberty';

  @override
  State<RouteMap3D> createState() => _RouteMap3DState();
}

class _RouteMap3DState extends State<RouteMap3D> {
  MapLibreMapController? _map;
  Timer? _spin;
  double _bearing = 20;
  bool _ready = false;

  LatLng _ll(GeoPoint p) => LatLng(p.lat, p.lng);

  LatLng get _center {
    final pts = widget.path.points;
    final lat = pts.map((p) => p.lat).reduce((a, b) => a + b) / pts.length;
    final lng = pts.map((p) => p.lng).reduce((a, b) => a + b) / pts.length;
    return LatLng(lat, lng);
  }

  /// Zoom que deja entera la ruta en pantalla (aprox.; el mapa se ajusta además con fitBounds).
  double get _zoom {
    final pts = widget.path.points;
    final dLat = pts.map((p) => p.lat).reduce(math.max) - pts.map((p) => p.lat).reduce(math.min);
    final dLng = pts.map((p) => p.lng).reduce(math.max) - pts.map((p) => p.lng).reduce(math.min);
    final span = math.max(dLat, dLng).clamp(.002, 2.0);
    return (math.log(360 / span) / math.ln2 - 1.2).clamp(8.0, 16.5).toDouble();
  }

  Future<void> _onStyleLoaded() async {
    final c = _map;
    if (c == null) return;
    final line = widget.path.points.map(_ll).toList();
    // Contorno blanco + trazo rosa (la ruta).
    await c.addLine(LineOptions(geometry: line, lineColor: '#231F20', lineWidth: 9, lineJoin: 'round'));
    await c.addLine(LineOptions(geometry: line, lineColor: '#F7B5CD', lineWidth: 5, lineJoin: 'round'));
    // Salida y destino.
    await c.addCircle(CircleOptions(geometry: line.first, circleRadius: 8, circleColor: '#FFFFFF', circleStrokeColor: '#231F20', circleStrokeWidth: 4));
    await c.addCircle(CircleOptions(geometry: line.last, circleRadius: 10, circleColor: '#F7B5CD', circleStrokeColor: '#231F20', circleStrokeWidth: 4));
    if (!mounted) return;
    setState(() => _ready = true);
    _startSpin();
  }

  void _startSpin() {
    _spin?.cancel();
    if (!widget.autoRotate || reduceMotion(context)) return;
    _spin = Timer.periodic(const Duration(milliseconds: 40), (_) {
      _bearing = (_bearing + .18) % 360;
      _map?.moveCamera(CameraUpdate.bearingTo(_bearing));
    });
  }

  @override
  void dispose() {
    _spin?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: p.field),
          MapLibreMap(
            styleString: RouteMap3D.styleUrl,
            initialCameraPosition: CameraPosition(target: _center, zoom: _zoom, tilt: widget.tilt, bearing: _bearing),
            onMapCreated: (c) => _map = c,
            onStyleLoadedCallback: _onStyleLoaded,
            compassEnabled: false,
            rotateGesturesEnabled: widget.interactive,
            tiltGesturesEnabled: widget.interactive,
            scrollGesturesEnabled: widget.interactive,
            zoomGesturesEnabled: widget.interactive,
            gestureRecognizers: widget.interactive ? {Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer())} : null,
          ),
          if (!_ready)
            const Center(child: SizedBox(width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 3))),
          if (widget.caption != null)
            Positioned(
              left: 12,
              top: 12,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(99), border: Border.all(color: p.border)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(AppIcons.bus, size: 16, color: AppColors.ink),
                    const SizedBox(width: 6),
                    Text(widget.caption!, style: text.labelMedium?.copyWith(color: AppColors.ink)),
                  ]),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
