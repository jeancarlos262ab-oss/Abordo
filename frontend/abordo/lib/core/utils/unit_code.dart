import '../config/app_config.dart';

/// El QR fijo de cada unidad trae un enlace como `https://abordo.mx/u/123456`.
/// Este parser también acepta el número suelto, por si la persona lo teclea.
abstract final class UnitCode {
  static final _link = RegExp(r'/u/(\d+)\s*$');
  static final _digits = RegExp('^\\d{${AppConfig.unitCodeMin},${AppConfig.unitCodeMax}}\$');

  static String? parse(String raw) {
    final text = raw.trim();
    final fromLink = _link.firstMatch(text)?.group(1);
    final candidate = fromLink ?? text;
    return _digits.hasMatch(candidate) ? candidate : null;
  }
}
