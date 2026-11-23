import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/providers.dart';
import '../../../core/services/voice_service.dart';
import '../../../core/utils/money.dart';
import '../data/driver_repository.dart';
import '../domain/driver_models.dart';

final driverRepositoryProvider = Provider<DriverRepository>((ref) => DriverRepository(ref.watch(apiClientProvider)));

final driverUnitsProvider = FutureProvider.autoDispose<List<ShiftUnit>>((ref) => ref.watch(driverRepositoryProvider).units());

final shiftProvider = AsyncNotifierProvider.autoDispose<ShiftController, ShiftState>(ShiftController.new);

/// Turno del chofer. Mientras hay un turno abierto consulta cada 3 s los pagos nuevos,
/// los suma al total y los anuncia con voz y vibración (el chofer no mira la pantalla).
class ShiftController extends AutoDisposeAsyncNotifier<ShiftState> {
  Timer? _timer;
  bool _polling = false;

  DriverRepository get _repo => ref.read(driverRepositoryProvider);

  @override
  Future<ShiftState> build() async {
    ref.onDispose(() => _timer?.cancel());
    final shift = await _repo.current();
    _syncTimer(shift);
    return shift;
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(_repo.current);
    final shift = state.valueOrNull;
    if (shift != null) _syncTimer(shift);
  }

  Future<void> start(int unitId) async {
    final shift = await _repo.start(unitId);
    state = AsyncData(shift);
    _syncTimer(shift);
  }

  /// Cierra el turno y devuelve el resumen para mostrárselo al chofer.
  Future<ShiftState> end() async {
    final summary = await _repo.end();
    state = const AsyncData(ShiftState.none);
    _syncTimer(ShiftState.none);
    return summary;
  }

  void _syncTimer(ShiftState shift) {
    _timer?.cancel();
    _timer = shift.isActive ? Timer.periodic(AppConfig.driverPaymentsPoll, (_) => _poll()) : null;
  }

  Future<void> _poll() async {
    final current = state.valueOrNull;
    if (_polling || current == null || !current.isActive) return;
    _polling = true;
    try {
      final batch = await _repo.newPayments(current.latestSeq);
      final latest = state.valueOrNull;
      if (batch.payments.isEmpty || latest == null || !latest.isActive) return;
      state = AsyncData(latest.withBatch(batch));
      _announce(batch.payments);
    } on ApiException {
      // Sin señal un momento: el siguiente intento recupera los pagos pendientes con el consecutivo.
    } finally {
      _polling = false;
    }
  }

  void _announce(List<ShiftPayment> payments) {
    unawaited(HapticFeedback.vibrate());
    final total = payments.fold<int>(0, (s, p) => s + p.amountCents);
    final phrase = payments.length == 1
        ? 'Pagó ${Money.spoken(total)}'
        : 'Pagaron ${payments.length} pasajeros, ${Money.spoken(total)}';
    unawaited(ref.read(voiceServiceProvider).say(phrase));
  }
}
