/// Configuración en tiempo de compilación:
/// `flutter run --dart-define=API_URL=https://api.tu-dominio.mx`
abstract final class AppConfig {
  /// 10.0.2.2 es el "localhost" de la computadora vista desde el emulador de Android.
  static const apiUrl = String.fromEnvironment('API_URL', defaultValue: 'http://10.0.2.2:3000');

  /// Zona horaria de operación: México (CDMX) no usa horario de verano, UTC−6 fijo.
  static const mxUtcOffsetHours = -6;

  /// Cada cuánto se consulta el estado de un pago, los pagos del chofer y el panel del dueño.
  static const payStatusPoll = Duration(seconds: 2);
  static const driverPaymentsPoll = Duration(seconds: 3);
  static const ownerPanelPoll = Duration(seconds: 10);

  /// Largo del código público de cada unidad (el que va en el QR fijo).
  static const unitCodeMin = 4;
  static const unitCodeMax = 8;
}
