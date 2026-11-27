import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/services/voice_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/route_map.dart';
import '../../../core/utils/route_path.dart';
import '../../../core/widgets/ticket_card.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/pulse_dot.dart';
import '../../../core/widgets/scan_frame.dart';
import '../../../core/widgets/success_badge.dart';
import '../../../core/widgets/page_scaffold.dart';
import '../../../core/widgets/state_views.dart';
import '../domain/passenger_models.dart';
import '../state/passenger_providers.dart';
import '../../../core/theme/app_icons.dart';

/// Paso 3: pagar y esperar la confirmación. La pantalla se actualiza sola.
class PayPage extends ConsumerWidget {
  const PayPage({super.key, required this.initial});
  final Charge initial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(chargeStatusProvider(initial.id));

    ref.listen<AsyncValue<Charge>>(chargeStatusProvider(initial.id), (prev, next) {
      final paid = next.valueOrNull?.status == ChargeStatus.paid;
      if (paid && prev?.valueOrNull?.status != ChargeStatus.paid) {
        HapticFeedback.heavyImpact();
        ref.read(voiceServiceProvider).say('Pago confirmado. Pagaste ${Money.spoken(initial.amountCents)}. Ya puedes subir.');
      }
    });

    final charge = status.valueOrNull ?? initial;
    final text = Theme.of(context).textTheme;
    final paid = charge.status == ChargeStatus.paid;
    return PopScope(
      canPop: !paid, // ya pagó: solo se sale con "Terminar"
      child: PageScaffold(
        overlap: false,
        title: 'Pagar mi pasaje',
        showBack: !paid,
        hero: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(paid ? 'Pago recibido' : 'Total a pagar', style: text.bodyLarge?.copyWith(color: AppColors.graphite)),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(Money.format(charge.amountCents), style: text.displayMedium?.copyWith(color: AppColors.ink)),
            ),
            const SizedBox(height: 2),
            Text('${charge.unitLabel} · ${charge.route}', style: text.bodyLarge?.copyWith(color: AppColors.graphite)),
          ],
        ),
        child: status.hasError && status.valueOrNull == null
            ? MessageView(
                icon: AppIcons.wifiSlash,
                message: '${friendlyError(status.error!)}\nSi ya pagaste, tu banco guarda el comprobante.',
                onAction: () => ref.invalidate(chargeStatusProvider(initial.id)),
              )
            : switch (charge.status) {
                ChargeStatus.pending => _Pending(charge: charge),
                ChargeStatus.paid => _Paid(charge: charge),
                ChargeStatus.expired || ChargeStatus.failed => _Failed(charge: charge),
              },
      ),
    );
  }
}

class _Pending extends StatelessWidget {
  const _Pending({required this.charge});
  final Charge charge;

