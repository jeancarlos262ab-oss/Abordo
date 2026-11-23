class OwnerSettings {
  const OwnerSettings({required this.businessName, required this.clabe, required this.peyConfigured, required this.peyKeyHint});

  factory OwnerSettings.fromJson(Map<String, dynamic> j) => OwnerSettings(
        businessName: j['businessName'] as String,
        clabe: j['clabe'] as String,
        peyConfigured: j['peyConfigured'] as bool,
        peyKeyHint: j['peyKeyHint'] as String,
      );

  final String businessName;
  final String clabe;
  final bool peyConfigured;
  final String peyKeyHint;

  /// Pasos pendientes para poder cobrar, en palabras sencillas.
  List<String> get missing => [if (clabe.isEmpty) 'Tu cuenta CLABE', if (!peyConfigured) 'Tus llaves de pey'];
  bool get ready => missing.isEmpty;
}

class OwnerUnit {
  const OwnerUnit({
    required this.id,
    required this.code,
    required this.label,
    required this.route,
    required this.fareCents,
    required this.active,
    required this.qrContent,
  });

  factory OwnerUnit.fromJson(Map<String, dynamic> j) => OwnerUnit(
        id: j['id'] as int,
        code: j['code'] as String,
        label: j['label'] as String,
        route: j['route'] as String,
        fareCents: j['fareCents'] as int,
        active: j['active'] as bool,
        qrContent: j['qrContent'] as String,
      );

  final int id;
  final String code;
  final String label;
  final String route;
  final int fareCents;
  final bool active;
  final String qrContent;

  /// "123456" -> "123 456", más fácil de leer y de teclear.
  String get spacedCode => code.length == 6 ? '${code.substring(0, 3)} ${code.substring(3)}' : code;
}

class DriverItem {
  const DriverItem({required this.id, required this.name, required this.login, required this.active});

  factory DriverItem.fromJson(Map<String, dynamic> j) =>
      DriverItem(id: j['id'] as int, name: j['name'] as String, login: j['login'] as String, active: j['active'] as bool);

  final int id;
  final String name;
  final String login;
  final bool active;
}

class Ranked {
  const Ranked({required this.name, required this.totalCents, required this.count});

  factory Ranked.fromJson(Map<String, dynamic> j) =>
      Ranked(name: j['name'] as String, totalCents: j['totalCents'] as int, count: j['count'] as int);

  final String name;
  final int totalCents;
  final int count;
}

class DaySummary {
  const DaySummary({required this.date, required this.totalCents, required this.count, required this.hourly, required this.byDriver, required this.byUnit});

  factory DaySummary.fromJson(Map<String, dynamic> j) => DaySummary(
        date: j['date'] as String,
        totalCents: j['totalCents'] as int,
        count: j['count'] as int,
        hourly: [for (final h in j['hourly'] as List) (h as Map<String, dynamic>)['totalCents'] as int],
        byDriver: [for (final r in j['byDriver'] as List) Ranked.fromJson(r as Map<String, dynamic>)],
        byUnit: [for (final r in j['byUnit'] as List) Ranked.fromJson(r as Map<String, dynamic>)],
      );

  final String date;
  final int totalCents;
  final int count;
  final List<int> hourly; // 24 valores, uno por hora (hora de México)
  final List<Ranked> byDriver;
  final List<Ranked> byUnit;

  /// Acumulado hora por hora, para la gráfica de línea.
  List<double> get cumulative {
    var acc = 0;
    return [for (final v in hourly) (acc += v).toDouble()];
  }
}

class HistoryItem {
  const HistoryItem({required this.id, required this.amountCents, required this.paidAt, required this.unitLabel, required this.driverName});

  factory HistoryItem.fromJson(Map<String, dynamic> j) => HistoryItem(
        id: j['id'] as String,
        amountCents: j['amountCents'] as int,
        paidAt: j['paidAt'] as String,
        unitLabel: j['unitLabel'] as String,
        driverName: j['driverName'] as String,
      );

  final String id;
  final int amountCents;
  final String paidAt;
  final String unitLabel;
  final String driverName;
}

class History {
  const History({required this.total, required this.items});

  factory History.fromJson(Map<String, dynamic> j) =>
      History(total: j['total'] as int, items: [for (final i in j['items'] as List) HistoryItem.fromJson(i as Map<String, dynamic>)]);

  final int total;
  final List<HistoryItem> items;
}
