import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/cover_scene.dart';

enum VehicleKind { bus, van, car }

/// Ilustración vectorial (sin imágenes externas) de un vehículo de lado, con los colores de marca.
/// Sirve para dar personalidad a cada unidad: se elige una variante según su número.
class VehicleArt extends StatelessWidget {
  const VehicleArt({super.key, required this.kind, this.width = 190, this.scene, this.repaint});
  final VehicleKind kind;
  final double width;

  /// Escena de la hora del día (como la portada). Con ella el vehículo se tiñe con la luz del
  /// momento: cálido al atardecer, oscuro de noche y con las ventanillas encendidas.
  final CoverScene Function()? scene;

  /// Avisa cuándo repintar (la transición de la escena y su animación).
  final Listenable? repaint;

  static VehicleKind forId(int id) => VehicleKind.values[id.abs() % VehicleKind.values.length];

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: SizedBox(width: width, height: width * .5, child: CustomPaint(painter: _VehiclePainter(kind, scene, repaint))),
      );
}

class _VehiclePainter extends CustomPainter {
  _VehiclePainter(this.kind, this.scene, Listenable? repaint) : super(repaint: repaint);
  final VehicleKind kind;
  final CoverScene Function()? scene;

  CoverScene? _sc;
  double get _night => _sc?.night ?? 0;
  double get _lit => _sc?.lit ?? 0;

  /// Tiñe un color de la carrocería con la luz del momento: un toque del cielo y, de noche, oscuro.
  Color _tone(Color c) {
    final sc = _sc;
    if (sc == null) return c;
    final x = Color.lerp(c, sc.skyBottom, .16)!;
    return Color.lerp(x, const Color(0xFF1B1519), .62 * _night)!;
  }

  /// Vidrio: se tiñe igual y, al encenderse las luces, se vuelve ámbar (interior iluminado).
  Color _glassTone(Color c) => Color.lerp(_tone(c), const Color(0xFFFFD98A), (_lit * .9).clamp(0.0, 1.0))!;

  static const _glass = Color(0xFFF7C2D7);

  @override
  void paint(Canvas canvas, Size size) {
    _sc = scene?.call();
    // Lienzo lógico de 200 x 100.
    canvas.scale(size.width / 200, size.height / 100);

    final fill = Paint()..style = PaintingStyle.fill;
    // Sombra en el suelo.
    canvas.drawOval(const Rect.fromLTWH(18, 84, 164, 9), fill..color = Colors.black.withOpacity(.12 + .13 * _night));

    switch (kind) {
      case VehicleKind.bus:
        _bus(canvas, fill);
      case VehicleKind.van:
        _van(canvas, fill);
      case VehicleKind.car:
        _car(canvas, fill);
    }
  }

  void _wheel(Canvas c, Paint f, double x, double y, double r) {
    c.drawCircle(Offset(x, y), r, f..color = AppColors.ink2);
    c.drawCircle(Offset(x, y), r * .62, f..color = _tone(AppColors.silver));
    c.drawCircle(Offset(x, y), r * .26, f..color = AppColors.graphite);
  }

