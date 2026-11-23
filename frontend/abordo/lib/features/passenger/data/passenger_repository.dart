import '../../../core/network/api_client.dart';
import '../domain/passenger_models.dart';

class PassengerRepository {
  const PassengerRepository(this._api);
  final ApiClient _api;

  Future<UnitInfo> unit(String code) async => UnitInfo.fromJson(await _api.get('/public/units/$code'));

  Future<Charge> createCharge(String code, {String? payerPhone}) async => Charge.fromJson(
        await _api.post('/public/units/$code/charges', body: {if (payerPhone != null && payerPhone.isNotEmpty) 'payerPhone': payerPhone}),
      );

  Future<Charge> charge(String id) async => Charge.fromJson(await _api.get('/public/charges/$id'));
}
