import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../utils/motion.dart';

/// Qué mascota se muestra según la entrada: pasajero (la de siempre), dueño o chofer.
enum MascotKind {
  passenger('assets/mascot/mascota.png'),
  owner('assets/mascot/mascota_dueno.png'),
  driver('assets/mascot/mascota_chofer.png');

  const MascotKind(this.asset);

  /// Ruta del PNG (declara la carpeta en pubspec.yaml: `assets/mascot/`).
  final String asset;
}

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

/// Mascota a partir de tu PNG, completa y sin sombra.
/// Tiembla si algo falla y brinca si sale bien.
class Mascot extends StatefulWidget {
  const Mascot({super.key, this.controller, this.height = 260, this.kind = MascotKind.passenger});
  final MascotController? controller;

  /// Cuál de las tres mascotas dibuja.
  final MascotKind kind;

  /// Alto de la mascota.
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
    final imageH = widget.height; // la imagen ocupa todo el alto y no se mueve
    final image = Image.asset(
      widget.kind.asset,
      height: imageH,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => SizedBox(height: imageH), // sin el PNG, solo deja el espacio
    );
    return ExcludeSemantics(
      child: SizedBox(
        height: widget.height,
        child: Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          children: [
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
