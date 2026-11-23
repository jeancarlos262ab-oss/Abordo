import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/providers.dart';
import '../../../core/utils/polling.dart';
import '../data/passenger_repository.dart';
import '../domain/passenger_models.dart';

final passengerRepositoryProvider = Provider<PassengerRepository>((ref) => PassengerRepository(ref.watch(apiClientProvider)));

final unitProvider = FutureProvider.autoDispose.family<UnitInfo, String>(
  (ref, code) => ref.watch(passengerRepositoryProvider).unit(code),
);

/// Consulta el cobro cada 2 s hasta que se pague, falle o venza.
final chargeStatusProvider = StreamProvider.autoDispose.family<Charge, String>((ref, id) {
  final repo = ref.watch(passengerRepositoryProvider);
  return poll(AppConfig.payStatusPoll, () => repo.charge(id), until: (c) => c.isFinal);
});
