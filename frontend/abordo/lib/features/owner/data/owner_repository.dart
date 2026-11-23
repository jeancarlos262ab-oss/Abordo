import '../../../core/network/api_client.dart';
import '../domain/owner_models.dart';

class OwnerRepository {
  const OwnerRepository(this._api);
  final ApiClient _api;

  List<T> _list<T>(Json json, String key, T Function(Map<String, dynamic>) parse) =>
      [for (final e in json[key] as List) parse(e as Map<String, dynamic>)];

  // Ajustes
  Future<OwnerSettings> settings() async => OwnerSettings.fromJson(await _api.get('/owner/settings'));

  /// Solo se envían los campos con valor: lo que se deja vacío no se modifica.
  Future<OwnerSettings> saveSettings({String? businessName, String? clabe, String? peyApiKey, String? peyApiSecret}) async {
    String? clean(String? v) => (v == null || v.trim().isEmpty) ? null : v.trim();
    return OwnerSettings.fromJson(
      await _api.put('/owner/settings', body: {
        if (clean(businessName) != null) 'businessName': clean(businessName),
        if (clean(clabe) != null) 'clabe': clean(clabe),
        if (clean(peyApiKey) != null) 'peyApiKey': clean(peyApiKey),
        if (clean(peyApiSecret) != null) 'peyApiSecret': clean(peyApiSecret),
      }),
    );
  }

  // Unidades
  Future<List<OwnerUnit>> units() async => _list(await _api.get('/owner/units'), 'units', OwnerUnit.fromJson);

  Future<void> createUnit({required String label, required String route, required int fareCents}) =>
      _api.post('/owner/units', body: {'label': label, 'route': route, 'fareCents': fareCents});

  Future<void> updateUnit(int id, {String? label, String? route, int? fareCents, bool? active}) => _api.patch('/owner/units/$id', body: {
        if (label != null) 'label': label,
        if (route != null) 'route': route,
        if (fareCents != null) 'fareCents': fareCents,
        if (active != null) 'active': active,
      });

  // Choferes
  Future<List<DriverItem>> drivers() async => _list(await _api.get('/owner/drivers'), 'drivers', DriverItem.fromJson);

  Future<void> createDriver({required String name, required String login, required String pin}) =>
      _api.post('/owner/drivers', body: {'name': name, 'login': login, 'pin': pin});

  Future<void> updateDriver(int id, {String? name, String? pin, bool? active}) => _api.patch('/owner/drivers/$id', body: {
        if (name != null) 'name': name,
        if (pin != null && pin.isNotEmpty) 'pin': pin,
        if (active != null) 'active': active,
      });

  // Reportes
  Future<DaySummary> summary(String date) async => DaySummary.fromJson(await _api.get('/owner/reports/summary', query: {'date': date}));

  Future<History> history(String date) async => History.fromJson(await _api.get('/owner/charges', query: {'date': date, 'limit': 100}));
}
