import '../../../core/network/api_client.dart';
import '../domain/passenger_models.dart';

class PassengerRepository {
  const PassengerRepository(this._api);
  final ApiClient _api;

  Future<UnitInfo> unit(String code) async => UnitInfo.fromJson(await _api.get('/public/units/$code'));

  Future<Charge> createCharge(String code, {String? payerPhone}) async => Charge.fromJson(
        await _api.post('/public/units/$code/charges', body: {if (payerPhone != null && payerPhone.isNotEmpty) 'payerPhone': payerPhone}),
      );

  // Cuenta del pasajero con sesión.
  Future<PassengerProfile> profile() async => PassengerProfile.fromJson(await _api.get('/passenger/me'));

  Future<void> linkAccount({required String holder, required String phone, required String bank}) =>
      _api.put('/passenger/account', body: {'holder': holder, 'phone': phone, 'bank': bank});

  Future<void> unlinkAccount() => _api.delete('/passenger/account');

  Future<PaymentHistory> payments() async => PaymentHistory.fromJson(await _api.get('/passenger/payments', query: {'limit': 100}));

  Future<Charge> charge(String id) async => Charge.fromJson(await _api.get('/public/charges/$id'));
}
