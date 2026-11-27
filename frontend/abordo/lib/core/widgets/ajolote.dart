import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/motion.dart';

/// Controla las reacciones de la mascota desde la pantalla (como un "control remoto").
class AjoloteController extends ChangeNotifier {
  bool _covering = false;
  double _look = 0;
  int _failTick = 0;
  int _successTick = 0;

  bool get covering => _covering;
  double get look => _look;
  int get failTick => _failTick;
  int get successTick => _successTick;

  /// Se tapa los ojos (al escribir la contraseña o el PIN).
  void setCovering(bool v) {
    if (_covering == v) return;
    _covering = v;
    notifyListeners();
  }

  /// Hacia dónde mira, de -1 (izquierda) a 1 (derecha): sigue lo que se escribe.
  void setLook(double v) {
    v = v.clamp(-1.0, 1.0).toDouble();
    if ((v - _look).abs() < .02) return;
    _look = v;
    notifyListeners();
  }

  void triggerFail() {
    _failTick++;
    notifyListeners();
  }

  void triggerSuccess() {
    _successTick++;
    notifyListeners();
  }
}

enum _Mood { idle, sad, happy }

/// Mascota de la app: un ajolote rosa dibujado en código (sin imágenes).
/// Parpadea, mueve las branquias, sigue el texto con la mirada, se tapa los ojos con las manitas
/// al escribir contraseñas, se pone triste si algo falla y salta de alegría si sale bien.
class Ajolote extends StatefulWidget {
  const Ajolote({super.key, this.controller, this.height = 200});
  final AjoloteController? controller;
  final double height;

  @override
  State<Ajolote> createState() => _AjoloteState();
}

class _AjoloteState extends State<Ajolote> with TickerProviderStateMixin {
  late final AnimationController _idle = AnimationController(vsync: this, duration: const Duration(seconds: 6));
  late final AnimationController _cover = AnimationController(vsync: this, duration: const Duration(milliseconds: 280));
  late final AnimationController _react = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  _Mood _mood = _Mood.idle;
  Timer? _calm;
  double _lookNow = 0;
  int _seenFail = 0, _seenSuccess = 0;

  AjoloteController? get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    _c?.addListener(_onController);
    _lookNow = _c?.look ?? 0;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduceMotion(context)) {
      _idle.stop();
    } else if (!_idle.isAnimating) {
      _idle.repeat();
    }
  }

  void _onController() {
    final c = _c!;
    if (c.covering) {
      _cover.forward();
    } else {
      _cover.reverse();
    }
    if (c.failTick != _seenFail) {
      _seenFail = c.failTick;
      _play(_Mood.sad);
    }
    if (c.successTick != _seenSuccess) {
      _seenSuccess = c.successTick;
      _play(_Mood.happy);
    }
    setState(() => _lookNow = c.look);
  }

  void _play(_Mood m) {
    _calm?.cancel();
    setState(() => _mood = m);
    _react.forward(from: 0);
    _calm = Timer(const Duration(milliseconds: 2200), () {
      if (mounted) setState(() => _mood = _Mood.idle);
    });
  }

  @override
  void dispose() {
    _c?.removeListener(_onController);
    _calm?.cancel();
    _idle.dispose();
    _cover.dispose();
    _react.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        height: widget.height,
        width: widget.height,
        child: CustomPaint(
          painter: _AjolotePainter(
            idle: _idle,
            cover: _cover,
            react: _react,
            mood: _mood,
            look: _lookNow,
            repaint: Listenable.merge([_idle, _cover, _react]),
          ),
        ),
      ),
    );
  }
}

class _AjolotePainter extends CustomPainter {
  _AjolotePainter({
    required this.idle,
    required this.cover,
    required this.react,
    required this.mood,
    required this.look,
    super.repaint,
  });

  final Animation<double> idle, cover, react;
  final _Mood mood;
  final double look;

