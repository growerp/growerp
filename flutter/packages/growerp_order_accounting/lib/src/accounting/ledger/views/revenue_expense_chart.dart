/*
 * This software is in the public domain under CC0 1.0 Universal plus a
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

import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../accounting.dart';

class RevenueExpenseChart extends StatelessWidget {
  // ignore: use_super_parameters
  const RevenueExpenseChart({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LedgerBloc(context.read<RestClient>()),
      child: const RevenueExpenseForm(),
    );
  }
}

class RevenueExpenseForm extends StatefulWidget {
  const RevenueExpenseForm({super.key});

  @override
  RevenueExpenseChartState createState() => RevenueExpenseChartState();
}

class RevenueExpenseChartState extends State<RevenueExpenseForm> {
  final TextEditingController _periodSearchBoxController =
      TextEditingController();
  NumberFormat formatter = NumberFormat("00");
  late int level;
  late LedgerBloc _ledgerBloc;
  late bool expanded;
  late TimePeriod _selectedPeriod;

  @override
  void initState() {
    super.initState();
    _ledgerBloc = context.read<LedgerBloc>();
    _selectedPeriod =
        TimePeriod(periodName: 'Y${DateTime.now().year}', periodType: 'Y');
    _ledgerBloc.add(LedgerFetch(ReportType.revenueExpense,
        periodName: _selectedPeriod.periodName));
    level = 0;
    expanded = false;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LedgerBloc, LedgerState>(listener: (context, state) {
      if (state.status == LedgerStatus.failure) {
        HelperFunctions.showMessage(context, '${state.message}', Colors.red);
      }
    }, builder: (context, state) {
      Color getColor(int line) {
        switch (line) {
          case 1:
            return Theme.of(context).colorScheme.onSecondary.withGreen(0);
          case 2:
            return Theme.of(context).colorScheme.primary.withGreen(200);
          case 3:
            return Theme.of(context).colorScheme.onSecondary.withBlue(0);
          case 4:
            return Theme.of(context).colorScheme.tertiary.withRed(1000);
          case 5:
            return Theme.of(context).colorScheme.onTertiary.withRed(100);
          default:
            return Theme.of(context).colorScheme.primary.withGreen(200);
        }
      }

      // calculate maxY and minY
      double maxY = 0.0, minY = 0.0;
      List<List<double>> newCsvRows = [];
      if (state.ledgerReport?.csvRows != null) {
        for (int row = 1; row < state.ledgerReport!.csvRows!.length; row++) {
          List<double> newRow = [];
          for (int cell = 1;
              cell < state.ledgerReport!.csvRows![0].length;
              cell++) {
            double doubleCell =
                double.parse(state.ledgerReport!.csvRows![row][cell]);
            if (doubleCell < minY) {
              minY = doubleCell;
            }
            if (doubleCell > maxY) {
              maxY = doubleCell;
            }
            newRow.add(doubleCell);
          }
          newCsvRows.add(newRow);
        }
      }

      switch (state.status) {
        case LedgerStatus.success:
        case LedgerStatus.failure:
          return Scaffold(
              body: Column(
            children: [
              SizedBox(
                height: 100,
                child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  SizedBox(
                    width: 150,
                    child: DropdownSearch<TimePeriod>(
                      key: const Key('periodDropDown'),
                      selectedItem: _selectedPeriod,
                      popupProps: PopupProps.menu(
                        isFilterOnline: true,
                        showSearchBox: true,
                        searchFieldProps: TextFieldProps(
                          autofocus: true,
                          decoration:
                              const InputDecoration(labelText: 'Year End'),
                          controller: _periodSearchBoxController,
                        ),
                        menuProps: MenuProps(
                            borderRadius: BorderRadius.circular(20.0)),
                        title: popUp(
                          context: context,
                          title: 'Select period',
                          height: 50,
                        ),
                      ),
                      dropdownDecoratorProps: const DropDownDecoratorProps(
                        dropdownSearchDecoration: InputDecoration(
                          labelText: 'Year End',
                        ),
                      ),
                      itemAsString: (TimePeriod? u) =>
                          " ${u!.periodName.substring(1)}", // invisible char for test
                      onChanged: (TimePeriod? newValue) {
                        setState(() => _selectedPeriod = newValue!);
                        _ledgerBloc.add(LedgerFetch(ReportType.revenueExpense,
                            periodName: newValue!.periodName));
                      },
                      items: state.timePeriods,
                      validator: (value) =>
                          value == null ? 'field required' : null,
                    ),
                  ),
                ]),
              ),
              if (state.ledgerReport?.csvRows == null ||
                  (minY == 0.0 && maxY == 0.0))
                Text(
                    "no data found for period ${state.ledgerReport?.period!.periodName.substring(1, 5)}",
                    textAlign: TextAlign.center),
              if (state.ledgerReport?.csvRows != null &&
                  (minY != 0.0 || maxY != 0.0))
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: LineChart(
                      LineChartData(
                          titlesData: const FlTitlesData(
                              show: true,
                              topTitles:
                                  AxisTitles(axisNameWidget: Text('Month')),
                              leftTitles:
                                  AxisTitles(axisNameWidget: Text('\$'))),
                          extraLinesData: ExtraLinesData(horizontalLines: [
                            for (int title = 0;
                                title <
                                    state.ledgerReport!.csvRows![0].length - 1;
                                title++)
                              HorizontalLine(
                                  strokeWidth: 0,
                                  y: maxY - maxY / 16 - (title * maxY / 16),
                                  label: HorizontalLineLabel(
                                      style: TextStyle(
                                        color: getColor(title),
                                      ),
                                      show: true,
                                      labelResolver: (p0) => state.ledgerReport!
                                          .csvRows![0][title + 1]))
                          ]),
                          lineBarsData: [
                            for (int column = 0;
                                column < newCsvRows[0].length;
                                column++)
                              LineChartBarData(
                                  dotData: const FlDotData(show: false),
                                  preventCurveOverShooting: true,
                                  isCurved: true,
                                  show: true,
                                  color: getColor(column),
                                  spots: [
                                    for (int x = 1;
                                        x < newCsvRows.length + 1;
                                        x++)
                                      FlSpot(x.toDouble(),
                                          newCsvRows[x - 1][column])
                                  ]),
                          ],
                          maxY: maxY,
                          minY: minY),

                      // swapAnimationDuration: const Duration(milliseconds: 150), // Optional
                      // swapAnimationCurve: Curves.linear, // Optional
                    ),
                  ),
                )
            ],
          ));
        default:
          return const LoadingIndicator();
      }
    });
  }
}
