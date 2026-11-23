import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'network/api_client.dart';
import 'storage/local_store.dart';
import '../features/auth/state/session_controller.dart';

final localStoreProvider = Provider<LocalStore>((_) => const LocalStore());

/// El token y el cierre de sesión se leen al momento de cada petición (no al construir),
/// así no hay dependencia circular con la sesión.
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    getToken: () => ref.read(sessionProvider).valueOrNull?.token,
    onUnauthorized: () => ref.read(sessionProvider.notifier).expire(),
  );
});
