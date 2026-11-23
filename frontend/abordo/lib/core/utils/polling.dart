import 'dart:async';

import '../network/api_exception.dart';

/// Consulta `fetch` cada `every` y emite cada resultado. Termina cuando `until` lo indica.
///
/// Un fallo de red aislado es pasajero y se reintenta sin romper la pantalla; tras
/// [maxFailures] fallos seguidos el error se propaga para que la UI ofrezca "Reintentar".
/// Una sesión vencida se propaga de inmediato.
Stream<T> poll<T>(
  Duration every,
  Future<T> Function() fetch, {
  bool Function(T value)? until,
  int maxFailures = 3,
}) async* {
  var failures = 0;
  while (true) {
    try {
      final value = await fetch();
      failures = 0;
      yield value;
      if (until != null && until(value)) return;
    } on ApiException catch (e) {
      failures++;
      if (e.isAuth || failures >= maxFailures) rethrow;
    }
    await Future<void>.delayed(every);
  }
}
