import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import '../utils/route_path.dart';
import 'dialogs.dart';

/// Vistas del mapa que el usuario puede elegir (como en cualquier app de mapas).
enum MapKind {
  standard('Estándar', Icons.map_outlined, 'https://tiles.openfreemap.org/styles/liberty'),
  light('Claro', Icons.wb_sunny_outlined, 'https://tiles.openfreemap.org/styles/positron'),
  detailed('Detallado', Icons.location_city_outlined, 'https://tiles.openfreemap.org/styles/bright'),
  satellite('Satélite', Icons.satellite_alt_outlined, _satelliteStyle);

  const MapKind(this.label, this.icon, this.style);
  final String label;
  final IconData icon;
  final String style;
}

// Imágenes de satélite de Esri (revisa sus términos de uso antes de publicar la app).
const _satelliteStyle = '{"version":8,"sources":{"sat":{"type":"raster","tiles":["https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}"],"tileSize":256,"maxzoom":19,"attribution":"Esri, Maxar, Earthstar Geographics"}},"layers":[{"id":"sat","type":"raster","source":"sat"}]}';

/// Mapa normal (MapLibre + OpenFreeMap, sin llaves) que muestra el recorrido de una ruta.
/// Con [controls] trae lo de cualquier app de mapas: cambiar de vista, zoom, brújula,
/// mi ubicación y volver a centrar la ruta.
class RouteMap extends StatefulWidget {
  const RouteMap({
    super.key,
    this.path = RoutePath.demo,
    this.height = 260,
    this.interactive = true,
    this.controls = true,
    this.caption,
    this.onTap,
    this.controlsTop = 10,
  });

  final RoutePath path;
  final double height;

  /// Mover, hacer zoom, girar e inclinar con los dedos.
  final bool interactive;

  /// Botones del mapa (vista, zoom, 3D, ubicación, centrar).
  final bool controls;

  /// Texto opcional sobre el mapa (p. ej. el nombre de la ruta).
  final String? caption;

  /// Si se da, el mapa es una vista previa: un toque ejecuta esto (p. ej. abrir en pantalla completa).
  final VoidCallback? onTap;

  /// Distancia de los botones laterales al borde de arriba (para dejar sitio a una barra encima).
  final double controlsTop;

  @override
  State<RouteMap> createState() => _RouteMapState();
}

class _RouteMapState extends State<RouteMap> {
  MapLibreMapController? _map;
  MapKind _kind = MapKind.light;
  bool _ready = false;
  static const _tilt = 60.0; // siempre en 3D
  bool _located = false;

  List<LatLng> get _line => widget.path.points.map((p) => LatLng(p.lat, p.lng)).toList();

  LatLngBounds get _bounds {
    final l = _line;
    final lats = l.map((e) => e.latitude), lngs = l.map((e) => e.longitude);
    return LatLngBounds(
      southwest: LatLng(lats.reduce((a, b) => a < b ? a : b), lngs.reduce((a, b) => a < b ? a : b)),
      northeast: LatLng(lats.reduce((a, b) => a > b ? a : b), lngs.reduce((a, b) => a > b ? a : b)),
    );
  }

  LatLng get _center {
    final b = _bounds;
    return LatLng((b.southwest.latitude + b.northeast.latitude) / 2, (b.southwest.longitude + b.northeast.longitude) / 2);
  }

  /// Se llama cada vez que carga un estilo (también al cambiar de vista): vuelve a dibujar la ruta.
  Future<void> _onStyleLoaded() async {
    final c = _map;
    if (c == null) return;
    final line = _line;
    await c.addLine(LineOptions(geometry: line, lineColor: '#231F20', lineWidth: 9, lineJoin: 'round'));
    await c.addLine(LineOptions(geometry: line, lineColor: '#F7B5CD', lineWidth: 5, lineJoin: 'round'));
    await c.addCircle(CircleOptions(geometry: line.first, circleRadius: 8, circleColor: '#FFFFFF', circleStrokeColor: '#231F20', circleStrokeWidth: 4));
    await c.addCircle(CircleOptions(geometry: line.last, circleRadius: 10, circleColor: '#F7B5CD', circleStrokeColor: '#231F20', circleStrokeWidth: 4));
    if (mounted && !_ready) {
      setState(() => _ready = true);
      _fit(animate: false);
    }
  }

  Future<void> _fit({bool animate = true}) async {
    final u = CameraUpdate.newLatLngBounds(_bounds, left: 48, top: 56, right: 48, bottom: 48);
    if (animate) {
      await _map?.animateCamera(u);
    } else {
      await _map?.moveCamera(u);
    }
    await _map?.moveCamera(CameraUpdate.tiltTo(_tilt));
  }

