class UnitInfo {
  const UnitInfo({required this.code, required this.label, required this.route, required this.fareCents, required this.acceptsPayments});

  factory UnitInfo.fromJson(Map<String, dynamic> j) => UnitInfo(
        code: j['code'] as String,
        label: j['label'] as String,
        route: j['route'] as String,
        fareCents: j['fareCents'] as int,
        acceptsPayments: j['acceptsPayments'] as bool,
      );

  final String code;
  final String label;
  final String route;
  final int fareCents;
  final bool acceptsPayments;
}

enum ChargeStatus {
  pending,
  paid,
  failed,
  expired;

  static ChargeStatus parse(String s) => ChargeStatus.values.firstWhere((v) => v.name == s, orElse: () => ChargeStatus.pending);
}

class Charge {
  const Charge({
    required this.id,
    required this.status,
    required this.amountCents,
    required this.unitLabel,
    required this.route,
    required this.expiresAt,
    this.qrPayload,
    this.paymentLink,
  });

  factory Charge.fromJson(Map<String, dynamic> j) => Charge(
        id: j['id'] as String,
        status: ChargeStatus.parse(j['status'] as String),
        amountCents: j['amountCents'] as int,
        unitLabel: (j['unitLabel'] as String?) ?? '',
        route: (j['route'] as String?) ?? '',
        expiresAt: DateTime.parse(j['expiresAt'] as String),
        qrPayload: j['qrPayload'] as String?,
        paymentLink: j['paymentLink'] as String?,
      );

  final String id;
  final ChargeStatus status;
  final int amountCents;
  final String unitLabel;
  final String route;
  final DateTime expiresAt;
  final String? qrPayload;
  final String? paymentLink;

  bool get isFinal => status != ChargeStatus.pending;
}
