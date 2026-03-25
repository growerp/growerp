/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 *
 * To the extent possible under law, the author(s) have dedicated all
 * copyright and related and neighboring rights to this software to the
 * public domain worldwide. This software is distributed without any
 * warranty.
 *
 * You should have received a copy of the CC0 Public Domain Dedication
 * along with this software (see the LICENSE.md file). If not, see
 * <http://creativecommons.org/publicdomain/zero/1.0/>.
 */

import 'package:decimal/decimal.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Generates and prints a Production Order PDF for a given [workOrder].
///
/// Layout:
///   - Header: WO#, Product, Qty, Start Date, Routing
///   - Panels table: QC# | Panel Name | Liner | Width | Length | SqFt | Passes | Weight
///   - Liner Totals: Liner | Total SqFt | Est. Weight
///   - BOM Items: Product ID | Quantity
Future<void> printProductionOrder(WorkOrder workOrder) async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.letter,
      build: (pw.Context context) => [
        _buildHeader(workOrder),
        pw.SizedBox(height: 12),
        _buildPanelsTable(workOrder.linerPanels),
        pw.SizedBox(height: 12),
        _buildLinerTotals(workOrder.linerPanels),
        if (workOrder.bomItems.isNotEmpty) ...[
          pw.SizedBox(height: 12),
          _buildBomTable(workOrder.bomItems),
        ],
      ],
    ),
  );

  await Printing.layoutPdf(
    onLayout: (PdfPageFormat format) async => pdf.save(),
    name: 'ProductionOrder_${workOrder.pseudoId}',
  );
}

pw.Widget _buildHeader(WorkOrder workOrder) {
  return pw.Container(
    padding: const pw.EdgeInsets.all(8),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.grey400),
      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'PRODUCTION ORDER',
              style: pw.TextStyle(
                  fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              'WO# ${workOrder.pseudoId}',
              style: pw.TextStyle(
                  fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Row(children: [
          _headerField('Product', workOrder.productName ?? workOrder.productPseudoId ?? ''),
          _headerField('Qty', workOrder.estimatedQuantity?.toString() ?? ''),
          _headerField('Start Date', workOrder.estimatedStartDate ?? ''),
          _headerField('Routing', workOrder.routingName ?? ''),
        ]),
        if (workOrder.workEffortName != null)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 4),
            child: pw.Text('Note: ${workOrder.workEffortName!}'),
          ),
      ],
    ),
  );
}

pw.Widget _headerField(String label, String value) {
  return pw.Expanded(
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label,
            style: pw.TextStyle(
                fontSize: 8, color: PdfColors.grey600)),
        pw.Text(value,
            style: pw.TextStyle(
                fontSize: 10, fontWeight: pw.FontWeight.bold)),
      ],
    ),
  );
}

pw.Widget _buildPanelsTable(List<LinerPanel> panels) {
  if (panels.isEmpty) {
    return pw.Text('No panels recorded.',
        style: const pw.TextStyle(fontSize: 10));
  }
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text('Liner Panels',
          style:
              pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 4),
      pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey300),
        columnWidths: {
          0: const pw.FlexColumnWidth(1),
          1: const pw.FlexColumnWidth(2),
          2: const pw.FlexColumnWidth(2),
          3: const pw.FlexColumnWidth(1),
          4: const pw.FlexColumnWidth(1),
          5: const pw.FlexColumnWidth(1),
          6: const pw.FlexColumnWidth(1),
          7: const pw.FlexColumnWidth(1),
        },
        children: [
          _tableHeaderRow(
              ['QC#', 'Panel Name', 'Liner', 'W(ft)', 'L(ft)', 'SqFt', 'Passes', 'Wt(lb)']),
          ...panels.map((p) => _tablePanelRow(p)),
        ],
      ),
    ],
  );
}

pw.TableRow _tableHeaderRow(List<String> headers) {
  return pw.TableRow(
    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
    children: headers
        .map((h) => pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text(h,
                  style: pw.TextStyle(
                      fontSize: 8, fontWeight: pw.FontWeight.bold),
                  textAlign: pw.TextAlign.center),
            ))
        .toList(),
  );
}

pw.TableRow _tablePanelRow(LinerPanel p) {
  return pw.TableRow(
    children: [
      p.qcNum,
      p.panelName ?? '',
      p.linerName ?? '',
      p.panelWidth?.toString() ?? '',
      p.panelLength?.toString() ?? '',
      p.panelSqft?.toString() ?? '',
      p.passes?.toString() ?? '',
      p.weight?.toString() ?? '',
    ]
        .map((v) => pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text(v,
                  style: const pw.TextStyle(fontSize: 8),
                  textAlign: pw.TextAlign.center),
            ))
        .toList(),
  );
}

pw.Widget _buildLinerTotals(List<LinerPanel> panels) {
  if (panels.isEmpty) return pw.SizedBox();

  // Group by liner type
  final Map<String, _LinerTotals> totals = {};
  for (final p in panels) {
    final key = p.linerName ?? p.linerTypeId ?? 'Unknown';
    totals.putIfAbsent(key, () => _LinerTotals(key));
    totals[key]!.addPanel(p);
  }

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text('Liner Totals',
          style:
              pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 4),
      pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey300),
        columnWidths: {
          0: const pw.FlexColumnWidth(3),
          1: const pw.FlexColumnWidth(2),
          2: const pw.FlexColumnWidth(2),
        },
        children: [
          _tableHeaderRow(['Liner', 'Total SqFt', 'Est. Weight (lb)']),
          ...totals.values.map(
            (t) => pw.TableRow(children: [
              t.linerName,
              t.totalSqft.toStringAsFixed(1),
              t.totalWeight.toStringAsFixed(1),
            ]
                .map((v) => pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(v,
                          style: const pw.TextStyle(fontSize: 8)),
                    ))
                .toList()),
          ),
        ],
      ),
    ],
  );
}

pw.Widget _buildBomTable(List<BomItem> items) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text('BOM / Materials',
          style:
              pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 4),
      pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey300),
        columnWidths: {
          0: const pw.FlexColumnWidth(3),
          1: const pw.FlexColumnWidth(2),
        },
        children: [
          _tableHeaderRow(['Product', 'Quantity']),
          ...items.map(
            (item) => pw.TableRow(children: [
              '${item.componentPseudoId}${item.componentName != null ? ' – ${item.componentName}' : ''}',
              item.quantity?.toString() ?? '',
            ]
                .map((v) => pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(v,
                          style: const pw.TextStyle(fontSize: 8)),
                    ))
                .toList()),
          ),
        ],
      ),
    ],
  );
}

class _LinerTotals {
  final String linerName;
  double totalSqft = 0;
  double totalWeight = 0;

  _LinerTotals(this.linerName);

  void addPanel(LinerPanel p) {
    totalSqft +=
        (p.panelSqft ?? Decimal.zero).toDouble();
    totalWeight +=
        (p.weight ?? Decimal.zero).toDouble();
  }
}
