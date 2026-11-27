import '../../../core/utils/route_path.dart';

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
    this.routePath,
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
        routePath: RoutePath.fromJson(j['routePath']),
      );

  final String id;
  final ChargeStatus status;
  final int amountCents;
  final String unitLabel;
  final String route;
  final DateTime expiresAt;
  final String? qrPayload;
  final String? paymentLink;

  /// Trazo de la ruta (si el servidor lo manda); si no, el mapa usa un recorrido de ejemplo.
  final RoutePath? routePath;

  bool get isFinal => status != ChargeStatus.pending;
}


/// Cuenta que el pasajero vinculó para pagar: el celular registrado en su banco para CoDi.
class LinkedAccount {
  const LinkedAccount({required this.holder, required this.phone, required this.bank});

  factory LinkedAccount.fromJson(Map<String, dynamic> j) => LinkedAccount(
        holder: (j['holder'] as String?) ?? '',
        phone: (j['phone'] as String?) ?? '',
        bank: (j['bank'] as String?) ?? '',
      );

  final String holder;

  /// Celular a 10 dígitos (el servidor puede mandarlo enmascarado: `••••••1234`).
  final String phone;
  final String bank;

  String get phoneHint => phone.length >= 4 ? '••••••${phone.substring(phone.length - 4)}' : phone;
}

/// Perfil del pasajero con sesión.
class PassengerProfile {
  const PassengerProfile({required this.name, required this.login, this.account});

  factory PassengerProfile.fromJson(Map<String, dynamic> j) => PassengerProfile(
        name: j['name'] as String,
        login: j['login'] as String,
        account: j['account'] == null ? null : LinkedAccount.fromJson(j['account'] as Map<String, dynamic>),
      );

  final String name;
  final String login;
  final LinkedAccount? account;

  bool get linked => account != null;
}

/// Un pago del historial del pasajero.
class PaymentItem {
  const PaymentItem({required this.id, required this.status, required this.amountCents, required this.unitLabel, required this.route, required this.createdAt});

  factory PaymentItem.fromJson(Map<String, dynamic> j) => PaymentItem(
        id: j['id'] as String,
        status: ChargeStatus.parse(j['status'] as String),
        amountCents: j['amountCents'] as int,
        unitLabel: (j['unitLabel'] as String?) ?? '',
        route: (j['route'] as String?) ?? '',
        createdAt: j['createdAt'] as String,
      );

  final String id;
  final ChargeStatus status;
  final int amountCents;
  final String unitLabel;
  final String route;

  /// Fecha ISO en UTC.
  final String createdAt;
}

/// Historial: los pagos más recientes y el total gastado en lo que va del mes.
class PaymentHistory {
  const PaymentHistory({required this.items, required this.monthCents});

  factory PaymentHistory.fromJson(Map<String, dynamic> j) => PaymentHistory(
        items: [for (final e in (j['payments'] as List? ?? const [])) PaymentItem.fromJson(e as Map<String, dynamic>)],
        monthCents: (j['monthCents'] as int?) ?? 0,
      );

  final List<PaymentItem> items;
  final int monthCents;
}
