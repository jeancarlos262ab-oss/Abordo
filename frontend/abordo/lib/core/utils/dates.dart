import 'package:intl/intl.dart';

import '../config/app_config.dart';

/// Todo el negocio opera en hora de México. Estas funciones no dependen de la zona del teléfono.
abstract final class AppDates {
  static const _offset = Duration(hours: AppConfig.mxUtcOffsetHours);

  static DateTime _mx(DateTime utc) => utc.toUtc().add(_offset);

  /// Hoy en México como "AAAA-MM-DD" (clave que entiende el backend).
  static String todayKey() => key(_mx(DateTime.now()));

  static String key(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  static DateTime fromKey(String key) {
    final p = key.split('-').map(int.parse).toList();
    return DateTime(p[0], p[1], p[2]);
  }

  static String shiftKey(String key, int days) => AppDates.key(fromKey(key).add(Duration(days: days)));

  /// "jueves 19 de noviembre"
  static String longDay(String key) => DateFormat("EEEE d 'de' MMMM", 'es_MX').format(fromKey(key));

  /// "8:15 a. m." a partir de un ISO UTC.
  /// "26 nov, 9:17 p. m." a partir de una fecha ISO en UTC.
  static String dayTime(String isoUtc) => DateFormat("d MMM, h:mm a", 'es_MX').format(_mx(DateTime.parse(isoUtc)));

  static String time(String isoUtc) => DateFormat('h:mm a', 'es_MX').format(_mx(DateTime.parse(isoUtc)));

  static String hourLabel(int hour) => DateFormat('h a', 'es_MX').format(DateTime(2000, 1, 1, hour));
}
