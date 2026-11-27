/// Punto geográfico simple (sin depender del mapa).
class GeoPoint {
  const GeoPoint(this.lat, this.lng);
  final double lat;
  final double lng;
}

/// Recorrido de una ruta: la lista de puntos por donde pasa la unidad, en orden.
/// El servidor puede mandarlo como `routePath: [[lat, lng], ...]`; si no llega, se usa [demo].
class RoutePath {
  const RoutePath(this.points);

  /// Lee `[[lat, lng], ...]`. Devuelve null si no hay al menos dos puntos válidos.
  static RoutePath? fromJson(Object? json) {
    if (json is! List) return null;
    final pts = <GeoPoint>[];
    for (final p in json) {
      if (p is List && p.length >= 2 && p[0] is num && p[1] is num) {
        pts.add(GeoPoint((p[0] as num).toDouble(), (p[1] as num).toDouble()));
      }
    }
    return pts.length >= 2 ? RoutePath(pts) : null;
  }

  final List<GeoPoint> points;

  GeoPoint get start => points.first;
  GeoPoint get end => points.last;

  /// Recorrido de ejemplo (Zócalo → Chapultepec, CDMX) para cuando la ruta aún no trae su trazo.
  static const demo = RoutePath([
    GeoPoint(19.43260, -99.13320),
    GeoPoint(19.43340, -99.13720),
    GeoPoint(19.43520, -99.14120),
    GeoPoint(19.43510, -99.14500),
    GeoPoint(19.43300, -99.15200),
    GeoPoint(19.43000, -99.15900),
    GeoPoint(19.42700, -99.16770),
    GeoPoint(19.42400, -99.17500),
    GeoPoint(19.42040, -99.18190),
  ]);
}
