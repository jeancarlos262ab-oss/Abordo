import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/dates.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/motion.dart';
import '../../../core/widgets/route_map.dart';
import '../../../core/widgets/state_views.dart';
import '../../auth/state/session_controller.dart';
import '../../owner/ui/owner_widgets.dart';
import '../domain/passenger_models.dart';
import '../state/passenger_providers.dart';
import 'passenger_account_tab.dart';
import 'unit_entry_page.dart';

class _Tab {
  const _Tab(this.title, this.icon, this.selectedIcon);
  final String title;
  final IconData icon;
  final IconData selectedIcon;
}

const _tabs = [
  _Tab('Pagar', AppIcons.scan, AppIcons.scan),
  _Tab('Historial', AppIcons.receiptOutlined, AppIcons.receipt),
  _Tab('Cuenta', AppIcons.user, AppIcons.user),
];

/// Estructura del pasajero con sesión: igual que la del dueño (título arriba y barra flotante
/// oscura abajo con la pestaña activa en una píldora rosa). Pagar, Historial y Cuenta.
class PassengerShell extends StatefulWidget {
  const PassengerShell({super.key});

  @override
  State<PassengerShell> createState() => _PassengerShellState();
}

class _PassengerShellState extends State<PassengerShell> {
  int _index = 0;

  Widget _body() => switch (_index) {
        0 => _PayTab(onAccount: () => setState(() => _index = 2)),
        1 => _HistoryTab(onPay: () => setState(() => _index = 0)),
        _ => const PassengerAccountTab(),
      };

