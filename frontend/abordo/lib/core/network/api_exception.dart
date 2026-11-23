/// Error de la API ya traducido a un mensaje que una persona puede entender.
class ApiException implements Exception {
  const ApiException(this.message, {this.status, this.code});

  final String message;
  final int? status;
  final String? code;

  bool get isAuth => status == 401;

  @override
  String toString() => message;
}

/// Mensaje seguro para mostrar en pantalla, venga de donde venga el error.
String friendlyError(Object error) =>
    error is ApiException ? error.message : 'Algo salió mal. Intenta de nuevo.';
