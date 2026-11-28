import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'session_controller.dart';

/// Foto de perfil de quien tiene la sesión abierta (bytes de la imagen), o null si no ha subido una.
/// Se vuelve a pedir al cambiar de usuario; después de subir o quitar la foto basta con
/// `ref.invalidate(avatarProvider)`.
final avatarProvider = FutureProvider<Uint8List?>((ref) async {
  final id = ref.watch(sessionProvider.select((s) => s.valueOrNull?.user.id));
  if (id == null) return null;
  final uri = await ref.watch(authRepositoryProvider).avatar();
  if (uri == null) return null;
  return base64Decode(uri.substring(uri.indexOf(',') + 1));
});