  Future<void> _goToMe() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        if (mounted) showMessage(context, 'Activa el permiso de ubicación para verte en el mapa.', error: true);
        return;
      }
      setState(() => _located = true); // muestra el punto azul
      final pos = await Geolocator.getCurrentPosition();
      await _map?.animateCamera(CameraUpdate.newLatLngZoom(LatLng(pos.latitude, pos.longitude), 16));
    } catch (_) {
      if (mounted) showMessage(context, 'No pudimos obtener tu ubicación.', error: true);
    }
  }

  Future<void> _pickKind() async {
    final chosen = await showFormSheet<MapKind>(
      context,
      title: 'Vista del mapa',
      builder: (ctx) => Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final k in MapKind.values)
            _KindTile(kind: k, selected: k == _kind, onTap: () => Navigator.of(ctx).pop(k)),
        ],
      ),
    );
    if (chosen != null && chosen != _kind && mounted) setState(() => _kind = chosen);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final map = MapLibreMap(
      styleString: _kind.style,
      initialCameraPosition: CameraPosition(target: _center, zoom: 12, tilt: _tilt),
      onMapCreated: (c) => _map = c,
      onStyleLoadedCallback: _onStyleLoaded,
      compassEnabled: widget.interactive && widget.controls,
      compassViewPosition: CompassViewPosition.topLeft,
      myLocationEnabled: _located,
      rotateGesturesEnabled: widget.interactive,
      tiltGesturesEnabled: widget.interactive,
      scrollGesturesEnabled: widget.interactive,
      zoomGesturesEnabled: widget.interactive,
      doubleClickZoomEnabled: widget.interactive,
      gestureRecognizers: widget.interactive ? {Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer())} : null,
    );

    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: p.field),
          map,
          if (!_ready) const Center(child: SizedBox(width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 3))),
          if (widget.caption != null)
            Positioned(
              left: 12,
              bottom: 12,
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
          if (widget.controls && widget.interactive)
            Positioned(
              right: 10,
              top: widget.controlsTop,
              child: Column(
                children: [
                  _MapButton(icon: Icons.layers_outlined, label: 'Vista del mapa', onTap: _pickKind),
                  const SizedBox(height: 8),
                  _MapButton(icon: Icons.route_outlined, label: 'Centrar la ruta', onTap: _fit),
                  const SizedBox(height: 8),
                  _MapButton(icon: Icons.my_location, label: 'Mi ubicación', active: _located, onTap: _goToMe),
                ],
              ),
            ),
          if (widget.controls && widget.interactive)
            Positioned(
              right: 10,
              bottom: 10,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(Dimens.rMd), border: Border.all(color: p.border)),
                child: Column(
                  children: [
                    _ZoomButton(icon: Icons.add, label: 'Acercar', onTap: () => _map?.animateCamera(CameraUpdate.zoomIn())),
                    Container(height: 1, width: 28, color: p.border),
                    _ZoomButton(icon: Icons.remove, label: 'Alejar', onTap: () => _map?.animateCamera(CameraUpdate.zoomOut())),
                  ],
                ),
              ),
            ),
          if (widget.onTap != null)
            Positioned.fill(
              child: Semantics(
                button: true,
                label: 'Abrir el mapa en pantalla completa',
                child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: widget.onTap),
              ),
            ),
        ],
      ),
    );
  }
}

class _MapButton extends StatelessWidget {
  const _MapButton({required this.icon, required this.label, required this.onTap, this.active = false});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: active ? AppColors.rose : Colors.white,
        shape: CircleBorder(side: BorderSide(color: active ? AppColors.ink : p.border)),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(width: 44, height: 44, child: Icon(icon, size: 22, color: AppColors.ink)),
        ),
      ),
    );
  }
}

class _ZoomButton extends StatelessWidget {
  const _ZoomButton({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: InkWell(onTap: onTap, child: SizedBox(width: 44, height: 44, child: Icon(icon, size: 22, color: AppColors.ink))),
      );
}

class _KindTile extends StatelessWidget {
  const _KindTile({required this.kind, required this.selected, required this.onTap});
  final MapKind kind;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      selected: selected,
      label: kind.label,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(Dimens.rMd),
        onTap: onTap,
        child: Container(
          width: 120,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: selected ? p.accentSoft : null,
            borderRadius: BorderRadius.circular(Dimens.rMd),
            border: Border.all(color: selected ? AppColors.ink : p.outline, width: selected ? 2 : 1),
          ),
          child: Column(
            children: [
              Icon(kind.icon, size: 28, color: selected ? AppColors.ink : p.muted),
              const SizedBox(height: 8),
              Text(kind.label, style: text.labelLarge),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mapa en pantalla completa con todos sus controles.
class RouteMapPage extends StatelessWidget {
  const RouteMapPage({super.key, this.path = RoutePath.demo, this.title = 'Rutas'});
  final RoutePath path;
  final String title;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      // Equivale a una barra rosa escondida: nadie la ve, pero fija los iconos del celular en negro
      // (y no heredan el blanco del inicio).
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: (isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark).copyWith(statusBarColor: Colors.transparent),
        child: Stack(
        fit: StackFit.expand,
        children: [
          // El mapa ocupa toda la pantalla, hasta los bordes.
          LayoutBuilder(builder: (context, c) => RouteMap(path: path, height: c.maxHeight, controlsTop: MediaQuery.paddingOf(context).top + 64 + 12)),
          // Botón de regreso y título encima del mapa, sobre un degradado suave para que se lean.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [p.background.withOpacity(.95), p.background.withOpacity(0)],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: SizedBox(
                  height: 64,
                  child: Row(
                    children: [
                      const SizedBox(width: 4),
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        tooltip: 'Regresar',
                        color: AppColors.ink,
                        style: IconButton.styleFrom(fixedSize: const Size.square(48)),
                        icon: const Icon(AppIcons.back, size: 24),
                      ),
                      Expanded(
                        child: Semantics(
                          header: true,
                          child: Text(title, textAlign: TextAlign.center, style: text.titleLarge?.copyWith(color: AppColors.ink), overflow: TextOverflow.ellipsis),
                        ),
                      ),
                      const SizedBox(width: 52), // equilibra el botón para que el título quede centrado
                    ],
                  ),
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
