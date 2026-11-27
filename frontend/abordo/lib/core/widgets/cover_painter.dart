import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart' show PictureInfo;

import '../utils/cover_scene.dart';

/// Capa que dibuja un [CoverPainter]: `back` va detrás del camión y `front` delante
/// (nieve, confeti, globos y el brillo de los faros).
enum CoverLayer { back, front }

/// Pinta la portada a partir de una [CoverScene]. No guarda estado: en cada cuadro pide la
/// escena y el reloj de animación a quien lo creó, así que puede repintarse a 60 fps sin
/// reconstruir widgets.
///
/// Todas las animaciones se repiten en ciclos que dividen exactamente [loopSeconds], por eso
/// el reloj `seconds()` (0 … 600) puede volver a 0 sin que se note ningún salto.
class CoverPainter extends CustomPainter {
  CoverPainter({
    required this.layer,
    required this.scene,
    required this.seconds,
    required this.compact,
    this.busScale = 1,
    required this.showBus,
    this.clouds = const [],
    super.repaint,
  });

  static const loopSeconds = 600.0;

  final CoverLayer layer;
  final CoverScene Function() scene;
  final double Function() seconds;
  final bool compact;
  final double busScale;
  final bool showBus;

  /// Nubes SVG ya cargadas (cloud_1..3). Si está vacía se usa la nube dibujada en código.
  final List<PictureInfo> clouds;