  static const _head = AppColors.pink;
  static const _gill = AppColors.pinkDeep;
  static const _gillTip = AppColors.rose;
  static const _belly = Color(0xFFFFE3EE);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 200, size.height / 200);
    final t = idle.value * 2 * math.pi; // 0..2π cada 6 s (ciclos enteros: sin saltos)
    final r = react.value;

    // Salto de alegría / temblor de tristeza.
    var dy = 0.0, dx = 0.0;
    if (mood == _Mood.happy) dy = -math.sin(r * math.pi * 3).abs() * 14 * (1 - r);
    if (mood == _Mood.sad) dx = math.sin(r * math.pi * 8) * 5 * (1 - r);
    canvas.translate(dx, dy + math.sin(t) * 1.5);

    final fill = Paint()..style = PaintingStyle.fill;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Branquias: tres ramitas por lado que se mecen.
    for (final side in [-1.0, 1.0]) {
      for (var i = 0; i < 3; i++) {
        final base = Offset(100 + side * 52, 78 + i * 16.0);
        final sway = math.sin(t * 2 + i * .9 + (side > 0 ? 1 : 0)) * 3;
        final tip = Offset(100 + side * (92 + i * 3 + sway), 52 + i * 22.0 + sway);
        final ctrl = Offset(100 + side * 78, base.dy - 10);
        final path = Path()
          ..moveTo(base.dx, base.dy)
          ..quadraticBezierTo(ctrl.dx, ctrl.dy, tip.dx, tip.dy);
        canvas.drawPath(path, stroke..color = _gill..strokeWidth = 7);
        canvas.drawCircle(tip, 5.2, fill..color = _gillTip);
      }
    }

    // Cuerpo y manitas de reposo.
    canvas.drawOval(const Rect.fromLTWH(54, 128, 92, 62), fill..color = _head);
    canvas.drawOval(const Rect.fromLTWH(70, 146, 60, 40), fill..color = _belly);

    // Cabeza.
    canvas.drawOval(const Rect.fromLTWH(32, 46, 136, 112), fill..color = _head);

    // Cachetes.
    canvas.drawCircle(const Offset(56, 116), 9, fill..color = _gillTip.withOpacity(.28));
    canvas.drawCircle(const Offset(144, 116), 9, fill..color = _gillTip.withOpacity(.28));

    // Ojos.
    final eyes = [const Offset(76, 100), const Offset(124, 100)];
    final blinkPhase = (idle.value * 2) % 1.0; // un parpadeo cada 3 s
    final blink = blinkPhase > .94 ? 1 - ((blinkPhase - .94) / .03 - 1).abs().clamp(0.0, 1.0) : 0.0;
    for (final e in eyes) {
      if (mood == _Mood.happy) {
        // Ojos felices ^ ^
        final p = Path()
          ..moveTo(e.dx - 8, e.dy + 3)
          ..quadraticBezierTo(e.dx, e.dy - 9, e.dx + 8, e.dy + 3);
        canvas.drawPath(p, stroke..color = AppColors.ink..strokeWidth = 3.4);
      } else {
        final pupil = e.translate(look * 3.5, 1.5);
        final h = mood == _Mood.sad ? 8.0 : 8.6;
        canvas.save();
        canvas.translate(pupil.dx, pupil.dy);
        canvas.scale(1, (1 - blink * .92).clamp(.08, 1.0));
        canvas.drawCircle(Offset.zero, h, fill..color = AppColors.ink);
        canvas.drawCircle(const Offset(-2.6, -3), 2.6, fill..color = Colors.white);
        canvas.restore();
        if (mood == _Mood.sad) {
          // Cejas caídas.
          final s = e.dx < 100 ? -1.0 : 1.0;
          final brow = Path()
            ..moveTo(e.dx - 9 * s, e.dy - 17 - 3 * s)
            ..lineTo(e.dx + 9 * s, e.dy - 17 + 3 * s);
          canvas.drawPath(brow, stroke..color = AppColors.ink..strokeWidth = 3);
        }
      }
    }

    // Boca.
    final mouth = Path();
    if (mood == _Mood.sad) {
      mouth
        ..moveTo(88, 132)
        ..quadraticBezierTo(100, 122, 112, 132);
      canvas.drawPath(mouth, stroke..color = AppColors.ink..strokeWidth = 3.2);
    } else if (mood == _Mood.happy) {
      mouth
        ..moveTo(84, 122)
        ..quadraticBezierTo(100, 146, 116, 122)
        ..close();
      canvas.drawPath(mouth, fill..color = AppColors.ink);
      canvas.drawOval(const Rect.fromLTWH(92, 130, 16, 8), fill..color = _gillTip);
    } else {
      mouth
        ..moveTo(88, 124)
        ..quadraticBezierTo(100, 134, 112, 124);
      canvas.drawPath(mouth, stroke..color = AppColors.ink..strokeWidth = 3.2);
    }

    // Manitas: suben de los costados hasta cubrir los ojos.
    final k = Curves.easeOutBack.transform(cover.value.clamp(0.0, 1.0));
    if (cover.value > 0.001) {
      for (var i = 0; i < 2; i++) {
        final from = Offset(i == 0 ? 52 : 148, 168);
        final to = eyes[i].translate(i == 0 ? 2 : -2, 2);
        final c = Offset.lerp(from, to, k)!;
        canvas.drawCircle(c, 17, fill..color = _head);
        canvas.drawCircle(c, 17, stroke..color = _gill..strokeWidth = 3);
        for (var f = -1; f <= 1; f++) {
          canvas.drawCircle(c.translate(f * 6.0, -9), 1.6, fill..color = _gill);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_AjolotePainter old) => old.mood != mood || old.look != look;
}
