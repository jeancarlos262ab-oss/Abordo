class ShiftUnit {
  const ShiftUnit({required this.id, required this.label, required this.route, required this.fareCents});

  factory ShiftUnit.fromJson(Map<String, dynamic> j) =>
      ShiftUnit(id: j['id'] as int, label: j['label'] as String, route: j['route'] as String, fareCents: j['fareCents'] as int);

  final int id;
  final String label;
  final String route;
  final int fareCents;
}

class ShiftPayment {
  const ShiftPayment({required this.seq, required this.id, required this.amountCents, required this.paidAt});

  factory ShiftPayment.fromJson(Map<String, dynamic> j) => ShiftPayment(
        seq: j['seq'] as int,
        id: j['id'] as String,
        amountCents: j['amountCents'] as int,
        paidAt: j['paidAt'] as String,
      );

  final int seq;
  final String id;
  final int amountCents;
  final String paidAt;
}

/// Pagos nuevos desde el último consecutivo conocido.
class PaymentsBatch {
  const PaymentsBatch({required this.payments, required this.latestSeq});

  factory PaymentsBatch.fromJson(Map<String, dynamic> j) => PaymentsBatch(
        payments: [for (final p in j['payments'] as List) ShiftPayment.fromJson(p as Map<String, dynamic>)],
        latestSeq: j['latestSeq'] as int,
      );

  final List<ShiftPayment> payments;
  final int latestSeq;
}

/// Estado del turno del chofer. Sin turno abierto, `unit` es null.
class ShiftState {
  const ShiftState({this.unit, this.startedAt, this.count = 0, this.amountCents = 0, this.recent = const [], this.latestSeq = 0});

  factory ShiftState.fromJson(Map<String, dynamic> j) {
    final shift = j['shift'] as Map<String, dynamic>?;
    final totals = j['totals'] as Map<String, dynamic>;
    return ShiftState(
      unit: shift == null ? null : ShiftUnit.fromJson(shift['unit'] as Map<String, dynamic>),
      startedAt: shift?['startedAt'] as String?,
      count: totals['count'] as int,
      amountCents: totals['amountCents'] as int,
      recent: [for (final p in (j['recent'] as List)) ShiftPayment.fromJson(p as Map<String, dynamic>)],
      latestSeq: (j['latestSeq'] as int?) ?? 0,
    );
  }

  static const none = ShiftState();

  final ShiftUnit? unit;
  final String? startedAt;
  final int count;
  final int amountCents;
  final List<ShiftPayment> recent; // del más nuevo al más viejo
  final int latestSeq;

  bool get isActive => unit != null;

  ShiftState withBatch(PaymentsBatch batch) => ShiftState(
        unit: unit,
        startedAt: startedAt,
        count: count + batch.payments.length,
        amountCents: amountCents + batch.payments.fold<int>(0, (s, p) => s + p.amountCents),
        recent: [...batch.payments.reversed, ...recent].take(8).toList(),
        latestSeq: batch.latestSeq,
      );
}
