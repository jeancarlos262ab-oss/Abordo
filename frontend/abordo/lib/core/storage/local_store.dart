import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Almacenamiento local seguro de claves simples (sesión y preferencias).
class LocalStore {
  const LocalStore([this._storage = const FlutterSecureStorage()]);

  final FlutterSecureStorage _storage;

  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (_) {
      return null; // almacenamiento corrupto: se comporta como vacío
    }
  }

  Future<void> write(String key, String value) => _storage.write(key: key, value: value);
  Future<void> remove(String key) => _storage.delete(key: key);
}
