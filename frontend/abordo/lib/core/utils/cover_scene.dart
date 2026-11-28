import 'dart:math' as math;
import 'dart:ui' show Color;

import 'package:flutter/foundation.dart' show immutable;

/// Fiestas que la portada celebra sola. Solo hay una activa a la vez (la primera que coincida).
enum Festival {
  navidad('Navidad'),
  anioNuevo('Año Nuevo'),
  reyes('Día de Reyes'),
  amor('San Valentín'),
  ninos('Día del Niño'),
  cincoMayo('5 de Mayo'),
  madres('Día de las Madres'),
  independencia('Independencia'),
  halloween('Halloween'),
  muertos('Día de Muertos'),
  guadalupe('Virgen de Guadalupe');

  const Festival(this.label);
  final String label;

  /// Fiesta que corresponde a [d], o null si es un día normal.
  /// Las fechas son fijas (calendario de México); para cambiarlas basta editar esta lista.
  static Festival? on(DateTime d) {
    final x = d.month * 100 + d.day;
    bool within(int m1, int d1, int m2, int d2) {
      final a = m1 * 100 + d1;
      final b = m2 * 100 + d2;
      return a <= b ? (x >= a && x <= b) : (x >= a || x <= b); // el rango puede cruzar el año
    }

    if (within(12, 31, 1, 1)) return Festival.anioNuevo;
    if (within(1, 2, 1, 6)) return Festival.reyes;
    if (within(2, 12, 2, 14)) return Festival.amor;
    if (within(4, 30, 4, 30)) return Festival.ninos;
    if (within(5, 3, 5, 5)) return Festival.cincoMayo;
    if (within(5, 8, 5, 10)) return Festival.madres;
    if (within(9, 10, 9, 16)) return Festival.independencia;
    if (within(10, 24, 10, 30)) return Festival.halloween;
    if (within(10, 31, 11, 2)) return Festival.muertos;
    if (within(12, 10, 12, 12)) return Festival.guadalupe; // antes que Navidad: tiene prioridad
    if (within(12, 1, 12, 30)) return Festival.navidad;
    return null;
  }
}

/// Colores y luz de un momento del día (un fotograma clave).
@immutable
class _Look {
  const _Look({
    required this.skyTop,
    required this.skyBottom,
    required this.sun,
    required this.far,
    required this.near,
    required this.ground,
    required this.road,
    required this.cloud,
    required this.night,
    required this.lit,
  });

  final Color skyTop;
  final Color skyBottom;
  final Color sun;
  final Color far;
  final Color near;
  final Color ground;
  final Color road;
  final Color cloud;

  /// 0 = pleno día … 1 = noche cerrada (estrellas, luna, faros).
  final double night;

  /// 0 … 1: cuántas ventanas y farolas están encendidas.
  final double lit;

  static _Look lerp(_Look a, _Look b, double t) => _Look(
        skyTop: Color.lerp(a.skyTop, b.skyTop, t)!,
        skyBottom: Color.lerp(a.skyBottom, b.skyBottom, t)!,
        sun: Color.lerp(a.sun, b.sun, t)!,
        far: Color.lerp(a.far, b.far, t)!,
        near: Color.lerp(a.near, b.near, t)!,
        ground: Color.lerp(a.ground, b.ground, t)!,
        road: Color.lerp(a.road, b.road, t)!,
        cloud: Color.lerp(a.cloud, b.cloud, t)!,
        night: _mix(a.night, b.night, t),
        lit: _mix(a.lit, b.lit, t),
      );
}

double _mix(double a, double b, double t) => a + (b - a) * t;

