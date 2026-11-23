import 'package:flutter/material.dart';

import '../network/api_exception.dart';
import 'dialogs.dart';

/// Comportamiento común de las pantallas con formulario: validar, mostrar "cargando",
/// ejecutar la acción y avisar el error con un mensaje claro. Evita repetir try/catch.
mixin SubmitMixin<T extends StatefulWidget> on State<T> {
  final formKey = GlobalKey<FormState>();
  bool busy = false;

  /// Devuelve true si la acción terminó bien.
  Future<bool> submit(Future<void> Function() action) async {
    if (busy || !(formKey.currentState?.validate() ?? false)) return false;
    setState(() => busy = true);
    try {
      await action();
      return true;
    } catch (e) {
      if (mounted) showMessage(context, friendlyError(e), error: true);
      return false;
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
}