  Future<void> _openBank(BuildContext context) async {
    final ok = await launchUrl(Uri.parse(charge.paymentLink!), mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) showMessage(context, 'No pudimos abrir tu banco. Escanea el código con tu app.', error: true);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (charge.paymentLink != null) ...[
          AppButton(label: 'Abrir mi app del banco', icon: AppIcons.bank, onPressed: () => _openBank(context)),
          const SizedBox(height: 16),
        ],
        if (charge.qrPayload != null) ...[
          TicketCard(
            top: Column(
              children: [
                Text(
                  charge.paymentLink != null ? 'O escanea este código con otro celular' : 'Escanea este código con la app de tu banco',
                  textAlign: TextAlign.center,
                  style: text.titleMedium,
                ),
                const SizedBox(height: 14),
                Semantics(
                  label: 'Código QR de cobro CoDi por ${Money.spoken(charge.amountCents)}',
                  child: ScanFrame(
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(Dimens.rMd)),
                      child: QrImageView(data: charge.qrPayload!, size: 190, backgroundColor: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            bottom: Row(
              children: [
                Expanded(child: Text('Total a pagar', style: text.bodyLarge?.copyWith(color: context.palette.muted))),
                Text(Money.format(charge.amountCents), style: tabular(text.headlineSmall)),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        const _WaitingBanner(),
        const SizedBox(height: 16),
        _RouteCard(charge: charge),
        const SizedBox(height: 12),
        Center(child: _Countdown(expiresAt: charge.expiresAt)),
        const SizedBox(height: 20),
        AppButton(label: 'Cancelar', kind: ButtonKind.secondary, onPressed: () => Navigator.of(context).pop()),
      ],
    );
  }
}

/// Mapa con el camino por donde va la ruta que el pasajero está pagando.
class _RouteCard extends StatelessWidget {
  const _RouteCard({required this.charge});
  final Charge charge;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      label: 'Mapa del camino de la ruta ${charge.route}',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Dimens.rXl),
        child: DecoratedBox(
          decoration: BoxDecoration(border: Border.all(color: p.border), borderRadius: BorderRadius.circular(Dimens.rXl)),
          child: RouteMap(path: charge.routePath ?? RoutePath.demo, height: 300, caption: charge.route.isEmpty ? null : charge.route),
        ),
      ),
    );
  }
}

class _WaitingBanner extends StatelessWidget {
  const _WaitingBanner();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    return Semantics(
      liveRegion: true,
      label: 'Esperando tu pago',
      child: AppCard(
        color: p.accentSoft,
        shadow: false,
        radius: Dimens.rXl,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            PulseDot(color: p.accent),
            const SizedBox(width: 10),
            Expanded(child: Text('Esperando tu pago. No cierres esta pantalla.', style: text.titleMedium)),
          ],
        ),
      ),
    );
  }
}

/// Cuenta regresiva simple. Su propio State evita redibujar toda la pantalla cada segundo.
class _Countdown extends StatefulWidget {
  const _Countdown({required this.expiresAt});
  final DateTime expiresAt;

  @override
  State<_Countdown> createState() => _CountdownState();
}

class _CountdownState extends State<_Countdown> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final left = widget.expiresAt.difference(DateTime.now());
    final secs = left.isNegative ? 0 : left.inSeconds;
    final label = '${secs ~/ 60}:${(secs % 60).toString().padLeft(2, '0')}';
    final p = context.palette;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(AppIcons.timer, size: 20, color: p.muted),
        const SizedBox(width: 8),
        Text('Tienes $label minutos para pagar.', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: p.muted)),
      ],
    );
  }
}

class _Paid extends StatelessWidget {
  const _Paid({required this.charge});
  final Charge charge;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    return Semantics(
      liveRegion: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: SuccessBadge(size: 88)),
          Text('¡Listo!', style: text.displaySmall, textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text('Pagaste ${Money.format(charge.amountCents)}. Ya puedes subir.', style: text.titleMedium?.copyWith(color: p.muted), textAlign: TextAlign.center),
          const SizedBox(height: 22),
          TicketCard(
            strip: Row(
              children: [
                Expanded(child: Text(charge.unitLabel, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800), overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 10),
                Text(Money.format(charge.amountCents), style: tabular(text.titleMedium?.copyWith(fontWeight: FontWeight.w800))),
              ],
            ),
            top: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(charge.unitLabel, style: text.titleLarge),
                Text(charge.route, style: text.bodyMedium?.copyWith(color: p.muted)),
              ],
            ),
            bottom: Row(
              children: [
                Expanded(child: Text('Total pagado', style: text.bodyLarge?.copyWith(color: p.muted))),
                Text(Money.format(charge.amountCents), style: tabular(text.headlineSmall)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _RouteCard(charge: charge),
          const SizedBox(height: 28),
          AppButton(label: 'Terminar', icon: AppIcons.check, onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst)),
        ],
      ),
    );
  }
}

class _Failed extends StatelessWidget {
  const _Failed({required this.charge});
  final Charge charge;

  @override
  Widget build(BuildContext context) {
    final expired = charge.status == ChargeStatus.expired;
    return MessageView(
      icon: expired ? AppIcons.timer : AppIcons.warningCircle,
      message: expired ? 'Se acabó el tiempo para pagar. No se cobró nada.' : 'El pago no se pudo completar. No se cobró nada.',
      actionLabel: 'Intentar otra vez',
      onAction: () => Navigator.of(context).pop(),
    );
  }
}