  static const _warm = Color(0xFFFFE2A6);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    canvas.clipRect(Offset.zero & size);
    final sc = scene();
    final s = seconds();
    if (layer == CoverLayer.back) {
      _paintBack(canvas, size, sc, s);
    } else {
      _paintFront(canvas, size, sc, s);
    }
  }

  @override
  bool shouldRepaint(CoverPainter old) => old.layer != layer || old.compact != compact || old.busScale != busScale || old.showBus != showBus || old.clouds != clouds;

  // ───────────────────────────── capa trasera ─────────────────────────────

  void _paintBack(Canvas canvas, Size size, CoverScene sc, double s) {
    final w = size.width;
    final h = size.height;
    final roadTop = h * .86;

    _sky(canvas, size, sc);
    _stars(canvas, size, sc, s);
    _sun(canvas, size, sc);
    _moon(canvas, size, sc);
    _clouds(canvas, size, sc, s);
    _festivalSky(canvas, size, sc, s);

    // Ciudad: capa lejana (con la masa base que oculta el sol al ponerse) y capa cercana.
    canvas.drawRect(Rect.fromLTRB(0, h * CoverScene.horizon, w, roadTop), Paint()..color = sc.far);
    _skyline(canvas, size, sc, s, near: false);
    final roofs = _skyline(canvas, size, sc, s, near: true);

    _ground(canvas, size, sc, s);
    _festivalBack(canvas, size, sc, s, roofs);
  }

  void _sky(Canvas canvas, Size size, CoverScene sc) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()..shader = ui.Gradient.linear(Offset.zero, Offset(0, size.height * CoverScene.horizon), [sc.skyTop, sc.skyBottom]),
    );
    // Velo muy suave arriba: el texto blanco de la cabecera se lee igual de día que de noche.
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height * .5),
      Paint()..shader = ui.Gradient.linear(Offset.zero, Offset(0, size.height * .5), [Colors.black.withOpacity(.16), Colors.black.withOpacity(0)]),
    );
  }

  void _stars(Canvas canvas, Size size, CoverScene sc, double s) {
    final a = ((sc.night - .35) / .65).clamp(0.0, 1.0).toDouble();
    if (a <= .01) return;
    final moon = Offset(sc.moonX * size.width, sc.moonY * size.height);
    final moonR = size.height * .075;
    const periods = [4.0, 5.0, 6.0, 8.0];
    for (var i = 0; i < 36; i++) {
      final p = Offset(_h(i, 1) * size.width, _h(i, 2) * size.height * .38);
      if ((p - moon).distance < moonR * 1.8) continue;
      final period = periods[(_h(i, 3) * 4).floor() % 4];
      final tw = .6 + .4 * math.sin(2 * math.pi * (s / period + _h(i, 4)));
      final r = .7 + _h(i, 5) * 1.1;
      canvas.drawCircle(p, r, Paint()..color = Colors.white.withOpacity(a * tw * (.4 + .5 * _h(i, 6))));
    }
  }

  void _sun(Canvas canvas, Size size, CoverScene sc) {
    final alpha = sc.sunAlpha * (1 - sc.night * .85);
    if (alpha <= .01) return;
    final h = size.height;
    final c = Offset(sc.sunX * size.width, sc.sunY * h);
    final low = ((sc.sunY - .24) / (CoverScene.horizon - .24)).clamp(0.0, 1.0).toDouble(); // 1 = en el horizonte
    final r = h * .09 * (1 + .2 * low);
    canvas.drawCircle(c, r, Paint()..color = sc.sun.withOpacity(alpha));
  }

  void _moon(Canvas canvas, Size size, CoverScene sc) {
    final alpha = sc.moonAlpha;
    if (alpha <= .01) return;
    final h = size.height;
    final c = Offset(sc.moonX * size.width, sc.moonY * h);
    final r = h * .075;
    const color = Color(0xFFFFF3F8);
    // Disco apagado: deja ver la forma aunque sea luna nueva.
    canvas.drawCircle(c, r, Paint()..color = color.withOpacity(.16 * alpha));

    final phase = sc.moonPhase;
    final k = math.cos(2 * math.pi * phase); // 1 nueva … -1 llena
    final tx = (k.abs() * r).clamp(.01, r).toDouble();
    canvas.save();
    if (phase >= .5) {
      // Menguante: la parte iluminada queda a la izquierda (se refleja el dibujo).
      canvas.translate(c.dx, 0);
      canvas.scale(-1, 1);
      canvas.translate(-c.dx, 0);
    }
    final lit = Path()
      ..moveTo(c.dx, c.dy - r)
      ..arcToPoint(Offset(c.dx, c.dy + r), radius: Radius.circular(r), clockwise: true)
      ..arcToPoint(Offset(c.dx, c.dy - r), radius: Radius.elliptical(tx, r), clockwise: k < 0)
      ..close();
    canvas.drawPath(lit, Paint()..color = color.withOpacity(alpha));
    canvas.save();
    canvas.clipPath(lit);
    final crater = Paint()..color = const Color(0xFF8A6A7C).withOpacity(.2 * alpha);
    canvas.drawCircle(c.translate(-r * .3, -r * .2), r * .22, crater);
    canvas.drawCircle(c.translate(r * .25, r * .3), r * .16, crater);
    canvas.drawCircle(c.translate(r * .38, -r * .35), r * .12, crater);
    canvas.restore();
    canvas.restore();
  }

  void _clouds(Canvas canvas, Size size, CoverScene sc, double s) {
    if (sc.cloud.opacity <= .02) return;
    final w = size.width;
    final h = size.height;
    const periods = [120.0, 150.0, 200.0, 300.0];
    const ys = [.2, .12, .3, .08];

    if (clouds.isNotEmpty) {
      // Nubes SVG: el color de la escena las tiñe (blancas de día, rosadas al atardecer, tenues de noche).
      const types = [0, 1, 2, 1];
      final tint = Paint()
        ..colorFilter = ColorFilter.mode(sc.cloud.withOpacity(1), BlendMode.modulate)
        ..color = Colors.white.withOpacity((sc.cloud.opacity * 1.8).clamp(0.0, 1.0).toDouble());
      for (var i = 0; i < 4; i++) {
        final pic = clouds[types[i] % clouds.length];
        final k = h / 300 * (i.isEven ? 1.0 : .8);
        final cw = 140 * k;
        final ch = cw * pic.size.height / pic.size.width;
        final q = (s / periods[i] + _h(i, 7)) % 1.0;
        final x = -cw + q * (w + 2 * cw);
        final y = h * ys[i];
        canvas.saveLayer(Rect.fromLTWH(x, y, cw, ch), tint);
        canvas.translate(x, y);
        canvas.scale(cw / pic.size.width);
        canvas.drawPicture(pic.picture);
        canvas.restore();
      }
      return;
    }

    final paint = Paint()..color = sc.cloud;
    for (var i = 0; i < 4; i++) {
      final k = h / 300 * (i.isEven ? 1.0 : .8);
      final cw = 90 * k;
      final q = (s / periods[i] + _h(i, 7)) % 1.0;
      final x = -cw + q * (w + 2 * cw);
      final y = h * ys[i];
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, y, cw, 18 * k), Radius.circular(9 * k)), paint);
      canvas.drawCircle(Offset(x + 34 * k, y + 4 * k), 15 * k, paint);
      canvas.drawCircle(Offset(x + 58 * k, y + 6 * k), 11 * k, paint);
    }
  }

  /// Dibuja una capa de edificios y devuelve los techos de la cercana (para las luces de fiesta).
  /// Todo (anchos, ventanas, separaciones) escala con el alto de la portada para que la ciudad
  /// conserve su proporción real en cualquier tamaño, y solo se dibuja lo que queda a la vista.
  List<Rect> _skyline(Canvas canvas, Size size, CoverScene sc, double s, {required bool near}) {
    final w = size.width;
    final h = size.height;
    final k = (h / 300).clamp(.4, 1.4).toDouble();
    final roadTop = h * .86;
    final baseY = near ? roadTop : roadTop - 6 * k;
    final minH = near ? h * .1 : h * .18;
    final maxH = near ? h * .3 : h * .42;
    final rnd = _Rng(near ? 11 : 3);
    final body = Paint()..color = near ? sc.near : sc.far;
    final glass = Paint()..color = Colors.white.withOpacity(.2 * (1 - sc.night));
    final roofs = <Rect>[];

    var x = -10.0 * k;
    while (x < w) {
      final bw = (28 + rnd.next() * 38) * k;
      final bh = minH + rnd.next() * (maxH - minH);
      final extra = rnd.next();
      final top = baseY - bh;
      final visible = x + bw > 0; // lo que queda fuera de la pantalla no se dibuja
      if (visible) canvas.drawRect(Rect.fromLTWH(x, top, bw, bh), body);
      if (near) {
        if (visible) {
          roofs.add(Rect.fromLTWH(x, top, bw, bh));
          if (extra > .7) canvas.drawRect(Rect.fromLTWH(x + bw * .2, top - 8 * k, bw * .6, 8 * k), body); // remate escalonado
        }
        for (var wy = top + 10 * k; wy < baseY - 12 * k; wy += 14 * k) {
          for (var wx = x + 6 * k; wx < x + bw - 8 * k; wx += 11 * k) {
            final base = rnd.next();
            final thr = rnd.next();
            if (!visible || wx + 5 * k < 0 || wx > w) continue;
            final win = Rect.fromLTWH(wx, wy, 5 * k, 7 * k);
            if (base > .45) canvas.drawRect(win, glass);
            // Cada ventana se enciende en su propio momento, así el anochecer es gradual.
            final on = ((sc.lit * .7 - thr) * 6).clamp(0.0, 1.0).toDouble();
            if (on > 0) canvas.drawRect(win, Paint()..color = _warm.withOpacity(on * .95));
          }
        }
      } else if (extra > .82 && visible) {
        // Antena con luz roja intermitente de noche.
        canvas.drawRect(Rect.fromLTWH(x + bw * .5, top - 12 * k, 1.6 * k, 12 * k), body);
        final blink = .5 + .5 * math.sin(2 * math.pi * s / 2);
        canvas.drawCircle(
          Offset(x + bw * .5 + .8 * k, top - 12 * k),
          2 * k,
          Paint()..color = const Color(0xFFFF5A7A).withOpacity(sc.night * (.35 + .65 * blink)),
        );
      }
      x += bw + 3 * k;
    }
    return roofs;
  }

  void _ground(Canvas canvas, Size size, CoverScene sc, double s) {
    final w = size.width;
    final h = size.height;
    final k = (h / 300).clamp(.4, 1.4).toDouble();
    final roadTop = h * .86;
    canvas.drawRect(Rect.fromLTWH(0, roadTop - 2, w, h - roadTop + 2), Paint()..color = sc.ground);
    canvas.drawRect(Rect.fromLTWH(0, roadTop + (h - roadTop) * .12, w, (h - roadTop) * .88), Paint()..color = sc.road);

    _vegetation(canvas, size, sc, s, k, roadTop);

    // Farolas: el foco se enciende con la luz que baja (sin resplandor alrededor).
    final pole = Paint()..color = Color.lerp(sc.near, Colors.black, .35)!;
    final lampH = h * .2;
    for (var x = 34.0 * k; x < w; x += 104 * k) {
      final head = Offset(x, roadTop - lampH);
      canvas.drawRect(Rect.fromLTWH(x - k, head.dy, 2 * k, lampH), pole);
      canvas.drawCircle(head, 3 * k, pole);
      final on = ((sc.lit - .1) / .5).clamp(0.0, 1.0).toDouble();
      if (on > 0) canvas.drawCircle(head, 2.6 * k, Paint()..color = _warm.withOpacity(on));
    }
  }

  /// Árboles y arbustos a la orilla de la carretera (sin personas). Todo escala con [k], se tiñe con
  /// la luz del momento (más oscuro de noche) y las copas se mecen apenas con el viento.
  void _vegetation(Canvas canvas, Size size, CoverScene sc, double s, double k, double roadTop) {
    final w = size.width;
    final h = size.height;
    final rnd = _Rng(21);
    final dim = (.18 + .6 * sc.night).clamp(0.0, 1.0).toDouble();
    Color tone(Color c) => Color.lerp(Color.lerp(c, sc.skyBottom, .1)!, sc.near, dim)!;

    final trunk = Paint()..color = tone(const Color(0xFF6B4A3E));
    final greens = [const Color(0xFF4FA37A), const Color(0xFF3E8F68), const Color(0xFF5DB386)];
    const jacaranda = Color(0xFFA77BCB); // jacaranda mexicana
    const rosado = Color(0xFFEE9FBF); // árbol en flor, rosa de la marca

    Color leaf(double r) {
      if (r > .88) return jacaranda;
      if (r > .78) return rosado;
      return greens[(r * 10).floor() % greens.length];
    }

    var x = 10.0 * k;
    var i = 0;
    while (x < w + 20 * k) {
      final kind = rnd.next();
      final hue = rnd.next();
      final sz = rnd.next();
      final sway = math.sin(2 * math.pi * (s / 6 + i * .23)) * 1.2 * k;
      final base = Offset(x, roadTop + 1);
      final c1 = tone(leaf(hue));
      final c2 = c1; // un solo tono por planta: sin sombras ni brillos

      if (kind < .38) {
        // Árbol de copa redonda.
        final th = h * (.07 + .05 * sz);
        final r = h * (.05 + .035 * sz);
        canvas.drawRect(Rect.fromLTWH(x - 1.6 * k, base.dy - th, 3.2 * k, th), trunk);
        final c = Offset(x + sway, base.dy - th - r * .55);
        canvas.drawCircle(c.translate(-r * .55, r * .25), r * .72, Paint()..color = c2);
        canvas.drawCircle(c.translate(r * .55, r * .25), r * .72, Paint()..color = c2);
        canvas.drawCircle(c, r, Paint()..color = c1);
      } else if (kind < .58) {
        // Ciprés: copa alargada.
        final ch = h * (.15 + .07 * sz);
        final cw = h * (.03 + .012 * sz);
        canvas.drawRect(Rect.fromLTWH(x - 1.2 * k, base.dy - 5 * k, 2.4 * k, 5 * k), trunk);
        canvas.drawOval(Rect.fromLTWH(x - cw + sway * .6, base.dy - ch - 3 * k, cw * 2, ch), Paint()..color = c2);
      } else if (kind < .7) {
        // Palmera.
        final th = h * (.12 + .06 * sz);
        final top = Offset(x + sway, base.dy - th);
        final stem = Path()
          ..moveTo(x - 1.6 * k, base.dy)
          ..quadraticBezierTo(x + 3 * k, base.dy - th * .5, top.dx - 1 * k, top.dy)
          ..lineTo(top.dx + 1 * k, top.dy)
          ..quadraticBezierTo(x + 5 * k, base.dy - th * .5, x + 1.6 * k, base.dy)
          ..close();
        canvas.drawPath(stem, trunk);
        final frond = Paint()
          ..color = c1
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 3 * k;
        final fl = h * .065;
        for (var j = 0; j < 7; j++) {
          final a = math.pi * (1.08 + j * .14) + sway * .02;
          final tip = top + Offset(math.cos(a) * fl, math.sin(a) * fl * .55 + fl * .35);
          final mid = top + Offset(math.cos(a) * fl * .5, math.sin(a) * fl * .9);
          canvas.drawPath(Path()..moveTo(top.dx, top.dy)..quadraticBezierTo(mid.dx, mid.dy, tip.dx, tip.dy), frond);
        }
      } else {
        // Arbusto bajo, en grupo de dos o tres bolas.
        final r = h * (.022 + .016 * sz);
        canvas.drawOval(Rect.fromCenter(center: Offset(x, base.dy - r * .6), width: r * 3.4, height: r * 1.5), Paint()..color = c2);
        canvas.drawCircle(Offset(x - r * .8, base.dy - r * .8), r, Paint()..color = c2);
        canvas.drawCircle(Offset(x + r * .7, base.dy - r * .85), r * .9, Paint()..color = c1);
        canvas.drawCircle(Offset(x - r * .05 + sway * .3, base.dy - r * 1.25), r * .95, Paint()..color = c1);
      }
      i++;
      x += (30 + rnd.next() * 46) * k;
    }
  }

  // ───────────────────────────── capa delantera ─────────────────────────────

  void _paintFront(Canvas canvas, Size size, CoverScene sc, double s) {
    sc.festivals.forEach((f, weight) {
      _fade(canvas, size, weight, () => _festivalFront(canvas, size, sc, s, f));
    });
  }

  // ───────────────────────────── fiestas ─────────────────────────────

  /// Dibuja [draw] con opacidad de grupo [weight] (para que una fiesta entre y salga suave).
  void _fade(Canvas canvas, Size size, double weight, VoidCallback draw) {
    if (weight >= .995) {
      draw();
      return;
    }
    canvas.saveLayer(Offset.zero & size, Paint()..color = Colors.white.withOpacity(weight.clamp(0.0, 1.0)));
    draw();
    canvas.restore();
  }

  /// Decoración que va detrás de los edificios (cielo).
  void _festivalSky(Canvas canvas, Size size, CoverScene sc, double s) {
    sc.festivals.forEach((f, weight) {
      _fade(canvas, size, weight, () {
        switch (f) {
          case Festival.anioNuevo:
            _fireworks(canvas, size, sc, s, const [Color(0xFFFFD166), Color(0xFFF7B5CD), Colors.white, Color(0xFF7BDFF2)]);
          case Festival.independencia:
            _fireworks(canvas, size, sc, s, const [Color(0xFF2FBF71), Colors.white, Color(0xFFE5383B)]);
          case Festival.reyes:
            _bethlehemStar(canvas, size, s);
          case Festival.guadalupe:
            _rays(canvas, size, s);
          default:
            break;
        }
      });
    });
  }

  /// Decoración que va delante de los edificios pero detrás del camión.
  void _festivalBack(Canvas canvas, Size size, CoverScene sc, double s, List<Rect> roofs) {
    sc.festivals.forEach((f, weight) {
      _fade(canvas, size, weight, () {
        switch (f) {
          case Festival.navidad:
            _roofLights(canvas, sc, roofs, s, const [Color(0xFFFF5A5F), Color(0xFFFFD166), Color(0xFF4CC38A), Color(0xFF7BDFF2), Colors.white]);
            _trees(canvas, size, s);
          case Festival.reyes:
            _roofLights(canvas, sc, roofs, s, const [Color(0xFFFFD166), Color(0xFFFFF1B8)]);
          case Festival.cincoMayo:
          case Festival.independencia:
            _bunting(canvas, size, const [Color(0xFF2FBF71), Colors.white, Color(0xFFE5383B)], rows: 2);
          case Festival.muertos:
            _bunting(canvas, size, const [Color(0xFFFF9F1C), Color(0xFFE63B8B), Color(0xFF8E5BD9), Color(0xFFFFD166), Color(0xFF4CC9F0)], rows: 2);
          case Festival.halloween:
            _pumpkins(canvas, sc, roofs);
          default:
            break;
        }
      });
    });
  }

  /// Partículas y adornos que pasan por delante de todo.
  void _festivalFront(Canvas canvas, Size size, CoverScene sc, double s, Festival f) {
    switch (f) {
      case Festival.navidad:
        _snow(canvas, size, s);
      case Festival.anioNuevo:
        _confetti(canvas, size, s, const [Color(0xFFFFD166), Color(0xFFF7B5CD), Colors.white, Color(0xFF7BDFF2)]);
      case Festival.reyes:
        _sparkles(canvas, size, s);
      case Festival.amor:
        _hearts(canvas, size, s);
      case Festival.ninos:
        _balloons(canvas, size, s);
      case Festival.cincoMayo:
      case Festival.independencia:
        _confetti(canvas, size, s, const [Color(0xFF2FBF71), Colors.white, Color(0xFFE5383B)]);
      case Festival.madres:
        _petals(canvas, size, s, const [Color(0xFFF7B5CD), Colors.white, Color(0xFFE97FA7), Color(0xFFFFE3EE)]);
      case Festival.halloween:
        _bats(canvas, size, s);
      case Festival.muertos:
        _petals(canvas, size, s, const [Color(0xFFFF9F1C), Color(0xFFFFB627), Color(0xFFFFD166), Color(0xFFFF7B00)]);
      case Festival.guadalupe:
        _petals(canvas, size, s, const [Color(0xFFE63B5E), Color(0xFFF7B5CD), Colors.white, Color(0xFFD94F86)]);
    }
  }

  /// Foco de luces a lo largo de los techos de los edificios cercanos.
  void _roofLights(Canvas canvas, CoverScene sc, List<Rect> roofs, double s, List<Color> colors) {
    final wire = Paint()
      ..color = Colors.black.withOpacity(.3)
      ..strokeWidth = 1;
    for (var i = 0; i < roofs.length; i++) {
      final r = roofs[i];
      canvas.drawLine(Offset(r.left + 2, r.top - 1), Offset(r.right - 2, r.top - 1), wire);
      var j = 0;
      for (var x = r.left + 5; x < r.right - 3; x += 9) {
        final tw = .55 + .45 * math.sin(2 * math.pi * (s / 3 + i * .37 + j * .19));
        final c = colors[(i + j) % colors.length];
        canvas.drawCircle(Offset(x, r.top - 1), 4, Paint()..color = c.withOpacity(.22 * tw * (.4 + .6 * sc.night)));
        canvas.drawCircle(Offset(x, r.top - 1), 1.9, Paint()..color = c.withOpacity(.55 + .45 * tw));
        j++;
      }
    }
  }

  /// Dos pinos con luces y estrella, a la izquierda del camino.
  void _trees(Canvas canvas, Size size, double s) {
    final h = size.height;
    final base = h * .88;
    void tree(double cx, double k) {
      final th = h * .3 * k;
      final tw = h * .19 * k;
      canvas.drawRect(Rect.fromLTWH(cx - tw * .06, base - th * .08, tw * .12, th * .08), Paint()..color = const Color(0xFF5B3A29));
      for (var i = 0; i < 3; i++) {
        final top = base - th + i * th * .27;
        final bottom = top + th * .42;
        final half = tw / 2 * (.55 + .22 * i);
        final p = Path()
          ..moveTo(cx, top)
          ..lineTo(cx + half, bottom)
          ..lineTo(cx - half, bottom)
          ..close();
        canvas.drawPath(p, Paint()..color = Color.lerp(const Color(0xFF1E6B4B), const Color(0xFF2A8A60), i / 2)!);
      }
      const colors = [Color(0xFFFF5A5F), Color(0xFFFFD166), Colors.white, Color(0xFF7BDFF2)];
      for (var i = 0; i < 14; i++) {
        final fy = .16 + _h(i, 5) * .76;
        final half = tw / 2 * (.2 + .8 * fy) * .8;
        final p = Offset(cx + (_h(i, 6) * 2 - 1) * half, base - th + th * fy);
        final tw2 = .5 + .5 * math.sin(2 * math.pi * (s / 3 + _h(i, 7)));
        canvas.drawCircle(p, 2.2, Paint()..color = colors[i % colors.length].withOpacity(.45 + .55 * tw2));
      }
      _star4(canvas, Offset(cx, base - th - 2), tw * .17, const Color(0xFFFFD166));
    }

    tree(size.width * .1, 1.0);
    tree(size.width * .22, .78);
  }

  /// Banderines de papel picado colgados de lado a lado.
  void _bunting(Canvas canvas, Size size, List<Color> colors, {int rows = 1}) {
    final w = size.width;
    final h = size.height;
    final u = (h / 300).clamp(.6, 1.4).toDouble();
    for (var r = 0; r < rows; r++) {
      final y0 = h * (.27 + r * .08);
      final sag = h * (.07 - r * .015);
      final string = Path()..moveTo(0, y0);
      string.quadraticBezierTo(w / 2, y0 + 2 * sag, w, y0);
      canvas.drawPath(
        string,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = Colors.white.withOpacity(.6),
      );
      final step = 26 * u;
      var i = 0;
      for (var x = step / 2 + r * step / 2; x < w; x += step) {
        final t = x / w;
        final y = y0 + 4 * sag * t * (1 - t);
        final fw = 8 * u;
        final fh = 18 * u;
        final flag = Path()
          ..moveTo(x - fw, y)
          ..lineTo(x + fw, y)
          ..lineTo(x + fw, y + fh)
          ..lineTo(x + fw / 2, y + fh + 4 * u)
          ..lineTo(x, y + fh)
          ..lineTo(x - fw / 2, y + fh + 4 * u)
          ..lineTo(x - fw, y + fh)
          ..close();
        canvas.drawPath(flag, Paint()..color = colors[i % colors.length]);
        // Calados del papel picado.
        canvas.drawCircle(Offset(x, y + fh * .42), 2.2 * u, Paint()..color = Colors.black.withOpacity(.14));
        i++;
      }
    }
  }

  /// Fuegos artificiales: solo se ven cuando oscurece.
  void _fireworks(Canvas canvas, Size size, CoverScene sc, double s, List<Color> colors) {
    final vis = ((sc.night - .3) / .5).clamp(0.0, 1.0).toDouble();
    if (vis <= .01) return;
    final w = size.width;
    final h = size.height;
    const xs = [.18, .46, .74];
    const ys = [.3, .2, .28];
    for (var i = 0; i < 3; i++) {
      final p = ((s + i * 2.0) / 6.0) % 1.0;
      if (p > .85) continue;
      final q = p / .85;
      final inv = 1 - q;
      final ease = 1 - inv * inv * inv;
      final r = h * .16 * ease;
      final alpha = vis * math.pow(inv, 1.4).toDouble();
      final cx = w * xs[i];
      final cy = h * ys[i];
      if (q < .1) canvas.drawCircle(Offset(cx, cy), 5 * (1 - q * 10), Paint()..color = Colors.white.withOpacity(vis));
      for (var k = 0; k < 16; k++) {
        final ang = k * 2 * math.pi / 16 + i * .4;
        final sag = q * q * h * .05;
        final c = colors[(k + i) % colors.length];
        final d = Offset(cx + math.cos(ang) * r, cy + math.sin(ang) * r + sag);
        final tail = Offset(cx + math.cos(ang) * r * .82, cy + math.sin(ang) * r * .82 + sag * .7);
        canvas.drawCircle(d, 1.7 * (1 - q * .5), Paint()..color = c.withOpacity(alpha));
        canvas.drawCircle(tail, 1.1, Paint()..color = c.withOpacity(alpha * .5));
      }
    }
  }

  /// Estrella de Belén con su resplandor.
  void _bethlehemStar(Canvas canvas, Size size, double s) {
    final c = Offset(size.width * .14, size.height * .36);
    final r = size.height * .07 * (1 + .08 * math.sin(2 * math.pi * s / 4));
    canvas.drawCircle(
      c,
      r * 3,
      Paint()..shader = ui.Gradient.radial(c, r * 3, [const Color(0xFFFFE08A).withOpacity(.5), const Color(0xFFFFE08A).withOpacity(0)]),
    );
    _star4(canvas, c, r, const Color(0xFFFFD166));
    _star4(canvas, c, r * .55, Colors.white);
  }

  /// Rayos dorados que salen del horizonte.
  void _rays(Canvas canvas, Size size, double s) {
    final c = Offset(size.width * .55, size.height * CoverScene.horizon + size.height * .02);
    final len = size.height * 1.1;
    final sweep = math.sin(2 * math.pi * s / 20) * 3 * math.pi / 180;
    final paint = Paint()..color = const Color(0xFFFFE08A).withOpacity(.16);
    for (var k = -5; k <= 5; k++) {
      final a = -math.pi / 2 + k * 12 * math.pi / 180 + sweep;
      const hw = 2.2 * math.pi / 180;
      final p = Path()
        ..moveTo(c.dx, c.dy)
        ..lineTo(c.dx + math.cos(a - hw) * len, c.dy + math.sin(a - hw) * len)
        ..lineTo(c.dx + math.cos(a + hw) * len, c.dy + math.sin(a + hw) * len)
        ..close();
      canvas.drawPath(p, paint);
    }
  }

  /// Calabazas encendidas sobre dos techos.
  void _pumpkins(Canvas canvas, CoverScene sc, List<Rect> roofs) {
    for (final i in const [1, 4]) {
      if (i >= roofs.length) continue;
      final r = roofs[i];
      final pr = math.min(r.width * .26, 11.0);
      final c = Offset(r.center.dx, r.top - pr * .8);
      canvas.drawOval(Rect.fromCenter(center: c, width: pr * 2, height: pr * 1.7), Paint()..color = const Color(0xFFFF8A1F));
      canvas.drawRect(Rect.fromLTWH(c.dx - 1, c.dy - pr * .95, 2.2, pr * .4), Paint()..color = const Color(0xFF3E7D32));
      final face = Paint()..color = Color.lerp(const Color(0xFF3B1A00), const Color(0xFFFFE08A), sc.night)!;
      final eyes = Path()
        ..moveTo(c.dx - pr * .55, c.dy - pr * .1)
        ..lineTo(c.dx - pr * .15, c.dy - pr * .1)
        ..lineTo(c.dx - pr * .35, c.dy - pr * .45)
        ..close()
        ..moveTo(c.dx + pr * .15, c.dy - pr * .1)
        ..lineTo(c.dx + pr * .55, c.dy - pr * .1)
        ..lineTo(c.dx + pr * .35, c.dy - pr * .45)
        ..close();
      canvas.drawPath(eyes, face);
      final mouth = Path()
        ..moveTo(c.dx - pr * .55, c.dy + pr * .2)
        ..lineTo(c.dx - pr * .3, c.dy + pr * .45)
        ..lineTo(c.dx - pr * .1, c.dy + pr * .2)
        ..lineTo(c.dx + pr * .1, c.dy + pr * .45)
        ..lineTo(c.dx + pr * .3, c.dy + pr * .2)
        ..lineTo(c.dx + pr * .55, c.dy + pr * .45)
        ..lineTo(c.dx + pr * .55, c.dy + pr * .6)
        ..lineTo(c.dx - pr * .55, c.dy + pr * .6)
        ..close();
      canvas.drawPath(mouth, face);
    }
  }

  // ───────────────────────────── partículas ─────────────────────────────

  void _snow(Canvas canvas, Size size, double s) {
    const periods = [10.0, 12.0, 15.0, 20.0];
    for (var i = 0; i < 46; i++) {
      final r = 1.2 + _h(i, 2) * 2.2;
      final period = periods[r > 2.4 ? 0 : (r > 1.9 ? 1 : (r > 1.5 ? 2 : 3))];
      final q = (s / period + _h(i, 3)) % 1.0;
      final x = _h(i, 1) * size.width + math.sin(2 * math.pi * (q * 3 + _h(i, 4))) * 8;
      final y = -6 + q * (size.height + 12);
      canvas.drawCircle(Offset(x, y), r, Paint()..color = Colors.white.withOpacity(.55 + .4 * _h(i, 5)));
    }
  }

  void _confetti(Canvas canvas, Size size, double s, List<Color> colors) {
    const periods = [12.0, 15.0, 20.0, 24.0];
    for (var i = 0; i < 40; i++) {
      final period = periods[i % 4];
      final q = (s / period + _h(i, 3)) % 1.0;
      final x = _h(i, 1) * size.width + math.sin(2 * math.pi * (q * 2 + _h(i, 4))) * 12;
      final y = -8 + q * (size.height + 16);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(2 * math.pi * (q * 2 + _h(i, 5)));
      canvas.drawRect(const Rect.fromLTWH(-2.2, -4, 4.4, 8), Paint()..color = colors[i % colors.length].withOpacity(.9));
      canvas.restore();
    }
  }

  void _petals(Canvas canvas, Size size, double s, List<Color> colors) {
    const periods = [15.0, 20.0, 24.0, 30.0];
    for (var i = 0; i < 30; i++) {
      final period = periods[i % 4];
      final q = (s / period + _h(i, 3)) % 1.0;
      final r = 3 + _h(i, 2) * 3;
      final x = _h(i, 1) * size.width + math.sin(2 * math.pi * (q * 2 + _h(i, 4))) * 14;
      final y = -8 + q * (size.height + 16);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(2 * math.pi * (q + _h(i, 5)));
      canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: r * 1.1, height: r * 1.8), Paint()..color = colors[i % colors.length].withOpacity(.9));
      canvas.restore();
    }
  }

  void _hearts(Canvas canvas, Size size, double s) {
    const periods = [12.0, 15.0, 20.0, 24.0];
    const colors = [Colors.white, Color(0xFFF7B5CD), Color(0xFFFFE3EE)];
    for (var i = 0; i < 16; i++) {
      final period = periods[i % 4];
      final q = (s / period + _h(i, 3)) % 1.0;
      final x = _h(i, 1) * size.width + math.sin(2 * math.pi * (q * 2 + _h(i, 4))) * 10;
      final y = size.height + 10 - q * (size.height + 20);
      final fade = math.sin(math.pi * q);
      _heart(canvas, Offset(x, y), 4 + _h(i, 2) * 6, colors[i % 3].withOpacity((.35 + .5 * _h(i, 5)) * fade));
    }
  }

  void _balloons(Canvas canvas, Size size, double s) {
    const periods = [20.0, 24.0, 30.0, 40.0];
    const colors = [Color(0xFFFFD166), Color(0xFF4CC9F0), Color(0xFFB5E48C), Colors.white, Color(0xFFF7B5CD), Color(0xFFB388EB)];
    for (var i = 0; i < 9; i++) {
      final period = periods[i % 4];
      final q = (s / period + _h(i, 3)) % 1.0;
      final r = 9 + _h(i, 2) * 6;
      final x = _h(i, 1) * size.width + math.sin(2 * math.pi * (q * 1.5 + _h(i, 4))) * 8;
      final y = size.height + r * 3 - q * (size.height + r * 6);
      final c = colors[i % colors.length];
      final string = Path()
        ..moveTo(x, y + r * 1.3)
        ..quadraticBezierTo(x + 5, y + r * 1.3 + 12, x - 2, y + r * 1.3 + 26);
      canvas.drawPath(
        string,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = Colors.white.withOpacity(.7),
      );
      canvas.drawOval(Rect.fromCenter(center: Offset(x, y), width: r * 2, height: r * 2.4), Paint()..color = c);
      final knot = Path()
        ..moveTo(x, y + r * 1.15)
        ..lineTo(x - 2.4, y + r * 1.5)
        ..lineTo(x + 2.4, y + r * 1.5)
        ..close();
      canvas.drawPath(knot, Paint()..color = c);
      canvas.drawOval(Rect.fromCenter(center: Offset(x - r * .4, y - r * .5), width: r * .35, height: r * .6), Paint()..color = Colors.white.withOpacity(.4));
    }
  }

  void _bats(Canvas canvas, Size size, double s) {
    const periods = [20.0, 24.0, 30.0, 40.0, 50.0];
    for (var i = 0; i < 5; i++) {
      final q = (s / periods[i] + _h(i, 3)) % 1.0;
      final dir = i.isEven ? 1.0 : -1.0;
      final x = dir > 0 ? -40 + q * (size.width + 80) : size.width + 40 - q * (size.width + 80);
      final y = size.height * (.12 + .22 * _h(i, 2)) + math.sin(2 * math.pi * (q * 4 + _h(i, 4))) * 10;
      final b = 8 + _h(i, 5) * 5;
      final flap = .35 + .65 * math.sin(2 * math.pi * (s / .8 + _h(i, 6))).abs();
      final p = Path()
        ..moveTo(0, -b * .25)
        ..quadraticBezierTo(-b * .5, -b * .9 * flap, -b * 1.4, -b * .3 * flap)
        ..quadraticBezierTo(-b, 0, -b * .8, b * .35)
        ..quadraticBezierTo(-b * .5, b * .1, -b * .3, b * .45)
        ..quadraticBezierTo(-b * .1, b * .2, 0, b * .5)
        ..quadraticBezierTo(b * .1, b * .2, b * .3, b * .45)
        ..quadraticBezierTo(b * .5, b * .1, b * .8, b * .35)
        ..quadraticBezierTo(b, 0, b * 1.4, -b * .3 * flap)
        ..quadraticBezierTo(b * .5, -b * .9 * flap, 0, -b * .25)
        ..close();
      canvas.save();
      canvas.translate(x, y);
      canvas.drawPath(p, Paint()..color = const Color(0xFF1B1018).withOpacity(.92));
      canvas.restore();
    }
  }

  void _sparkles(Canvas canvas, Size size, double s) {
    const periods = [3.0, 4.0, 5.0, 6.0];
    for (var i = 0; i < 16; i++) {
      final t = math.sin(2 * math.pi * (s / periods[i % 4] + _h(i, 3)));
      if (t <= 0) continue;
      final p = Offset(_h(i, 1) * size.width, _h(i, 2) * size.height * .45);
      _star4(canvas, p, (3 + _h(i, 4) * 4) * t, (i.isEven ? const Color(0xFFFFD166) : Colors.white).withOpacity(t));
    }
  }

  // ───────────────────────────── formas ─────────────────────────────

  void _star4(Canvas canvas, Offset c, double r, Color color) {
    final p = Path();
    for (var i = 0; i < 8; i++) {
      final ang = i * math.pi / 4 - math.pi / 2;
      final rad = i.isEven ? r : r * .22;
      final pt = Offset(c.dx + math.cos(ang) * rad, c.dy + math.sin(ang) * rad);
      if (i == 0) {
        p.moveTo(pt.dx, pt.dy);
      } else {
        p.lineTo(pt.dx, pt.dy);
      }
    }
    p.close();
    canvas.drawPath(p, Paint()..color = color);
  }

  void _heart(Canvas canvas, Offset c, double r, Color color) {
    final p = Path()
      ..moveTo(c.dx, c.dy + r * .9)
      ..cubicTo(c.dx - r * 1.2, c.dy + r * .1, c.dx - r, c.dy - r * .9, c.dx, c.dy - r * .35)
      ..cubicTo(c.dx + r, c.dy - r * .9, c.dx + r * 1.2, c.dy + r * .1, c.dx, c.dy + r * .9)
      ..close();
    canvas.drawPath(p, Paint()..color = color);
  }
}

/// Número pseudoaleatorio estable (0 … 1) para la posición `i` y el "canal" `k`: la misma
/// partícula cae siempre en el mismo sitio, sin guardar nada.
double _h(int i, int k) {
  final v = math.sin(i * 12.9898 + k * 78.233 + 4.1414) * 43758.5453;
  return v - v.floorToDouble();
}

/// Generador pseudoaleatorio simple y determinista (la ciudad no cambia entre pintados).
class _Rng {
  _Rng(this._s);
  int _s;
  double next() {
    _s = (_s * 1103515245 + 12345) & 0x7fffffff;
    return (_s % 10000) / 10000;
  }
}