// Paleta de Inter Miami (rosa #F7B5CD y negro) en cada momento del día. El cielo es grafito arriba
// y rosa en el horizonte, así el texto blanco de las cabeceras se lee siempre; la ciudad va en negro.
const _night = _Look(
  skyTop: Color(0xFF0F0D0E), skyBottom: Color(0xFF3A2A31), sun: Color(0xFFFFF3F8),
  far: Color(0xFF2A2326), near: Color(0xFF141112), ground: Color(0xFF2A2A2C),
  road: Color(0xFF110F10), cloud: Color(0x12F7B5CD), night: 1, lit: 1,
);
const _dawn = _Look(
  skyTop: Color(0xFF2D2430), skyBottom: Color(0xFFF2A9C3), sun: Color(0xFFFFD6B0),
  far: Color(0xFF6B4A5E), near: Color(0xFF2A2126), ground: Color(0xFF9A9A9F),
  road: Color(0xFF231A20), cloud: Color(0x66FFC9B8), night: .55, lit: .55,
);
const _morning = _Look(
  skyTop: Color(0xFF3A2E36), skyBottom: Color(0xFFF7B5CD), sun: Color(0xFFFFEBC4),
  far: Color(0xFF7A5568), near: Color(0xFF2B2327), ground: Color(0xFFBDBDC2),
  road: Color(0xFF231F20), cloud: Color(0x66FFFFFF), night: .05, lit: .08,
);
const _day = _Look(
  skyTop: Color(0xFF40343C), skyBottom: Color(0xFFF7B5CD), sun: Color(0xFFFFF1D6),
  far: Color(0xFF8A5F73), near: Color(0xFF231F20), ground: Color(0xFFBDBDC2),
  road: Color(0xFF231F20), cloud: Color(0x52FFFFFF), night: 0, lit: 0,
);
const _golden = _Look(
  skyTop: Color(0xFF3D2E36), skyBottom: Color(0xFFF5A8C0), sun: Color(0xFFFFE2A8),
  far: Color(0xFF7E5266), near: Color(0xFF231A1E), ground: Color(0xFFB0B0B5),
  road: Color(0xFF231A1E), cloud: Color(0x66FFD9B8), night: .1, lit: .12,
);
const _sunset = _Look(
  skyTop: Color(0xFF2E2230), skyBottom: Color(0xFFE98AAE), sun: Color(0xFFFFC98A),
  far: Color(0xFF5E3F52), near: Color(0xFF1E171B), ground: Color(0xFF8F8F94),
  road: Color(0xFF1E161A), cloud: Color(0x70FFB59E), night: .3, lit: .4,
);
const _dusk = _Look(
  skyTop: Color(0xFF1A1320), skyBottom: Color(0xFF9C5878), sun: Color(0xFFFFD0B0),
  far: Color(0xFF3E2C3A), near: Color(0xFF1A1418), ground: Color(0xFF55555A),
  road: Color(0xFF181216), cloud: Color(0x40E8A0C0), night: .78, lit: .9,
);

/// Todo lo que la portada necesita para dibujarse en un instante: colores, luz, posición del
/// sol y de la luna y fiestas activas. Es una función continua del reloj, así que se puede
/// interpolar con [lerp] para que los cambios (amanecer, atardecer, una fiesta que empieza a
/// medianoche) ocurran de forma suave mientras la persona sigue en la pantalla.
@immutable
class CoverScene {
  const CoverScene({
    required this.skyTop,
    required this.skyBottom,
    required this.sun,
    required this.far,
    required this.near,
    required this.ground,
    required this.road,
    required this.cloud,
    required this.night,
    required this.lit,
    required this.sunX,
    required this.sunY,
    required this.sunAlpha,
    required this.moonX,
    required this.moonY,
    required this.moonAlpha,
    required this.moonPhase,
    required this.festivals,
  });

  final Color skyTop;
  final Color skyBottom;
  final Color sun;
  final Color far;
  final Color near;
  final Color ground;
  final Color road;
  final Color cloud;

  final double night;
  final double lit;

  /// Posiciones normalizadas (0 … 1 del ancho y del alto de la portada).
  final double sunX;
  final double sunY;
  final double sunAlpha;
  final double moonX;
  final double moonY;
  final double moonAlpha;

  /// 0 = luna nueva, .25 = cuarto creciente, .5 = llena, .75 = cuarto menguante.
  final double moonPhase;

  /// Peso (0 … 1) de cada fiesta activa; al cambiar de fiesta una sube y la otra baja.
  final Map<Festival, double> festivals;

  /// Línea del horizonte (fracción del alto): el sol y la luna se ocultan detrás de ella.
  static const horizon = .68;

  /// Punto más alto del arco del sol y la luna.
  static const _peak = .24;

  /// Aproximación del orto y el ocaso para el centro de México (Puebla), según el día del año.
  static (double, double) sunTimes(DateTime d) {
    final doy = d.difference(DateTime(d.year)).inDays;
    final s = math.cos(2 * math.pi * (doy - 172) / 365.25); // 1 en junio, -1 en diciembre
    final half = 6.08 + .52 * s; // medio día solar en horas
    const noon = 12.55;
    return (noon - half, noon + half);
  }

  /// Fase de la luna (0 … 1) para la fecha [d].
  static double moonPhaseOf(DateTime d) {
    final days = d.toUtc().difference(DateTime.utc(2000, 1, 6, 18, 14)).inMinutes / 1440.0;
    return (days / 29.530588853) % 1.0;
  }

