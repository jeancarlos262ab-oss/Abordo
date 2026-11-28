import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/auth_repository.dart';
import '../domain/session.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(apiClientProvider), ref.watch(localStoreProvider)),
);

/// Sesión actual: null = nadie ha iniciado sesión. Es lo único que decide qué pantalla raíz se ve.
final sessionProvider = AsyncNotifierProvider<SessionController, Session?>(SessionController.new);

class SessionController extends AsyncNotifier<Session?> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  Future<Session?> build() => _repo.restore();

  /// [role] es la entrada desde la que se intenta entrar: cada una solo acepta a sus propios usuarios.
  Future<void> login({required String login, required String secret, required Role role}) async {
    final session = await _repo.login(login: login.trim(), secret: secret, role: role);
    state = AsyncData(session);
  }

  Future<void> registerOwner({required String name, required String login, required String secret}) async {
    final session = await _repo.registerOwner(name: name.trim(), login: login.trim(), secret: secret);
    state = AsyncData(session);
  }

  Future<void> registerPassenger({required String name, required String login, required String secret}) async {
    final session = await _repo.registerPassenger(name: name.trim(), login: login.trim(), secret: secret);
    state = AsyncData(session);
  }

  Future<void> logout() async {
    await _repo.clear();
    state = const AsyncData(null);
  }

  /// El servidor dijo que el token ya no vale: se regresa al inicio sin preguntar.
  void expire() {
    if (state.valueOrNull == null) return;
    unawaited(logout());
  }
}
