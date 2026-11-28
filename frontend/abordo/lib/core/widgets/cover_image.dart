import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import '../utils/cover_scene.dart';
import '../utils/motion.dart';
import 'cover_painter.dart';
import 'app_button.dart';
import 'dialogs.dart';
import 'bus_image.dart';

/// Portada a todo el espacio disponible: la ilustración automática, que cambia sola con la hora,
/// el día y las fiestas del año.
class CoverImage extends StatelessWidget {
  const CoverImage({super.key, this.showBus = true, this.compact = false, this.busScale = 1, this.at});

  final bool showBus;

  /// Cabecera de pantalla: bus más pequeño.
  final bool compact;

  /// Multiplica el tamaño del bus (1 = normal). Para portadas bajitas.
  final double busScale;

  /// Fija la fecha y hora de la ilustración (sin reloj). Sirve para probar una fiesta o una hora
  /// concreta, p. ej. `CoverImage(at: DateTime(2026, 12, 24, 19, 30))`.
  final DateTime? at;

  @override
  Widget build(BuildContext context) => _LiveCover(showBus: showBus, compact: compact, busScale: busScale, at: at);
}

/// La ilustración viva. Cada pocos segundos revisa el reloj y, si la luz o la fiesta cambiaron,
/// pasa de la escena anterior a la nueva con una transición suave; además anima nubes, estrellas
/// y la decoración de la fiesta (se detiene con "Reducir movimiento" del sistema).
class _LiveCover extends StatefulWidget {
  const _LiveCover({required this.showBus, required this.compact, required this.busScale, this.at});

  final bool showBus;
  final bool compact;
  final double busScale;
  final DateTime? at;

  @override
  State<_LiveCover> createState() => _LiveCoverState();
}

class _LiveCoverState extends State<_LiveCover> with TickerProviderStateMixin, WidgetsBindingObserver {
  /// Cada cuánto se revisa el reloj.
  static const _tick = Duration(seconds: 20);

  /// Duración del paso de una escena a la siguiente.
  static const _blend = Duration(milliseconds: 2400);

  late final AnimationController _morph = AnimationController(vsync: this, duration: _blend);
  late final AnimationController _ambient = AnimationController(vsync: this, duration: const Duration(seconds: 600));

  late CoverScene _from;
  late CoverScene _to;
  CoverScene? _cache;
  double _cacheV = -1;
  Timer? _clock;
  bool _still = false;

  /// Nubes SVG del proyecto (assets/clouds/cloud_1.svg ... cloud_3.svg).
  static const _cloudAssets = [
    'assets/clouds/cloud_1.svg',
    'assets/clouds/cloud_2.svg',
    'assets/clouds/cloud_3.svg',
  ];
  List<PictureInfo> _clouds = const [];

  Future<void> _loadClouds() async {
    try {
      final loaded = <PictureInfo>[];
      for (final path in _cloudAssets) {
        loaded.add(await vg.loadPicture(SvgAssetLoader(path), null));
      }
      if (!mounted) {
        for (final p in loaded) {
          p.picture.dispose();
        }
        return;
      }
      setState(() => _clouds = loaded);
    } catch (_) {
      // Sin los SVG se conserva la nube dibujada en código.
    }
  }

  /// PNG de vegetación: árbol, pino, palmera y arbusto (en ese orden).
  static const _plantAssets = [
    'assets/trees/arbol.png',
    'assets/trees/pino.png',
    'assets/trees/palmera.png',
    'assets/trees/arbusto.png',
  ];
  List<ui.Image> _plants = const [];

  Future<void> _loadPlants() async {
    try {
      final loaded = <ui.Image>[];
      for (final path in _plantAssets) {
        final data = await rootBundle.load(path);
        final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
        loaded.add((await codec.getNextFrame()).image);
      }
      if (!mounted) {
        for (final i in loaded) {
          i.dispose();
        }
        return;
      }
      setState(() => _plants = loaded);
    } catch (_) {
      // Sin los PNG simplemente no se dibuja vegetación.
    }
  }

