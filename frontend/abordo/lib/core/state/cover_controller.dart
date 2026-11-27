import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../providers.dart';

@immutable
class CoverState {
  const CoverState({this.photo});

  /// Foto del usuario; si existe, tiene prioridad sobre la portada automática.
  final Uint8List? photo;
}

/// Portada de las pantallas principales. Por defecto es una ilustración que cambia sola según
/// la hora, el día y las fiestas del año (ver `CoverScene`); el usuario puede reemplazarla por
/// una foto de su galería. La foto se guarda en el teléfono.
class CoverController extends Notifier<CoverState> {
  static const _kPhoto = 'cover_photo';

  /// Clave de la versión anterior (ilustración elegida a mano); ya no se usa.
  static const _kLegacyArt = 'cover_art';

  @override
  CoverState build() {
    Future.microtask(_load);
    return const CoverState();
  }

  Future<void> _load() async {
    final store = ref.read(localStoreProvider);
    final photo = await store.read(_kPhoto);
    Uint8List? bytes;
    if (photo != null && photo.isNotEmpty) {
      try {
        bytes = base64Decode(photo);
      } catch (_) {
        bytes = null;
      }
    }
    state = CoverState(photo: bytes);
    try {
      await store.remove(_kLegacyArt);
    } catch (_) {}
  }

  /// Abre la galería y guarda la foto elegida (reducida para que pese poco). Devuelve false si
  /// el usuario cancela o la foto no se pudo leer.
  Future<bool> pickFromGallery() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1080, imageQuality: 78);
    if (file == null) return false;
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) return false;
    await ref.read(localStoreProvider).write(_kPhoto, base64Encode(bytes));
    state = CoverState(photo: bytes);
    return true;
  }

  /// Descarta la foto y vuelve a la portada automática.
  Future<void> removePhoto() async {
    await ref.read(localStoreProvider).remove(_kPhoto);
    state = const CoverState();
  }
}

final coverProvider = NotifierProvider<CoverController, CoverState>(CoverController.new);
