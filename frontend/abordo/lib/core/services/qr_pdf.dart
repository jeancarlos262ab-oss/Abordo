import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../features/owner/domain/owner_models.dart';
import '../utils/money.dart';

/// Arma el PDF con el QR de una unidad (hoja carta, listo para imprimir y pegar) y abre el
/// diálogo del sistema para imprimirlo, guardarlo o compartirlo.
///
/// Requiere en pubspec.yaml: `pdf` y `printing`.
abstract final class QrPdf {
  static const _ink = PdfColor.fromInt(0xFF161314);
  static const _pink = PdfColor.fromInt(0xFFF7B5CD);
  static const _pinkDeep = PdfColor.fromInt(0xFFE97FA7);
  static const _grey = PdfColor.fromInt(0xFF655E61);
  static const _line = PdfColor.fromInt(0xFFE7E2E4);

  static Future<void> printOrSave(OwnerUnit unit) async {
    final bytes = await build(unit);
    await Printing.layoutPdf(name: 'QR ${unit.label}.pdf', onLayout: (_) async => bytes);
  }

  static Future<Uint8List> build(OwnerUnit unit) async {
    final doc = pw.Document(title: 'QR ${unit.label}', author: 'ABORDO');

    pw.Widget step(String n, String label) => pw.Expanded(
          child: pw.Column(children: [
            pw.Container(
              width: 34,
              height: 34,
              alignment: pw.Alignment.center,
              decoration: const pw.BoxDecoration(color: _pink, shape: pw.BoxShape.circle),
              child: pw.Text(n, style: pw.TextStyle(color: _ink, fontSize: 16, fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 8),
            pw.Text(label, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: _ink)),
          ]),
        );

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(40),
        build: (_) => pw.Container(
          decoration: pw.BoxDecoration(
            borderRadius: pw.BorderRadius.circular(28),
            border: pw.Border.all(color: _ink, width: 3),
          ),
          child: pw.ClipRRect(
            horizontalRadius: 25,
            verticalRadius: 25,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // Cabecera.
                pw.Container(
                  color: _ink,
                  padding: const pw.EdgeInsets.fromLTRB(30, 28, 30, 26),
                  child: pw.Column(children: [
                    pw.Text('ABORDO', style: pw.TextStyle(color: PdfColors.white, fontSize: 22, fontWeight: pw.FontWeight.bold, letterSpacing: 5)),
                    pw.SizedBox(height: 14),
                    pw.Text('Paga tu pasaje con CoDi', style: pw.TextStyle(color: _pink, fontSize: 34, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),
                    pw.Text('Sin cambio. Sin comisión. En segundos.', style: const pw.TextStyle(color: PdfColors.white, fontSize: 15)),
                  ]),
                ),
                pw.SizedBox(height: 26),
                // QR.
                pw.Center(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(18),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: pw.BorderRadius.circular(20),
                      border: pw.Border.all(color: _pinkDeep, width: 4),
                    ),
                    child: pw.BarcodeWidget(
                      barcode: pw.Barcode.qrCode(),
                      data: unit.qrContent,
                      width: 290,
                      height: 290,
                      color: _ink,
                    ),
                  ),
                ),
                pw.SizedBox(height: 22),
                pw.Center(child: pw.Text(unit.label, style: pw.TextStyle(fontSize: 30, fontWeight: pw.FontWeight.bold, color: _ink))),
                pw.SizedBox(height: 2),
                pw.Center(child: pw.Text('${unit.route}  -  Pasaje ${Money.format(unit.fareCents)}', style: const pw.TextStyle(fontSize: 18, color: _grey))),
                pw.SizedBox(height: 18),
                // Número para quien no pueda escanear.
                pw.Center(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 26, vertical: 12),
                    decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFFF6F3F4), borderRadius: pw.BorderRadius.circular(40), border: pw.Border.all(color: _line)),
                    child: pw.Column(children: [
                      pw.Text('NUMERO DE LA UNIDAD', style: pw.TextStyle(fontSize: 11, color: _grey, letterSpacing: 2, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 2),
                      pw.Text(unit.spacedCode, style: pw.TextStyle(fontSize: 34, fontWeight: pw.FontWeight.bold, color: _ink, letterSpacing: 5)),
                    ]),
                  ),
                ),
                pw.Spacer(),
                // Pasos.
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 30),
                  child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                    step('1', 'Escanea'),
                    step('2', 'Confirma'),
                    step('3', 'Paga'),
                  ]),
                ),
                pw.SizedBox(height: 22),
                pw.Container(
                  color: _pink,
                  padding: const pw.EdgeInsets.symmetric(vertical: 14),
                  child: pw.Center(child: pw.Text('Abre la camara de tu celular y apunta al codigo', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: _ink))),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return doc.save();
  }
}