  DateTime get _now => widget.at ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    _from = _to = CoverScene.at(_now);
    _morph.value = 1;
    WidgetsBinding.instance.addObserver(this);
    _startClock();
    _loadClouds();
    _loadPlants();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = reduceMotion(context);
    if (still) {
      _still = true;
      _ambient.stop();
    } else if (!_ambient.isAnimating) {
      _still = false;
      _ambient.repeat();
    }
  }

  @override
  void didUpdateWidget(_LiveCover old) {
    super.didUpdateWidget(old);
    if (old.at != widget.at) {
      _startClock();
      _refresh();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Al volver de segundo plano la hora pudo cambiar mucho: se ajusta con la misma transición.
    if (state == AppLifecycleState.resumed) _refresh();
  }

  void _startClock() {
    _clock?.cancel();
    _clock = widget.at == null ? Timer.periodic(_tick, (_) => _refresh()) : null;
  }

  /// Escena que se está viendo ahora mismo (a mitad de transición, la mezcla de ambas).
  CoverScene _current() {
    final v = _morph.value;
    if (v >= 1) return _to;
    if (v == _cacheV && _cache != null) return _cache!; // la comparten las dos capas del cuadro
    _cacheV = v;
    return _cache = CoverScene.lerp(_from, _to, Curves.easeInOutCubic.transform(v));
  }

  void _refresh() {
    if (!mounted) return;
    final next = CoverScene.at(_now);
    if (_still) {
      _from = _to = next;
      _cacheV = -1;
      _morph.value = 1;
    } else {
      _from = _current(); // parte desde lo que se ve, aunque haya otra transición en curso
      _to = next;
      _cacheV = -1;
      _morph.forward(from: 0);
    }
  }

  double _seconds() => _ambient.value * CoverPainter.loopSeconds;

  @override
  void dispose() {
    _clock?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _morph.dispose();
    _ambient.dispose();
    for (final p in _clouds) {
      p.picture.dispose();
    }
    for (final i in _plants) {
      i.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repaint = Listenable.merge([_morph, _ambient]);
    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, c) {
          final busW = (c.maxWidth * (widget.compact ? .5 : .56) * widget.busScale).clamp(60.0, 300.0).toDouble();
          return ClipRect(
            child: CustomPaint(
              painter: CoverPainter(
                layer: CoverLayer.back,
                scene: _current,
                seconds: _seconds,
                compact: widget.compact,
                busScale: widget.busScale,
                showBus: widget.showBus,
                clouds: _clouds,
                plants: _plants,
                repaint: repaint,
              ),
              foregroundPainter: CoverPainter(
                layer: CoverLayer.front,
                scene: _current,
                seconds: _seconds,
                compact: widget.compact,
                busScale: widget.busScale,
                showBus: widget.showBus,
                repaint: repaint,
              ),
              child: SizedBox.expand(
                child: widget.showBus
                    ? Stack(
                        children: [
                          Positioned(
                            right: c.maxWidth * .04,
                            bottom: c.maxHeight * (widget.compact ? .06 : .07),
                            child: BusImage.city(width: busW, scene: _current, repaint: repaint),
                          ),
                        ],
                      )
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Botón de la cabecera para ver la portada: sin fondo, solo el icono blanco.
class CoverButton extends StatelessWidget {
  const CoverButton({super.key, this.color = Colors.white});

  /// Color del icono: blanco sobre la portada del inicio, negro sobre las cabeceras rosa.
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Ver la portada',
      excludeSemantics: true,
      child: InkResponse(
        onTap: () => showCoverSheet(context),
        radius: 26,
        child: SizedBox(width: Dimens.minTap, height: Dimens.minTap, child: Icon(AppIcons.info, size: 26, color: color)),
      ),
    );
  }
}

/// Emergente con solo el texto que explica la portada automática.
Future<void> showCoverSheet(BuildContext context) {
  final festival = Festival.on(DateTime.now());
  return showDialog<void>(
    context: context,
    builder: (ctx) => AppDialog(
      icon: AppIcons.info,
      title: 'Tu portada cambia',
      message: festival == null
          ? 'Tu portada cambia sola con la hora del día y las fiestas del año.'
          : 'Hoy tu portada celebra: ${festival.label}. Cambia sola con la hora del día y las fiestas del año.',
      actions: [AppButton(label: 'Entendido', onPressed: () => Navigator.pop(ctx))],
    ),
  );
}
