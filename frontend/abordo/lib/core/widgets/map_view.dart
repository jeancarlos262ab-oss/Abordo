import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_icons.dart';

/// Mapa claro visto desde el cielo (manzanas grises, calles blancas, parques rosa pálido, río),
/// con una ruta rosa, su punto de salida, el autobús en camino y el pin de destino.
/// Es ilustración estática: no es interactivo. Se dibuja en el alto dado; la ruta ocupa solo los
/// primeros [routeHeight] píxeles para dejar libre el resto (donde puede montarse una tarjeta).
class MapView extends StatelessWidget {
  const MapView({super.key, this.height = 260, this.routeHeight});
  final double height;
  final double? routeHeight;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: ClipRect(child: CustomPaint(painter: _LightMapPainter(routeHeight ?? height))),
        ),
      );
}

class _LightMapPainter extends CustomPainter {
  const _LightMapPainter(this.rh);
  final double rh;

  static const _street = Color(0xFFFFFFFF);
  static const _block = Color(0xFFEDE8EB);
  static const _park = Color(0xFFFADCE8);
  static const _water = Color(0xFFE2DCE6);
  static const _casing = Color(0xFFDCD4D9);

  static Paint _fill(Color c) => Paint()..color = c;
  static Paint _line(Color c, double w) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  void _label(Canvas canvas, String text, Offset at, {double size = 9, Color color = const Color(0xFFA79DA2), double angle = 0}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(fontSize: size, fontWeight: FontWeight.w700, color: color, letterSpacing: .2)),
      textDirection: TextDirection.ltr,
    )..layout();
    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.rotate(angle);
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
    canvas.restore();
  }

  void _icon(Canvas canvas, IconData icon, Offset c, double size, Color color) {
    final tp = TextPainter(
      text: TextSpan(text: String.fromCharCode(icon.codePoint), style: TextStyle(fontSize: size, fontFamily: icon.fontFamily, package: icon.fontPackage, color: color)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rnd = math.Random(5);
    final span = math.max(w, h) * 1.4;

    canvas.drawRect(Offset.zero & size, _fill(_street));

    // Manzanas (los huecos entre ellas son las calles blancas).
    canvas.save();
    canvas.translate(w * .5, h * .4);
    canvas.rotate(-.28);
    const gap = 8.0;
    var y = -span;
    while (y < span) {
      final rowH = 26 + rnd.nextDouble() * 34;
      var x = -span;
      while (x < span) {
        final colW = 34 + rnd.nextDouble() * 56;
        final roll = rnd.nextDouble();
        final r = Rect.fromLTWH(x, y, colW, rowH).deflate(gap / 2);
        if (roll < .1) {
          canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(8)), _fill(_park));
          for (var k = 0; k < 4; k++) {
            canvas.drawCircle(Offset(r.left + 8 + rnd.nextDouble() * math.max(1, r.width - 16), r.top + 8 + rnd.nextDouble() * math.max(1, r.height - 16)), 2.4, _fill(const Color(0xFFF3B5CC)));
          }
        } else if (roll > .08) {
          canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(3)), _fill(_block));
        }
        x += colW;
      }
      y += rowH;
    }
    canvas.restore();

    // Río.
    final river = Path()
      ..moveTo(-30, rh * .05)
      ..cubicTo(w * .18, rh * -.1, w * .3, rh * .6, w * .46, rh * .78)
      ..cubicTo(w * .62, rh * .96, w * .9, rh * .78, w * 1.1, rh * 1.0);
    canvas.drawPath(river, _line(_water, 22));

    // Avenidas con contorno gris y centro blanco.
    void avenue(Path p, double wd) {
      canvas.drawPath(p, _line(_casing, wd + 3));
      canvas.drawPath(p, _line(_street, wd));
    }

    avenue(Path()..moveTo(-10, rh * .62)..cubicTo(w * .3, rh * .55, w * .62, rh * 1.0, w * 1.05, rh * .5), 9);
    avenue(Path()..moveTo(w * .66, -10)..cubicTo(w * .6, rh * .3, w * .78, rh * .6, w * .72, rh * 1.1), 7);

    // Nombres de zonas y calles.
    _label(canvas, 'CENTRO', Offset(w * .13, rh * .26), size: 10);
    _label(canvas, 'Terminal', Offset(w * .86, rh * .66));
    _label(canvas, 'Mercado', Offset(w * .08, rh * .9));
    _label(canvas, 'Parque Jardín', Offset(w * .38, rh * .12));
    _label(canvas, 'Av. Principal', Offset(w * .3, rh * .6), angle: -.06, size: 8);

    // Ruta rosa en S, con contorno blanco y resplandor.
    final start = Offset(w * .2, rh * .84);
    final end = Offset(w * .78, rh * .24);
    final route = Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(w * .2, rh * .5, w * .52, rh * .96, w * .54, rh * .6)
      ..cubicTo(w * .55, rh * .36, w * .78, rh * .5, end.dx, end.dy);
    canvas.drawPath(route, _line(AppColors.rose.withOpacity(.18), 14));
    canvas.drawPath(route, _line(AppColors.ink, 9));
    canvas.drawPath(route, _line(AppColors.rose, 5));

    // Autobús en camino (punto sobre la ruta).
    final metric = route.computeMetrics().first;
    final bus = metric.getTangentForOffset(metric.length * .56)!.position;
    canvas.drawCircle(bus, 9, _fill(Colors.white));
    canvas.drawCircle(bus, 6, _fill(AppColors.rose));

    // Salida.
    _marker(canvas, start, 15, AppColors.rose, AppIcons.locate, AppColors.ink);
    // Destino: autobús dentro de un círculo blanco con borde rosa.
    _marker(canvas, end, 20, Colors.white, AppIcons.bus, AppColors.ink, ring: AppColors.ink);
  }

  void _marker(Canvas canvas, Offset c, double r, Color fill, IconData icon, Color iconColor, {Color? ring}) {
    canvas.drawCircle(c, r + 3, _fill(Colors.white));
    canvas.drawCircle(c, r, _fill(fill));
    if (ring != null) canvas.drawCircle(c, r, _line(ring, 2.5));
    _icon(canvas, icon, c, r * 1.05, iconColor);
  }

  @override
  bool shouldRepaint(_LightMapPainter old) => old.rh != rh;
}
