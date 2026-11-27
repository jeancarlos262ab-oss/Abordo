import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../utils/motion.dart';

/// Ruta del PNG de la mascota (decláralo en pubspec.yaml: `assets/mascot/`).
const mascotAsset = 'assets/mascot/mascota.png';

/// Control remoto de la mascota: reacciona cuando el login falla o sale bien.
class MascotController extends ChangeNotifier {
  int _failTick = 0;
  int _successTick = 0;
  int get failTick => _failTick;
  int get successTick => _successTick;

  void triggerFail() {
    _failTick++;
    notifyListeners();
  }

  void triggerSuccess() {
    _successTick++;
    notifyListeners();
  }
}

/// Mascota a partir de tu PNG, completa y sobre una sombra ovalada en el piso.
/// Tiembla si algo falla y brinca si sale bien (la sombra se queda quieta).
class Mascot extends StatefulWidget {
  const Mascot({super.key, this.controller, this.height = 260});
  final MascotController? controller;

  /// Alto total del conjunto (mascota + sombra).
  final double height;

  @override
  State<Mascot> createState() => _MascotState();
}

class _MascotState extends State<Mascot> with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
  bool _happy = false;
  int _seenFail = 0, _seenSuccess = 0;

  @override
  void initState() {
    super.initState();
    widget.controller?.addListener(_onController);
  }

  void _onController() {
    final c = widget.controller!;
    if (reduceMotion(context)) return;
    if (c.failTick != _seenFail) {
      _seenFail = c.failTick;
      _happy = false;
      _anim.forward(from: 0);
    } else if (c.successTick != _seenSuccess) {
      _seenSuccess = c.successTick;
      _happy = true;
      _anim.forward(from: 0);
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onController);
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const shadowH = 18.0;
    const lift = 22.0; // cuánto sube la sombra, detrás de la imagen (súbelo o bájalo a tu gusto)
    final imageH = widget.height; // la imagen ocupa todo el alto y no se mueve
    final shadowW = math.min(imageH * .62, 220.0);
    final image = Image.asset(
      mascotAsset,
      height: imageH,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => SizedBox(height: imageH), // sin el PNG, solo deja el espacio
    );
    // Sombra: un círculo aplastado, de un solo tono rosa un poco más profundo que el fondo.
    const shadowColor = Color(0xFFE79DBA);
    return ExcludeSemantics(
      child: SizedBox(
        height: widget.height,
        child: Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          children: [
            Positioned(
              bottom: lift,
              child: Container(
                width: shadowW,
                height: shadowH,
                decoration: BoxDecoration(
                  color: shadowColor,
                  borderRadius: BorderRadius.all(Radius.elliptical(shadowW / 2, shadowH / 2)),
                ),
              ),
            ),
            Positioned(
              top: 0,
              child: AnimatedBuilder(
                animation: _anim,
                child: image,
                builder: (_, child) {
                  final t = _anim.value;
                  final dx = _happy ? 0.0 : math.sin(t * math.pi * 8) * 8 * (1 - t);
                  final dy = _happy ? -math.sin(t * math.pi * 3).abs() * 16 * (1 - t) : 0.0;
                  return Transform.translate(offset: Offset(dx, dy), child: child);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
