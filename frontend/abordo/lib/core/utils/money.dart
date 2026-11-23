import 'package:intl/intl.dart';

abstract final class Money {
  static final _whole = NumberFormat.currency(locale: 'es_MX', symbol: r'$', decimalDigits: 0);
  static final _cents = NumberFormat.currency(locale: 'es_MX', symbol: r'$', decimalDigits: 2);

  /// 1200 -> "$12", 1250 -> "$12.50". Los centavos solo se muestran cuando existen.
  static String format(int cents) => cents % 100 == 0 ? _whole.format(cents / 100) : _cents.format(cents / 100);

  /// Texto pensado para voz: 1200 -> "12 pesos", 100 -> "1 peso".
  static String spoken(int cents) {
    final pesos = cents / 100;
    final n = cents % 100 == 0 ? pesos.toStringAsFixed(0) : pesos.toStringAsFixed(2);
    return cents == 100 ? '1 peso' : '$n pesos';
  }

  /// "12" o "12.50" -> centavos. Devuelve null si no es un monto válido.
  static int? parseToCents(String input) {
    final v = double.tryParse(input.trim().replaceAll(',', '.'));
    return v == null ? null : (v * 100).round();
  }
}