  static double _smooth(double t) => t * t * (3 - 2 * t);

  static _Look _lookAt(double h, double sr, double ss) {
    final keys = <(double, _Look)>[
      (sr - 1.2, _night),
      (sr - .15, _dawn),
      (sr + 1.2, _morning),
      (sr + 3.0, _day),
      (ss - 3.0, _day),
      (ss - 1.0, _golden),
      (ss + .1, _sunset),
      (ss + .9, _dusk),
      (ss + 1.8, _night),
    ];
    if (h <= keys.first.$1 || h >= keys.last.$1) return _night;
    for (var i = 0; i < keys.length - 1; i++) {
      final (ta, la) = keys[i];
      final (tb, lb) = keys[i + 1];
      if (h <= tb) {
        final t = ((h - ta) / (tb - ta)).clamp(0.0, 1.0).toDouble();
        return _Look.lerp(la, lb, _smooth(t));
      }
    }
    return _night;
  }

  /// La escena que corresponde al momento [now] (hora local del teléfono).
  factory CoverScene.at(DateTime now) {
    final h = now.hour + now.minute / 60 + now.second / 3600;
    final (sr, ss) = sunTimes(now);
    final look = _lookAt(h, sr, ss);

    // Sol: sale por la izquierda, sube y se pone por la derecha detrás de los edificios.
    final u = (h - sr) / (ss - sr);
    final uc = u.clamp(-.15, 1.15).toDouble();
    final sunX = .28 + .64 * uc;
    final sunY = horizon - math.sin(math.pi * uc) * (horizon - _peak);
    final sunAlpha = (u > -.12 && u < 1.12) ? 1.0 : 0.0;

    // Luna: hace el mismo recorrido durante la noche.
    final len = 24 - (ss - sr);
    final v = h >= ss ? (h - ss) / len : (h + 24 - ss) / len;
    final vc = v.clamp(-.15, 1.15).toDouble();
    final moonX = .28 + .64 * vc;
    final moonY = horizon - math.sin(math.pi * vc) * (horizon - _peak);
    final moonAlpha = ((look.night - .25) / .5).clamp(0.0, 1.0).toDouble();

    final fest = Festival.on(now);
    return CoverScene(
      skyTop: look.skyTop,
      skyBottom: look.skyBottom,
      sun: look.sun,
      far: look.far,
      near: look.near,
      ground: look.ground,
      road: look.road,
      cloud: look.cloud,
      night: look.night,
      lit: look.lit,
      sunX: sunX,
      sunY: sunY,
      sunAlpha: sunAlpha,
      moonX: moonX,
      moonY: moonY,
      moonAlpha: moonAlpha,
      moonPhase: moonPhaseOf(now),
      festivals: fest == null ? const {} : {fest: 1.0},
    );
  }

  /// Interpola la fase por el camino corto (de .99 a .01 pasa por luna nueva, no por todas).
  static double _lerpPhase(double a, double b, double t) {
    var d = b - a;
    if (d > .5) d -= 1;
    if (d < -.5) d += 1;
    return (a + d * t) % 1.0;
  }

  static CoverScene lerp(CoverScene a, CoverScene b, double t) {
    final fest = <Festival, double>{};
    for (final k in {...a.festivals.keys, ...b.festivals.keys}) {
      final v = _mix(a.festivals[k] ?? 0, b.festivals[k] ?? 0, t);
      if (v > .001) fest[k] = v;
    }
    Color c(Color x, Color y) => Color.lerp(x, y, t)!;
    double d(double x, double y) => _mix(x, y, t);
    return CoverScene(
      skyTop: c(a.skyTop, b.skyTop),
      skyBottom: c(a.skyBottom, b.skyBottom),
      sun: c(a.sun, b.sun),
      far: c(a.far, b.far),
      near: c(a.near, b.near),
      ground: c(a.ground, b.ground),
      road: c(a.road, b.road),
      cloud: c(a.cloud, b.cloud),
      night: d(a.night, b.night),
      lit: d(a.lit, b.lit),
      sunX: d(a.sunX, b.sunX),
      sunY: d(a.sunY, b.sunY),
      sunAlpha: d(a.sunAlpha, b.sunAlpha),
      moonX: d(a.moonX, b.moonX),
      moonY: d(a.moonY, b.moonY),
      moonAlpha: d(a.moonAlpha, b.moonAlpha),
      moonPhase: _lerpPhase(a.moonPhase, b.moonPhase, t),
      festivals: fest,
    );
  }
}
