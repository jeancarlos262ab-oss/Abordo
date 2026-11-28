import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Tarjeta tipo boleto: dos mitades separadas por una línea punteada con muescas semicirculares
/// recortadas de verdad a los lados (se ve el fondo de la pantalla a través de ellas).
class TicketCard extends StatelessWidget {
  const TicketCard({super.key, required this.top, required this.bottom, this.strip, this.details, this.footer});
  final Widget top;
  final Widget bottom;

  /// Franja gris sobre el boleto (como el "origen ⇄ destino" de la referencia).
  final Widget? strip;

  /// Datos extra (ruta, folio, fecha…) que van debajo de [top], separados por una línea fina.
  final Widget? details;

  /// Pie del boleto (p. ej. código de barras) debajo de [bottom].
  final Widget? footer;

  static const _notch = 12.0;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
        children: [
          if (strip != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              decoration: BoxDecoration(color: p.field, borderRadius: BorderRadius.circular(Dimens.rLg)),
              child: strip,
            ),
            const SizedBox(height: 8),
          ],
          ClipPath(
            clipper: const _TicketClipper(top: true),
            child: Container(
              width: double.infinity,
              color: p.card,
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 20 + _notch),
              child: details == null
                  ? top
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        top,
                        const SizedBox(height: 16),
                        Divider(height: 1, color: p.text.withOpacity(.16)),
                        const SizedBox(height: 16),
                        details!,
                      ],
                    ),
            ),
          ),
          ClipPath(
            clipper: const _TicketClipper(top: false),
            child: Container(
              width: double.infinity,
              color: p.card,
              padding: const EdgeInsets.fromLTRB(22, _notch + 18, 22, 22),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: -(_notch + 18),
                    child: SizedBox(height: 2, child: CustomPaint(painter: _DashPainter(p.text.withOpacity(.25)))),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: footer == null
                        ? bottom
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [bottom, const SizedBox(height: 18), footer!],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
    );
  }
}

class _TicketClipper extends CustomClipper<Path> {
  const _TicketClipper({required this.top});
  final bool top;

  @override
  Path getClip(Size size) {
    const r = Dimens.rLg;
    const n = TicketCard._notch;
    final rect = top
        ? RRect.fromRectAndCorners(Offset.zero & size, topLeft: const Radius.circular(r), topRight: const Radius.circular(r))
        : RRect.fromRectAndCorners(Offset.zero & size, bottomLeft: const Radius.circular(r), bottomRight: const Radius.circular(r));
    final shape = Path()..addRRect(rect);
    final y = top ? size.height : 0.0;
    final holes = Path()
      ..addOval(Rect.fromCircle(center: Offset(0, y), radius: n))
      ..addOval(Rect.fromCircle(center: Offset(size.width, y), radius: n));
    return Path.combine(PathOperation.difference, shape, holes);
  }

  @override
  bool shouldReclip(_TicketClipper old) => old.top != top;
}

class _DashPainter extends CustomPainter {
  const _DashPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var x = TicketCard._notch; x < size.width - TicketCard._notch; x += 12) {
      canvas.drawLine(Offset(x, 1), Offset(x + 6, 1), p);
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => old.color != color;
}

/// Un dato del boleto: etiqueta chica arriba y valor abajo (RUTA, FOLIO, FECHA…).
class TicketInfo {
  const TicketInfo(this.label, this.value, {this.icon});
  final String label;
  final String value;
  final IconData? icon;
}

/// Cuadrícula de datos del boleto, en dos columnas.
class TicketInfoGrid extends StatelessWidget {
  const TicketInfoGrid({super.key, required this.items});
  final List<TicketInfo> items;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    Widget cell(TicketInfo i) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (i.icon != null) ...[
              Padding(padding: const EdgeInsets.only(top: 2), child: Icon(i.icon, size: 16, color: p.muted)),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(i.label, style: text.labelSmall?.copyWith(color: p.muted)),
                  const SizedBox(height: 2),
                  Text(i.value, style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        );

    final rows = <Widget>[];
    for (var i = 0; i < items.length; i += 2) {
      rows.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: cell(items[i])),
          const SizedBox(width: 12),
          Expanded(child: i + 1 < items.length ? cell(items[i + 1]) : const SizedBox.shrink()),
        ],
      ));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          rows[i],
        ],
      ],
    );
  }
}

/// Código de barras decorativo del boleto (barras determinadas por [seed], con el folio debajo).
class TicketBarcode extends StatelessWidget {
  const TicketBarcode({super.key, required this.seed, this.height = 38});
  final String seed;
  final double height;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    return ExcludeSemantics(
      child: Column(
        children: [
          SizedBox(height: height, width: double.infinity, child: CustomPaint(painter: _BarcodePainter(seed, p.text))),
          const SizedBox(height: 6),
          Text(seed, style: text.labelSmall?.copyWith(color: p.muted, letterSpacing: 3)),
        ],
      ),
    );
  }
}

class _BarcodePainter extends CustomPainter {
  const _BarcodePainter(this.seed, this.color);
  final String seed;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    var h = 17;
    for (final c in seed.codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    final paint = Paint()..color = color;
    var x = 0.0;
    while (x < size.width) {
      h = (h * 1103515245 + 12345) & 0x7fffffff;
      final w = 1.0 + (h % 3);
      final gap = 1.5 + ((h >> 4) % 3);
      if (x + w > size.width) break;
      canvas.drawRect(Rect.fromLTWH(x, 0, w, size.height), paint);
      x += w + gap;
    }
  }

  @override
  bool shouldRepaint(_BarcodePainter old) => old.seed != seed || old.color != color;
}
