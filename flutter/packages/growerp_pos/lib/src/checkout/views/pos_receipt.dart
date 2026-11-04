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

import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../l10n/generated/pos_localizations.dart';

/// The words on the receipt: the PDF is built outside the widget tree.
class PosReceiptLabels {
  const PosReceiptLabels({
    required this.tax,
    required this.total,
    required this.cash,
    required this.card,
    required this.change,
  });
  final String tax;
  final String total;
  final String cash;
  final String card;
  final String change;

  factory PosReceiptLabels.of(PosLocalizations localizations) =>
      PosReceiptLabels(
        tax: localizations.tax,
        total: localizations.total,
        cash: localizations.cash,
        card: localizations.card,
        change: localizations.change,
      );
}

/// A receipt on an 80mm roll.
Future<Uint8List> buildPosReceipt(
  PosSale sale, {
  required String companyName,
  required PosReceiptLabels labels,
}) async {
  final currencyId = sale.currencyId ?? 'USD';
  pw.Widget row(String label, String value, {bool bold = false}) => pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      pw.Flexible(child: pw.Text(label)),
      pw.Text(
        value,
        style: bold ? pw.TextStyle(fontWeight: pw.FontWeight.bold) : null,
      ),
    ],
  );
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
          pw.SizedBox(height: 4),
          pw.Text(
            '${sale.invoicePseudoId ?? ''}  '
            '${sale.saleDate?.dateOnly() ?? ''}',
            textAlign: pw.TextAlign.center,
          ),
          pw.Divider(),
          for (final line in sale.lines)
            row(
              '${line.quantity} x ${line.description ?? ''}',
              line.lineTotal.currency(currencyId: currencyId),
            ),
          pw.Divider(),
          for (final tax in sale.taxes)
            row(
              '${labels.tax} ${tax.taxPercentage}%',
              tax.taxAmount.currency(currencyId: currencyId),
            ),
          row(
            labels.total,
            sale.grandTotal.currency(currencyId: currencyId),
            bold: true,
          ),
          pw.Divider(),
          for (final tender in sale.tenders)
            row(
              tender.method == 'PiCash' ? labels.cash : labels.card,
              tender.amount.currency(currencyId: currencyId),
            ),
          row(
            labels.change,
            sale.changeAmount.currency(currencyId: currencyId),
          ),
        ],
      ),
    ),
  );
  return document.save();
}

/// The slip of a refund on an 80mm roll.
Future<Uint8List> buildPosRefundReceipt(
  PosRefund refund, {
  required String companyName,
  required String title,
  required PosReceiptLabels labels,
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
          pw.SizedBox(height: 4),
          pw.Text(
            '$title ${refund.paymentPseudoId ?? ''}  '
            '${refund.refundDate?.dateOnly() ?? ''}',
            textAlign: pw.TextAlign.center,
          ),
          pw.Divider(),
          for (final line in refund.lines)
            pw.Text('${line.quantity} x ${line.description ?? ''}'),
          pw.Divider(),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(refund.method == 'PiCash' ? labels.cash : labels.card),
              pw.Text(
                refund.amount.currency(currencyId: refund.currencyId ?? 'USD'),
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    ),
  );
  return document.save();
}
