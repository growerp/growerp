/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:typed_data';

import 'package:decimal/decimal.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../l10n/generated/pos_localizations.dart';

/// The words of the report: the PDF is built outside the widget tree.
class PosZReportLabels {
  const PosZReportLabels(this.localizations);
  final PosLocalizations localizations;

  factory PosZReportLabels.of(PosLocalizations localizations) =>
      PosZReportLabels(localizations);

  String tender(String? method) =>
      method == 'PiCash' ? localizations.cash : localizations.card;
}

class PosZRow {
  const PosZRow(this.key, this.label, this.value);
  final String key;
  final String label;
  final String value;
}

/// One list of rows for the screen and the paper.
List<PosZRow> posZReportRows(
  PosZReport report,
  PosZReportLabels labels,
  String currencyId,
) {
  final l = labels.localizations;
  String money(Decimal? amount) => amount.currency(currencyId: currencyId);
  return [
    PosZRow(
      'Sales',
      '${l.sales} (${report.saleCount ?? 0})',
      money(report.salesTotal),
    ),
    for (final tender in report.tenders)
      PosZRow(
        'Sales${tender.method}',
        '  ${labels.tender(tender.method)}',
        money(tender.amount),
      ),
    for (final tax in report.taxes)
      PosZRow(
        'Tax${tax.taxPercentage}',
        '${l.tax} ${tax.taxPercentage}%',
        money(tax.taxAmount),
      ),
    PosZRow(
      'Refunds',
      '${l.refunds} (${report.refundCount ?? 0})',
      money(report.refundTotal),
    ),
    for (final tender in report.refundTenders)
      PosZRow(
        'Refunds${tender.method}',
        '  ${labels.tender(tender.method)}',
        money(tender.amount),
      ),
    PosZRow('RefundTax', l.refundedTax, money(report.refundTaxTotal)),
    if ((report.voidCount ?? 0) > 0)
      PosZRow('Voids', l.voidedLines, '${report.voidCount}'),
    PosZRow('Float', l.openingFloat, money(report.openingFloat)),
    PosZRow('Movements', l.cashMovement, money(report.movementTotal)),
    PosZRow('Expected', l.expectedCash, money(report.expectedCash)),
    if (report.countedCash != null) ...[
      PosZRow('Counted', l.countedCash, money(report.countedCash)),
      PosZRow('Variance', l.variance, money(report.variance)),
    ],
  ];
}

/// The report on an 80mm roll.
Future<Uint8List> buildPosZReport({
  required String title,
  required String companyName,
  required List<PosZRow> rows,
}) async {
  final document = pw.Document();
  document.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.roll80.copyWith(
        marginLeft: 4 * PdfPageFormat.mm,
        marginRight: 4 * PdfPageFormat.mm,
        marginTop: 4 * PdfPageFormat.mm,
        marginBottom: 4 * PdfPageFormat.mm,
      ),
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Text(
            companyName,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
          ),
          pw.Text(title, textAlign: pw.TextAlign.center),
          pw.Divider(),
          for (final row in rows)
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Flexible(child: pw.Text(row.label)),
                pw.Text(row.value),
              ],
            ),
        ],
      ),
    ),
  );
  return document.save();
}