  @override
  Widget build(BuildContext context) {
    final tab = _tabs[_index];
    final text = Theme.of(context).textTheme;
    final fade = reduceMotion(context) ? Duration.zero : const Duration(milliseconds: 220);

    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: (context.isDarkTheme ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark).copyWith(statusBarColor: Colors.transparent),
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 48,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: Dimens.maxContentWidth),
                    child: Padding(
                      padding: EdgeInsets.only(left: Navigator.of(context).canPop() ? 4 : Dimens.pagePadding, right: 8),
                      child: Row(
                        children: [
                          if (Navigator.of(context).canPop())
                            IconButton(
                              tooltip: 'Regresar',
                              onPressed: () => Navigator.of(context).maybePop(),
                              style: IconButton.styleFrom(backgroundColor: Colors.transparent, foregroundColor: AppColors.ink, fixedSize: const Size.square(48)),
                              icon: const Icon(AppIcons.back, size: 24),
                            ),
                          Expanded(
                            child: Semantics(
                              header: true,
                              child: Text(tab.title, style: text.headlineMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: Dimens.maxContentWidth),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: AnimatedSwitcher(duration: fade, child: KeyedSubtree(key: ValueKey(_index), child: _body())),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Dimens.pagePadding, 6, Dimens.pagePadding, 12),
          child: Align(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: Dimens.maxContentWidth - 2 * Dimens.pagePadding),
              child: Container(
                height: 66,
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(color: context.panelColor, borderRadius: BorderRadius.circular(99)),
                child: LayoutBuilder(
                  builder: (context, c) {
                    final selected = c.maxWidth * .42;
                    final other = (c.maxWidth - selected) / (_tabs.length - 1);
                    return Row(
                      children: [
                        for (var i = 0; i < _tabs.length; i++)
                          _NavItem(
                            tab: _tabs[i],
                            selected: i == _index,
                            width: i == _index ? selected : other,
                            duration: fade,
                            onTap: () => setState(() => _index = i),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.tab, required this.selected, required this.width, required this.duration, required this.onTap});
  final _Tab tab;
  final bool selected;
  final double width;
  final Duration duration;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      selected: selected,
      label: selected ? '${tab.title}, pestaña actual' : tab.title,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: selected
            ? null
            : () {
                HapticFeedback.selectionClick();
                onTap();
              },
        child: AnimatedContainer(
          duration: duration,
          curve: Curves.easeOutCubic,
          width: width,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: selected ? AppColors.rose : Colors.transparent, borderRadius: BorderRadius.circular(99)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(selected ? tab.selectedIcon : tab.icon, size: 24, color: selected ? AppColors.ink : Colors.white.withOpacity(.72)),
              if (selected) ...[
                const SizedBox(width: 7),
                Flexible(
                  child: Text(tab.title, maxLines: 1, softWrap: false, overflow: TextOverflow.clip, style: text.labelLarge?.copyWith(color: AppColors.ink)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────────── Pagar ─────────────────────────────

class _PayTab extends ConsumerWidget {
  const _PayTab({required this.onAccount});
  final VoidCallback onAccount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final muted = context.palette.muted;
    final user = ref.watch(sessionProvider).valueOrNull?.user;
    final profile = ref.watch(passengerProfileProvider).valueOrNull;
    final history = ref.watch(paymentsProvider).valueOrNull;
    final soft = Colors.white.withOpacity(.65);

    return ListView(
      padding: const EdgeInsets.fromLTRB(Dimens.pagePadding, 0, Dimens.pagePadding, 32),
      children: [
        OwnerListHeader(title: 'Hola, ${user?.firstName ?? ''}', subtitle: 'Paga tu pasaje con CoDi, sin efectivo.'),
        const SizedBox(height: 14),
        // Cifra del mes en el panel oscuro (lo más importante, sin tarjetas blancas).
        Container(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
          decoration: BoxDecoration(color: context.panelColor, borderRadius: BorderRadius.circular(Dimens.rXl)),
          child: Semantics(
            container: true,
            label: history == null ? 'Gastado este mes' : 'Gastado este mes: ${Money.spoken(history.monthCents)}',
            child: ExcludeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('GASTADO ESTE MES', style: text.labelSmall?.copyWith(color: soft)),
                  const SizedBox(height: 6),
                  Text(history == null ? '—' : Money.format(history.monthCents), style: tabular(text.displayLarge).copyWith(color: Colors.white, fontSize: 48)),
                  const SizedBox(height: 4),
                  Text(
                    history == null
                        ? 'Cargando…'
                        : '${history.items.where((e) => e.status == ChargeStatus.paid).length} pasajes pagados',
                    style: text.bodyMedium?.copyWith(color: soft),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        InkButton(
          label: 'Pagar mi pasaje',
          icon: AppIcons.scan,
          onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const UnitEntryPage())),
        ),
        const SizedBox(height: 18),
        // Estado de la cuenta vinculada.
        OwnerItemBox(
          child: InkWell(
            onTap: onAccount,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: context.inkAt(.08)),
                    child: Icon(AppIcons.bank, size: 22, color: context.inkColor),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(profile?.linked == true ? 'Cuenta vinculada' : 'Vincula tu cuenta', style: text.titleMedium),
                        Text(
                          profile?.linked == true
                              ? '${profile!.account!.bank} · ${profile.account!.phoneHint}'
                              : 'Así pagas más rápido y guardamos tu historial.',
                          style: text.bodyMedium?.copyWith(color: muted),
                        ),
                      ],
                    ),
                  ),
                  Icon(AppIcons.caretRight, size: 20, color: muted),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Center(
          child: PillButton(
            label: 'Ver rutas que usan CoDi',
            icon: AppIcons.mapPin,
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const RouteMapPage(title: 'Rutas con CoDi'))),
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────── Historial ────────────────────────────

class _HistoryTab extends ConsumerWidget {
  const _HistoryTab({required this.onPay});
  final VoidCallback onPay;

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(paymentsProvider);
    await ref.read(paymentsProvider.future);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    return OwnerAsync<PaymentHistory>(
      value: ref.watch(paymentsProvider),
      onRetry: () => ref.invalidate(paymentsProvider),
      loading: const Padding(padding: EdgeInsets.symmetric(horizontal: Dimens.pagePadding), child: OwnerSkeleton()),
      data: (h) {
        if (h.items.isEmpty) {
          return MessageView(icon: AppIcons.receiptOutlined, message: 'Aún no tienes pagos. Cuando pagues un pasaje aparecerá aquí.', actionLabel: 'Pagar mi pasaje', onAction: onPay);
        }
        return RefreshIndicator(
          color: AppColors.rose,
          backgroundColor: context.panelColor,
          onRefresh: () => _refresh(ref),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(Dimens.pagePadding, 0, Dimens.pagePadding, 32),
            children: [
              OwnerListHeader(title: '${h.items.length} ${h.items.length == 1 ? 'pasaje' : 'pasajes'}', subtitle: 'Este mes llevas ${Money.format(h.monthCents)}.'),
              const SizedBox(height: 10),
              for (var i = 0; i < h.items.length; i++) ...[
                if (i > 0) const SizedBox(height: 12),
                OwnerItemBox(child: _PaymentRow(item: h.items[i], text: text, muted: p.muted)),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({required this.item, required this.text, required this.muted});
  final PaymentItem item;
  final TextTheme text;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (icon, color, label) = switch (item.status) {
      ChargeStatus.paid => (AppIcons.check, p.success, 'Pagado'),
      ChargeStatus.pending => (AppIcons.hourglass, muted, 'Pendiente'),
      ChargeStatus.expired => (AppIcons.timer, p.danger, 'Venció'),
      ChargeStatus.failed => (AppIcons.close, p.danger, 'No se pagó'),
    };
    return Semantics(
      container: true,
      label: '${Money.spoken(item.amountCents)}, ${item.unitLabel}, $label, ${AppDates.dayTime(item.createdAt)}',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: color.withOpacity(.16), shape: BoxShape.circle),
                child: Icon(icon, size: 22, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(Money.format(item.amountCents), style: tabular(text.titleLarge)),
                    Text(item.route.isEmpty ? item.unitLabel : '${item.unitLabel} · ${item.route}', style: text.bodyMedium?.copyWith(color: muted), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(label, style: text.labelMedium?.copyWith(color: color)),
                  Text(AppDates.dayTime(item.createdAt), style: text.labelSmall?.copyWith(color: muted)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
