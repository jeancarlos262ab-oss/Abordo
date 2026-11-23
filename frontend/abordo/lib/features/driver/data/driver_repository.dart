import '../../../core/network/api_client.dart';
import '../domain/driver_models.dart';

class DriverRepository {
  const DriverRepository(this._api);
  final ApiClient _api;

  Future<List<ShiftUnit>> units() async =>
      [for (final u in (await _api.get('/driver/units'))['units'] as List) ShiftUnit.fromJson(u as Map<String, dynamic>)];

  Future<ShiftState> current() async => ShiftState.fromJson(await _api.get('/driver/shift'));
  Future<ShiftState> start(int unitId) async => ShiftState.fromJson(await _api.post('/driver/shift', body: {'unitId': unitId}));

  /// Cierra el turno y regresa el resumen final.
  Future<ShiftState> end() async => ShiftState.fromJson(await _api.delete('/driver/shift'));

  Future<PaymentsBatch> newPayments(int afterSeq) async =>
      PaymentsBatch.fromJson(await _api.get('/driver/shift/payments', query: {'afterSeq': afterSeq}));
}
