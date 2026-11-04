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
import 'pos_z_report.dart';

/// The numbers of a shift on the screen, with printing.
class PosZReportDialog extends StatelessWidget {
  const PosZReportDialog(this.report, {super.key, required this.currencyId});
  final PosZReport report;
  final String currencyId;

  @override
  Widget build(BuildContext context) {
    final localizations = PosLocalizations.of(context)!;
    final rows = posZReportRows(
      report,
      PosZReportLabels.of(localizations),
      currencyId,
    );
    return Dialog(
      key: const Key('PosZReportDialog'),
      insetPadding: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: popUp(
        context: context,
        title: '${localizations.zReport} ${report.terminalName ?? ''}',
        height: 560,
        width: 380,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                key: const Key('listView'),
                children: [
                  for (final row in rows)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(child: Text(row.label)),
                        Text(row.value, key: Key('posZ${row.key}')),
                      ],
                    ),
                ],
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('posZPrint'),
                    icon: const Icon(Icons.print),
                    label: Text(localizations.print),
                    onPressed: () {
                      final authenticate = context
                          .read<AuthBloc>()
                          .state
                          .authenticate;
                      Printing.layoutPdf(
                        format: PdfPageFormat.roll80,
                        onLayout: (_) => buildPosZReport(
                          title:
                              '${localizations.zReport} '
                              '${report.terminalName ?? ''}',
                          companyName: authenticate?.company?.name ?? '',
                          rows: rows,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    key: const Key('posZDone'),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(localizations.close),
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
