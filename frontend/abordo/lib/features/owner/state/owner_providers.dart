import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/providers.dart';
import '../../../core/utils/dates.dart';
import '../../../core/utils/polling.dart';
import '../data/owner_repository.dart';
import '../domain/owner_models.dart';

final ownerRepositoryProvider = Provider<OwnerRepository>((ref) => OwnerRepository(ref.watch(apiClientProvider)));

final settingsProvider = FutureProvider.autoDispose<OwnerSettings>((ref) => ref.watch(ownerRepositoryProvider).settings());
final unitsProvider = FutureProvider.autoDispose<List<OwnerUnit>>((ref) => ref.watch(ownerRepositoryProvider).units());
final driversProvider = FutureProvider.autoDispose<List<DriverItem>>((ref) => ref.watch(ownerRepositoryProvider).drivers());

/// Día que se está viendo en "Hoy" (clave AAAA-MM-DD en hora de México).
final selectedDayProvider = StateProvider.autoDispose<String>((_) => AppDates.todayKey());

/// Cuadre del día. Si es hoy se refresca solo cada 10 s ("panel en vivo"); un día pasado se consulta una vez.
final summaryProvider = StreamProvider.autoDispose<DaySummary>((ref) {
  final repo = ref.watch(ownerRepositoryProvider);
  final day = ref.watch(selectedDayProvider);
  return poll(AppConfig.ownerPanelPoll, () => repo.summary(day), until: (_) => day != AppDates.todayKey());
});

final historyProvider = FutureProvider.autoDispose.family<History, String>((ref, day) => ref.watch(ownerRepositoryProvider).history(day));
