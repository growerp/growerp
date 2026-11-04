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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../../../l10n/generated/pos_localizations.dart';
import 'pos_receipt.dart';

/// The finished sale on the screen, with printing and the way to the next sale.
class PosReceiptDialog extends StatelessWidget {
  const PosReceiptDialog(this.sale, {super.key});
  final PosSale sale;

  @override
  Widget build(BuildContext context) {
    final localizations = PosLocalizations.of(context)!;
    final currencyId = sale.currencyId ?? 'USD';
    Widget row(String label, String value, {Key? key}) => Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(child: Text(label)),
        Text(value, key: key),
      ],
    );
    return Dialog(
      key: const Key('PosReceiptDialog'),
      insetPadding: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: popUp(
        context: context,
        title: localizations.receipt,
        height: 520,
        width: 360,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                key: const Key('listView'),
                children: [
                  Text(
                    sale.invoicePseudoId ?? '',
                    key: const Key('posReceiptNumber'),
                    textAlign: TextAlign.center,
                  ),
                  const Divider(),
                  for (final line in sale.lines)
                    row(
                      '${line.quantity} x ${line.description ?? ''}',
                      line.lineTotal.currency(currencyId: currencyId),
                    ),
                  const Divider(),
                  for (final tax in sale.taxes)
                    row(
                      '${localizations.tax} ${tax.taxPercentage}%',
                      tax.taxAmount.currency(currencyId: currencyId),
                    ),
                  row(
                    localizations.total,
                    sale.grandTotal.currency(currencyId: currencyId),
                    key: const Key('posReceiptTotal'),
                  ),
                  const Divider(),
                  for (final tender in sale.tenders)
                    row(
                      tender.method == 'PiCash'
                          ? localizations.cash
                          : localizations.card,
                      tender.amount.currency(currencyId: currencyId),
                    ),
                  row(
                    localizations.change,
                    sale.changeAmount.currency(currencyId: currencyId),
                    key: const Key('posReceiptChange'),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('posPrint'),
                    icon: const Icon(Icons.print),
                    label: Text(localizations.print),
                    onPressed: () {
                      final authenticate = context
                          .read<AuthBloc>()
                          .state
                          .authenticate;
                      Printing.layoutPdf(
                        format: PdfPageFormat.roll80,
                        onLayout: (_) => buildPosReceipt(
                          sale,
                          companyName: authenticate?.company?.name ?? '',
                          labels: PosReceiptLabels.of(localizations),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    key: const Key('posNewSale'),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(localizations.newSale),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
