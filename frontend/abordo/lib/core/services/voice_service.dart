import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../providers.dart';

/// Voz en español de México. Se usa para el aviso "Pagó 12 pesos" del chofer
/// y para confirmar el pago al pasajero (útil para quien ve poco).
class VoiceService {
  VoiceService(this._isEnabled);

  final bool Function() _isEnabled;
  final FlutterTts _tts = FlutterTts();
  bool _ready = false;

  Future<void> _init() async {
    await _tts.setLanguage('es-MX');
    await _tts.setSpeechRate(.5);
    await _tts.setVolume(1);
    _ready = true;
  }

  Future<void> say(String text) async {
    if (!_isEnabled()) return;
    try {
      if (!_ready) await _init();
      await _tts.stop();
      await _tts.speak(text);
    } catch (_) {
      // Sin voz disponible en el equipo: la app sigue funcionando con vibración y pantalla.
    }
  }

  Future<void> stop() => _tts.stop();
}

class VoiceEnabledController extends Notifier<bool> {
  static const _key = 'pref.voice';

  @override
  bool build() {
    _load();
    return true; // encendida por defecto
  }

  Future<void> _load() async {
    final saved = await ref.read(localStoreProvider).read(_key);
    if (saved == '0') state = false;
  }

  Future<void> set(bool value) async {
    state = value;
    await ref.read(localStoreProvider).write(_key, value ? '1' : '0');
  }
}

final voiceEnabledProvider = NotifierProvider<VoiceEnabledController, bool>(VoiceEnabledController.new);

final voiceServiceProvider = Provider<VoiceService>((ref) {
  final service = VoiceService(() => ref.read(voiceEnabledProvider));
  ref.onDispose(service.stop);
  return service;
});
