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
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 15),
                contentType: Headers.jsonContentType,
              ),
            );

  final Dio _dio;
  final String? Function() _getToken;
  final void Function() _onUnauthorized;

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
    return switch (e.type) {
      DioExceptionType.connectionError ||
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        const ApiException('No hay conexión a internet. Revisa tu señal e intenta otra vez.'),
      _ => ApiException('Algo salió mal. Intenta de nuevo.', status: status),
    };
  }
}
