/// Configuración en tiempo de compilación. Por defecto apunta al backend en Render; para otro servidor:
///   `flutter run --dart-define=API_URL=https://otro-servidor.com`
/// Backend local desde el emulador de Android (10.0.2.2 es el "localhost" de tu computadora):
///   `flutter run --dart-define=API_URL=http://10.0.2.2:3000`
abstract final class AppConfig {
  static const apiUrl = String.fromEnvironment('API_URL', defaultValue: 'https://abordo.onrender.com');

  /// Render (plan gratuito) apaga el servidor tras un rato sin uso y la primera petición tarda hasta ~1 min en
  /// despertarlo; con timeouts cortos la app mostraría un falso "sin internet". Sin señal el error es inmediato.
  static const connectTimeout = Duration(seconds: 30);
  static const receiveTimeout = Duration(seconds: 60);

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
