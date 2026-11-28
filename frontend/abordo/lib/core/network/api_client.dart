import 'package:dio/dio.dart';

import '../config/app_config.dart';
import 'api_exception.dart';

typedef Json = Map<String, dynamic>;

/// Único punto de acceso HTTP de la app: agrega el token, traduce errores y decodifica JSON.
class ApiClient {
  ApiClient({
    required String? Function() getToken,
    required void Function() onUnauthorized,
    Dio? dio,
  })  : _getToken = getToken,
        _onUnauthorized = onUnauthorized,
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: '${AppConfig.apiUrl}/api',
                connectTimeout: AppConfig.connectTimeout,
                receiveTimeout: AppConfig.receiveTimeout,
                contentType: Headers.jsonContentType,
              ),
            );

  final Dio _dio;
  final String? Function() _getToken;
  final void Function() _onUnauthorized;

  /// Despierta el servidor (Render gratis se duerme) en cuanto abre la app, sin bloquear ni mostrar errores.
  static Future<void> wakeServer() async {
    try {
      await Dio(BaseOptions(connectTimeout: AppConfig.connectTimeout, receiveTimeout: const Duration(seconds: 90)))
          .get<Object?>('${AppConfig.apiUrl}/health');
    } catch (_) {
      // Es solo un calentamiento: si falla, la primera petición real reintentará.
    }
  }

  Future<Json> get(String path, {Json? query}) => _send('GET', path, query: query);
  Future<Json> post(String path, {Object? body}) => _send('POST', path, body: body ?? <String, dynamic>{});
  Future<Json> put(String path, {Object? body}) => _send('PUT', path, body: body);
  Future<Json> patch(String path, {Object? body}) => _send('PATCH', path, body: body);
  Future<Json> delete(String path) => _send('DELETE', path);

  Future<Json> _send(String method, String path, {Object? body, Json? query}) async {
    try {
      final token = _getToken();
      final res = await _dio.request<Object?>(
        path,
        data: body,
        queryParameters: query,
        options: Options(method: method, headers: {if (token != null) 'Authorization': 'Bearer $token'}),
      );
      final data = res.data;
      return data is Map<String, dynamic> ? data : <String, dynamic>{};
    } on DioException catch (e) {
      throw _translate(e);
    }
  }

  ApiException _translate(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;
    final error = data is Map ? data['error'] : null;

    if (status == 401 && _getToken() != null) _onUnauthorized();

    if (error is Map && error['message'] is String) {
      return ApiException(error['message'] as String, status: status, code: error['code'] as String?);
    }
    if (status == 409) return ApiException('Ese usuario ya existe. Elige otro.', status: status, code: 'duplicate');
    return switch (e.type) {
      DioExceptionType.connectionError =>
        const ApiException('No hay conexión a internet. Revisa tu señal e intenta otra vez.'),
      DioExceptionType.connectionTimeout || DioExceptionType.sendTimeout || DioExceptionType.receiveTimeout =>
        const ApiException('El servidor tardó en responder. Intenta de nuevo en unos segundos.'),
      _ => ApiException('Algo salió mal. Intenta de nuevo.', status: status),
    };
  }
}