  void _bus(Canvas c, Paint f) {
    final dark = _tone(const Color(0xFF2A2427));
    final bodyPath = Path()
      ..moveTo(6, 72)
      ..lineTo(6, 24)
      ..quadraticBezierTo(6, 14, 16, 14)
      ..lineTo(171, 14)
      ..quadraticBezierTo(182, 14, 186, 25)
      ..lineTo(194, 50)
      ..lineTo(194, 72)
      ..quadraticBezierTo(194, 78, 188, 78)
      ..lineTo(12, 78)
      ..quadraticBezierTo(6, 78, 6, 72)
      ..close();

    // Aire acondicionado del techo.
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(52, 9, 60, 7), const Radius.circular(3)), f..color = _tone(AppColors.silver));
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(58, 9, 48, 2.5), const Radius.circular(1.2)), f..color = _tone(Colors.white));

    // Carrocería con degradado suave (luz arriba, sombra abajo).
    c.drawPath(
      bodyPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_tone(Colors.white), _tone(const Color(0xFFF6EEF1))],
        ).createShader(const Rect.fromLTWH(6, 14, 188, 64)),
    );

    c.save();
    c.clipPath(bodyPath);
    // Franja de marca rosa con filete blanco.
    c.drawRect(
      const Rect.fromLTWH(6, 55, 188, 15),
      Paint()
        ..shader = LinearGradient(colors: [_tone(AppColors.rose), _tone(AppColors.roseLight)]).createShader(const Rect.fromLTWH(6, 55, 188, 15)),
    );
    c.drawRect(const Rect.fromLTWH(6, 60, 188, 1.6), f..color = _tone(Colors.white).withOpacity(.85));
    // Faldón oscuro.
    c.drawRect(const Rect.fromLTWH(6, 70, 188, 8), f..color = dark);
    c.restore();

    // Ventanillas con reflejo.
    final glass = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_glassTone(const Color(0xFFFFE3EE)), _glassTone(const Color(0xFFF2A9C6))],
      ).createShader(const Rect.fromLTWH(14, 22, 112, 26));
    for (var i = 0; i < 4; i++) {
      final r = RRect.fromRectAndRadius(Rect.fromLTWH(14 + i * 29.0, 22, 25, 26), const Radius.circular(5));
      c.drawRRect(r, glass);
      final glint = Path()
        ..moveTo(14 + i * 29.0 + 4, 48)
        ..lineTo(14 + i * 29.0 + 12, 22)
        ..lineTo(14 + i * 29.0 + 16, 22)
        ..lineTo(14 + i * 29.0 + 8, 48)
        ..close();
      c.save();
      c.clipRRect(r);
      c.drawPath(glint, f..color = Colors.white.withOpacity(.35 * (1 - _night * .6)));
      c.restore();
    }

    // Puerta doble delantera.
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(130, 22, 22, 46), const Radius.circular(4)), f..color = _tone(const Color(0xFFE9D3DC)));
    for (var i = 0; i < 2; i++) {
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(132 + i * 10.0, 24, 8, 30), const Radius.circular(3)), glass);
    }
    c.drawRect(const Rect.fromLTWH(141.3, 24, 1.4, 42), f..color = dark.withOpacity(.35));

    // Parabrisas, letrero de destino y espejo.
    final wind = Path()
      ..moveTo(158, 22)
      ..lineTo(172, 22)
      ..quadraticBezierTo(177, 22, 179, 27)
      ..lineTo(187, 50)
      ..lineTo(158, 50)
      ..close();
    c.drawPath(wind, glass);
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(160, 16.5, 20, 4.5), const Radius.circular(2)), f..color = dark);
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(162, 17.8, 12, 1.9), const Radius.circular(1)), f..color = const Color(0xFFFFC857));
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(152, 28, 3, 9), const Radius.circular(1.5)), f..color = dark);

    // Faros y luces traseras.
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(188, 54, 6, 6), const Radius.circular(3)), f..color = Color.lerp(const Color(0xFFFFE9B0), Colors.white, _night)!);
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(6, 52, 3.5, 9), const Radius.circular(1.7)), f..color = const Color(0xFFFF4D6D));
    // Parachoques.
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(184, 72, 12, 5), const Radius.circular(2.5)), f..color = _tone(AppColors.graphite));

    // Pasos de rueda y ruedas.
    for (final x in const [44.0, 150.0]) {
      c.drawCircle(Offset(x, 78), 15, f..color = dark);
      _wheel(c, f, x, 78, 11.5);
    }
  }

  void _van(Canvas c, Paint f) {
    final path = Path()
      ..moveTo(10, 74)
      ..lineTo(10, 30)
      ..quadraticBezierTo(10, 20, 22, 20)
      ..lineTo(128, 20)
      ..quadraticBezierTo(140, 20, 148, 32)
      ..lineTo(176, 50)
      ..quadraticBezierTo(190, 54, 190, 66)
      ..lineTo(190, 74)
      ..close();
    c.drawPath(path, f..color = Colors.white);
    c.save();
    c.clipPath(path);
    c.drawRect(const Rect.fromLTWH(0, 56, 200, 9), f..color = AppColors.rose);
    c.restore();
    for (var i = 0; i < 3; i++) {
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(20 + i * 36.0, 27, 30, 20), const Radius.circular(5)), f..color = _glass);
    }
    final windshield = Path()
      ..moveTo(128, 27)
      ..lineTo(138, 27)
      ..quadraticBezierTo(142, 27, 145, 32)
      ..lineTo(160, 47)
      ..lineTo(128, 47)
      ..close();
    c.drawPath(windshield, f..color = _glass);
    c.drawCircle(const Offset(187, 62), 3.2, f..color = AppColors.roseLight);
    _wheel(c, f, 46, 76, 12);
    _wheel(c, f, 152, 76, 12);
  }

  void _car(Canvas c, Paint f) {
    final cabin = Path()
      ..moveTo(52, 46)
      ..lineTo(74, 24)
      ..quadraticBezierTo(78, 20, 84, 20)
      ..lineTo(124, 20)
      ..quadraticBezierTo(130, 20, 135, 24)
      ..lineTo(154, 46)
      ..close();
    c.drawPath(cabin, f..color = Colors.white);
    final body = RRect.fromRectAndRadius(const Rect.fromLTWH(10, 42, 180, 34), const Radius.circular(14));
    c.drawRRect(body, f..color = Colors.white);
    c.save();
    c.clipRRect(body);
    c.drawRect(const Rect.fromLTWH(10, 58, 180, 7), f..color = AppColors.rose);
    c.restore();
    // Ventanas.
    final w1 = Path()
      ..moveTo(60, 43)
      ..lineTo(77, 27)
      ..lineTo(98, 27)
      ..lineTo(98, 43)
      ..close();
    final w2 = Path()
      ..moveTo(104, 27)
      ..lineTo(122, 27)
      ..lineTo(141, 43)
      ..lineTo(104, 43)
      ..close();
    c.drawPath(w1, f..color = _glass);
    c.drawPath(w2, f..color = _glass);
    c.drawCircle(const Offset(184, 52), 3.4, f..color = AppColors.roseLight);
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(10, 50, 4, 7), const Radius.circular(2)), f..color = AppColors.rose);
    _wheel(c, f, 48, 76, 12);
    _wheel(c, f, 152, 76, 12);
  }

  @override
  bool shouldRepaint(_VehiclePainter old) => old.kind != kind;
}
