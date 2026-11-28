import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/services/qr_pdf.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/labeled_field.dart';
import '../../../core/widgets/submit_mixin.dart';
import '../domain/owner_models.dart';
import '../state/owner_providers.dart';
import 'owner_widgets.dart';
import 'unit_qr_page.dart';

Future<void> _openForm(BuildContext context, {OwnerUnit? unit}) => showFormSheet<void>(
      context,
      title: unit == null ? 'Nueva unidad' : 'Editar unidad',
      builder: (_) => _UnitForm(unit: unit),
    );

class UnitsTab extends ConsumerWidget {
  const UnitsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => OwnerList<OwnerUnit>(
        value: ref.watch(unitsProvider),
        onRefresh: () async => ref.invalidate(unitsProvider),
        emptyIcon: AppIcons.busOutlined,
        emptyMessage: 'Aún no tienes unidades. Agrega la primera para generar su código QR.',
        addLabel: 'Agregar unidad',
        onAdd: () => _openForm(context),
        header: (ctx, items) {
          final on = items.where((u) => u.active).length;
          final off = items.length - on;
          return OwnerListHeader(
            title: '${items.length} ${items.length == 1 ? 'unidad' : 'unidades'}',
            subtitle: off == 0
                ? (on == 1 ? '1 cobrando ahora' : '$on cobrando ahora')
                : '$on cobrando · $off ${off == 1 ? 'apagada' : 'apagadas'}',
          );
        },
        itemBuilder: (ctx, u) => _UnitCard(unit: u),
      );
}

/// Una unidad como fila abierta: el vehículo con su nombre y ruta, el QR con el número y el precio,
/// y tres acciones rápidas (imprimir, ver QR, editar). Todo directo sobre el fondo.
class _UnitCard extends StatefulWidget {
  const _UnitCard({required this.unit});
  final OwnerUnit unit;

  @override
  State<_UnitCard> createState() => _UnitCardState();
}

class _UnitCardState extends State<_UnitCard> {
  bool _printing = false;

  Future<void> _print() async {
    setState(() => _printing = true);
    try {
      await QrPdf.printOrSave(widget.unit);
    } catch (_) {
      if (mounted) showMessage(context, 'No pudimos preparar el PDF. Intenta de nuevo.', error: true);
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final unit = widget.unit;
    final text = Theme.of(context).textTheme;
    final muted = context.palette.muted;
    return Semantics(
      container: true,
      label: '${unit.label}, ${unit.route}, pasaje de ${Money.spoken(unit.fareCents)}, ${unit.active ? 'cobrando' : 'apagada'}',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      StateTag(label: unit.active ? 'Cobrando' : 'Apagada', on: unit.active),
                      const SizedBox(height: 8),
                      Text(unit.label, style: text.headlineSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(AppIcons.path, size: 15, color: muted),
                          const SizedBox(width: 6),
                          Expanded(child: Text(unit.route, style: text.bodyMedium?.copyWith(color: muted), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Acciones rápidas en la esquina superior derecha, junto al estado.
                Align(
                  alignment: Alignment.topRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      QuickAction(compact: true, icon: AppIcons.printer, label: 'Imprimir', semanticLabel: 'Imprimir QR en PDF', primary: true, loading: _printing, onTap: _print),
                      const SizedBox(width: 8),
                      QuickAction(
                        compact: true,
                        icon: AppIcons.qr,
                        label: 'Ver QR',
                        onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => UnitQrPage(unit: unit))),
                      ),
                      const SizedBox(width: 8),
                      QuickAction(compact: true, icon: AppIcons.pencil, label: 'Editar', onTap: () => _openForm(context, unit: unit)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // El QR sí lleva fondo blanco: es lo que permite que la cámara lo lea.
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: Colors.white), // cuadrado, sin esquinas redondeadas
                  child: ExcludeSemantics(child: QrImageView(data: unit.qrContent, size: 84, backgroundColor: Colors.white, padding: EdgeInsets.zero)),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('PASAJE', style: text.labelSmall?.copyWith(color: muted)),
                      Text(Money.format(unit.fareCents), style: tabular(text.headlineMedium)),
                      const SizedBox(height: 8),
                      Text('NÚMERO DE LA UNIDAD', style: text.labelSmall?.copyWith(color: muted)),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(unit.spacedCode, style: tabular(text.titleLarge?.copyWith(fontSize: 20, letterSpacing: 2.5))),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('Los pasajeros escanean el QR o escriben este número para pagar.', style: text.bodySmall?.copyWith(color: muted)),
          ],
        ),
      ),
    );
  }
}

class _UnitForm extends ConsumerStatefulWidget {
  const _UnitForm({this.unit});
  final OwnerUnit? unit;

  @override
  ConsumerState<_UnitForm> createState() => _UnitFormState();
}

class _UnitFormState extends ConsumerState<_UnitForm> with SubmitMixin<_UnitForm> {
  late final _label = TextEditingController(text: widget.unit?.label);
  late final _route = TextEditingController(text: widget.unit?.route);
  late final _fare = TextEditingController(text: widget.unit == null ? '12' : (widget.unit!.fareCents / 100).toStringAsFixed(widget.unit!.fareCents % 100 == 0 ? 0 : 2));
  late bool _active = widget.unit?.active ?? true;

  @override
  void dispose() {
    _label.dispose();
    _route.dispose();
    _fare.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final repo = ref.read(ownerRepositoryProvider);
    final fare = Money.parseToCents(_fare.text)!;
    final ok = await submit(() async {
      final u = widget.unit;
      if (u == null) {
        await repo.createUnit(label: _label.text.trim(), route: _route.text.trim(), fareCents: fare);
      } else {
        await repo.updateUnit(u.id, label: _label.text.trim(), route: _route.text.trim(), fareCents: fare, active: _active);
      }
    });
    if (ok && mounted) {
      ref.invalidate(unitsProvider);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LabeledField(label: 'Nombre de la unidad', hint: 'Unidad 14', icon: AppIcons.bus, controller: _label, validator: Validators.notEmpty('el nombre')),
          LabeledField(label: 'Ruta', hint: 'Ruta 52', icon: AppIcons.path, controller: _route, validator: Validators.notEmpty('la ruta')),
          LabeledField(
            label: 'Precio del pasaje (pesos)',
            icon: AppIcons.dollar,
            controller: _fare,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.done,
            validator: Validators.money('El precio'),
          ),
          if (widget.unit != null) ...[
            AppCard(
              shadow: false,
              onTap: () => setState(() => _active = !_active),
              padding: const EdgeInsets.fromLTRB(18, 12, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Cobrando con CoDi', style: Theme.of(context).textTheme.titleMedium),
                        Text('Apágala si la unidad no está en servicio.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.palette.muted)),
                      ],
                    ),
                  ),
                  ExcludeSemantics(child: Switch(value: _active, onChanged: (v) => setState(() => _active = v))),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          const SizedBox(height: 8),
          AppButton(label: 'Guardar', icon: AppIcons.check, loading: busy, onPressed: _save),
        ],
      ),
    );
  }
}
