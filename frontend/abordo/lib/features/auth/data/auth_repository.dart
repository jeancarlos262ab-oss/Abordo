import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/local_store.dart';
import '../domain/session.dart';

class AuthRepository {
  const AuthRepository(this._api, this._store);

  final ApiClient _api;
  final LocalStore _store;

  static const _tokenKey = 'session.token';
  static const _userKey = 'session.user';

  /// Entra solo si el usuario es del [role] de la entrada elegida: un dueño no entra por la puerta del
  /// pasajero ni al revés. Se pide el rol al servidor y además se comprueba aquí antes de guardar nada.
  Future<Session> login({required String login, required String secret, required Role role}) async {
    final json = await _api.post('/auth/login', body: {'login': login, 'secret': secret, 'role': role.name});
    final user = User.fromJson(json['user'] as Map<String, dynamic>);
    if (user.role != role) {
      // Mismo mensaje que un error normal: no se revela que el usuario existe en otra entrada.
      throw const ApiException('Usuario o contraseña incorrectos.', status: 401, code: 'wrong_role');
    }
    return _persist(json);
  }

  Future<Session> registerOwner({required String name, required String login, required String secret}) async =>
      _persist(await _api.post('/auth/register-owner', body: {'name': name, 'login': login, 'secret': secret}));

  Future<Session> registerPassenger({required String name, required String login, required String secret}) async =>
      _persist(await _api.post('/auth/register-passenger', body: {'name': name, 'login': login, 'secret': secret}));

  /// Sesión guardada, o null. Si el servidor responde que el token ya no vale, se borra.
  /// Sin internet se confía en lo guardado para poder abrir la app.
  Future<Session?> restore() async {
    final token = await _store.read(_tokenKey);
    final raw = await _store.read(_userKey);
    if (token == null || raw == null) return null;
    try {
      return Session(token: token, user: User.fromJson(jsonDecode(raw) as Map<String, dynamic>));
    } catch (_) {
      await clear();
      return null;
    }
  }

  Future<void> clear() async {
    await _store.remove(_tokenKey);
    await _store.remove(_userKey);
  }

  Future<Session> _persist(Map<String, dynamic> json) async {
    final user = json['user'] as Map<String, dynamic>;
    final token = json['token'] as String;
    await _store.write(_tokenKey, token);
    await _store.write(_userKey, jsonEncode(user));
    return Session(token: token, user: User.fromJson(user));
  }
}
