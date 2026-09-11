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

import 'dart:convert';
import 'package:decimal/decimal.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:intl/intl.dart';
import 'package:growerp_order_accounting/l10n/generated/order_accounting_localizations.dart';

import '../../accounting/ledger/blocs/ledger_bloc.dart';
import '../../accounting/ledger/fiscal_year.dart';

/// Simple profit & loss: income and expense accounts of a period with totals.
/// With [taxSummary] the report is yearly only, carries an explanation for the
/// self-employment tax filing, and its CSV export also lists every cash book
/// entry of the year.
class ProfitLossForm extends StatelessWidget {
  final bool taxSummary;
  const ProfitLossForm({super.key, this.taxSummary = false});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LedgerBloc(context.read<RestClient>()),
      child: ProfitLossReport(taxSummary: taxSummary),
    );
  }
}

/// Menu entry for the yearly tax summary
class TaxSummaryForm extends StatelessWidget {
  const TaxSummaryForm({super.key});
  @override
  Widget build(BuildContext context) => const ProfitLossForm(taxSummary: true);
}

class ProfitLossReport extends StatefulWidget {
  final bool taxSummary;
  const ProfitLossReport({super.key, required this.taxSummary});

  @override
  State<ProfitLossReport> createState() => _ProfitLossReportState();
}

class _ProfitLossReportState extends State<ProfitLossReport> {
  late LedgerBloc _ledgerBloc;
  late String periodName;
  late String currencyId;
  late OrderAccountingLocalizations _localizations;

  @override
  void initState() {
    super.initState();
    _ledgerBloc = context.read<LedgerBloc>();
    periodName = currentFiscalYearName(context);
    currencyId =
        context
            .read<AuthBloc>()
            .state
            .authenticate
            ?.company
            ?.currency
            ?.currencyId ??
        'USD';
    _fetch();
  }

  void _fetch() => _ledgerBloc.add(
    LedgerFetch(ReportType.profitLoss, periodName: periodName),
  );

  void _selectPeriod(String newPeriodName) {
    setState(() => periodName = newPeriodName);
    _fetch();
  }

  void _shiftYear(int delta, List<TimePeriod> timePeriods) {
    final year = yearFromPeriodName(periodName) + delta;
    if (!periodYearExists(timePeriods, year)) {
      HelperFunctions.showMessage(
        context,
        _localizations.dataForYearNotAvailable(year.toString()),
        Colors.orange,
      );
      return;
    }
    _selectPeriod(periodNameForYear(periodName, year));
  }

  String _money(Decimal? value) => value.currency(currencyId: currencyId);

  Future<void> _exportCsv(ProfitLoss report) async {
    final buffer = StringBuffer();
    String row(List<String> cells) => createCsvRow(cells, cells.length);
    buffer.write(
      row(['Section', 'Account code', 'Account', 'Class', 'Amount']),
    );
    for (final line in report.income) {
      buffer.write(
        row([
          _localizations.plIncome,
          line.accountCode,
          line.accountName,
          line.className,
          line.amount.toString(),
        ]),
      );
    }
    for (final line in report.expenses) {
      buffer.write(
        row([
          _localizations.plExpenses,
          line.accountCode,
          line.accountName,
          line.className,
          line.amount.toString(),
        ]),
      );
    }
    buffer.write(
      row([
        _localizations.plTotalIncome,
        '',
        '',
        '',
        report.totalIncome.toString(),
      ]),
    );
    buffer.write(
      row([
        _localizations.plTotalExpenses,
        '',
        '',
        '',
        report.totalExpenses.toString(),
      ]),
    );
    buffer.write(
      row([
        _localizations.plNetProfit,
        '',
        '',
        '',
        report.netProfit.toString(),
      ]),
    );

    if (widget.taxSummary && report.period != null) {
      // every cash book entry of the year, oldest first
      final entries = (await context.read<RestClient>().getCashBookEntry(
        fromDate: report.period!.fromDate?.toIso8601String(),
        thruDate: report.period!.thruDate?.toIso8601String(),
        start: 0,
        limit: 10000,
      )).cashBookEntries.reversed;
      buffer.write(row([]));
      buffer.write(
        row([
          'Date',
          'In/Out',
          'Amount',
          'Category',
          'Description',
          'Party',
          'Source',
          'Id',
        ]),
      );
      for (final entry in entries) {
        buffer.write(
          row([
            entry.date == null
                ? ''
                : DateFormat('yyyy-MM-dd').format(entry.date!),
            entry.isIncome ? 'in' : 'out',
            entry.amount.toString(),
            entry.category?.accountName ?? '',
            entry.description,
            entry.otherCompany?.name ??
                '${entry.otherUser?.firstName ?? ''} ${entry.otherUser?.lastName ?? ''}'
                    .trim(),
            entry.source,
            entry.pseudoId ?? '',
          ]),
        );
      }
    }
    if (!mounted) return;
    final fileName =
        '${widget.taxSummary ? 'TaxSummary' : 'ProfitLoss'}_$periodName.csv';
    try {
      final uri = await FilePicker.saveFile(
        dialogTitle: _localizations.exportCsv,
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['csv'],
        bytes: foundation.Uint8List.fromList(utf8.encode(buffer.toString())),
      );
      if (!mounted || uri == null) return; // cancelled
      HelperFunctions.showMessage(
        context,
        _localizations.exportDone(fileName),
        Colors.green,
      );
    } catch (e) {
      if (!mounted) return;
      HelperFunctions.showMessage(context, 'Could not save: $e', Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    _localizations = OrderAccountingLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return BlocConsumer<LedgerBloc, LedgerState>(
      listener: (context, state) {
        if (state.status == LedgerStatus.failure) {
          HelperFunctions.showMessage(context, '${state.message}', Colors.red);
        }
      },
      builder: (context, state) {
        if (state.status == LedgerStatus.initial ||
            (state.status == LedgerStatus.loading &&
                state.profitLoss == null)) {
          return const Center(child: LoadingIndicator());
        }
        final report = state.profitLoss;
        final year = yearFromPeriodName(periodName);

        Widget header() => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    key: const Key('previousYear'),
                    icon: const Icon(Icons.arrow_back),
                    tooltip: _localizations.previousYear,
                    onPressed: () => _shiftYear(-1, state.timePeriods),
                  ),
                  Text(
                    '${_localizations.year}$year',
                    key: const Key('periodLabel'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    key: const Key('nextYear'),
                    icon: const Icon(Icons.arrow_forward),
                    tooltip: _localizations.nextYear,
                    onPressed: year >= currentFiscalYear(context)
                        ? null
                        : () => _shiftYear(1, state.timePeriods),
                  ),
                ],
              ),
              if (!widget.taxSummary)
                SegmentedButton<String>(
                  key: const Key('periodType'),
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: 'Y',
                      label: Text(_localizations.yearLetter),
                    ),
                    ButtonSegment(
                      value: 'Q',
                      label: Text(_localizations.quarterLetter),
                    ),
                    ButtonSegment(
                      value: 'M',
                      label: Text(_localizations.monthLetter),
                    ),
                  ],
                  selected: {
                    periodName.contains('q')
                        ? 'Q'
                        : periodName.contains('m')
                        ? 'M'
                        : 'Y',
                  },
                  onSelectionChanged: (selection) {
                    final now = DateTime.now();
                    final suffix = switch (selection.first) {
                      'Q' =>
                        'q${(((now.month - 1) ~/ 3) + 1).toString().padLeft(2, '0')}',
                      'M' => 'm${now.month.toString().padLeft(2, '0')}',
                      _ => '',
                    };
                    _selectPeriod('Y$year$suffix');
                  },
                ),
              if (!widget.taxSummary && periodName.length > 5)
                DropdownButton<String>(
                  key: const Key('periodSelect'),
                  value:
                      state.timePeriods.any((p) => p.periodName == periodName)
                      ? periodName
                      : null,
                  hint: Text(periodName),
                  items: [
                    for (final period in state.timePeriods.where(
                      (p) => p.periodName.startsWith('Y$year'),
                    ))
                      DropdownMenuItem(
                        value: period.periodName,
                        child: Text(period.periodName),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) _selectPeriod(value);
                  },
                ),
              if (report != null)
                OutlinedButton.icon(
                  key: const Key('exportCsv'),
                  icon: const Icon(Icons.download),
                  label: Text(_localizations.exportCsv),
                  onPressed: () => _exportCsv(report),
                ),
            ],
          ),
        );

        Widget section(
          String title,
          List<ProfitLossLine> lines,
          String totalLabel,
          Decimal? total,
          Color color,
          String key,
        ) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  for (final (index, line) in lines.indexed)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${line.accountCode} ${line.accountName}',
                              key: Key('$key$index'),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            _money(line.amount),
                            key: Key('${key}Amount$index'),
                          ),
                        ],
                      ),
                    ),
                  const Divider(),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          totalLabel,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        _money(total),
                        key: Key('${key}Total'),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: [
            if (widget.taxSummary)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Text(
                  _localizations.taxSummaryHint,
                  key: const Key('taxSummaryHint'),
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ),
            header(),
            if (report == null)
              Expanded(child: Center(child: Text(_localizations.plNoData)))
            else
              Expanded(
                child: ListView(
                  key: const Key('listView'),
                  children: [
                    if (report.income.isEmpty && report.expenses.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          _localizations.plNoData,
                          key: const Key('plNoData'),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    section(
                      _localizations.plIncome,
                      report.income,
                      _localizations.plTotalIncome,
                      report.totalIncome,
                      colorScheme.success,
                      'income',
                    ),
                    section(
                      _localizations.plExpenses,
                      report.expenses,
                      _localizations.plTotalExpenses,
                      report.totalExpenses,
                      colorScheme.danger,
                      'expense',
                    ),
                    Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      color: colorScheme.primaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _localizations.plNetProfit,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Text(
                              _money(report.netProfit),
                              key: const Key('netProfit'),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color:
                                    (report.netProfit ?? Decimal.zero) <
                                        Decimal.zero
                                    ? colorScheme.danger
                                    : colorScheme.success,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
