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

    return BlocConsumer<LedgerBloc, LedgerState>(listener: (context, state) {
      if (state.status == LedgerStatus.failure) {
        HelperFunctions.showMessage(context, '${state.message}', Colors.red);
      }
    }, builder: (context, state) {
      switch (state.status) {
        case LedgerStatus.success:
        case LedgerStatus.failure:
          _selectedPeriod = state.ledgerReport!.period!;

          var months = [
            'Jan',
            'Feb',
            'Mar',
            'Apr',
            'May',
            'Jun',
            'Jul',
            'Aug',
            'Sep',
            'Oct',
            'Nov',
            'Dec'
          ];
          // calculate maxY and minY
          double maxY = 0.0, minY = 0.0;
          List<List<double>> newCsvRows = [];
          int row = 1;
          if (state.ledgerReport?.csvRows != null) {
            for (int i = 1; i < 13; i++) {
              List<double> newRow = [];
              if (months.indexWhere((month) =>
                          state.ledgerReport?.csvRows?[row][0]
                              .substring(0, 3) ==
                          month) ==
                      i - 1 &&
                  row < state.ledgerReport!.csvRows!.length - 1) {
                for (int cell = 1;
                    cell < state.ledgerReport!.csvRows![row].length;
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
                row++;
              } else {
                newRow = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
              }
              newCsvRows.add(newRow);
            }
          }

          return Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          tooltip: 'Previous Year',
                          onPressed: () {
                            // Extract the year from the period name
                            String currentPeriodName =
                                _selectedPeriod.periodName;
                            String yearStr = '';
                            int year = 0;

                            if (currentPeriodName.contains('q')) {
                              // Format: Y2025q1
                              yearStr = currentPeriodName.substring(1, 5);
                              year =
                                  int.tryParse(yearStr) ?? DateTime.now().year;
                            } else if (currentPeriodName.contains('m')) {
                              // Format: Y2025m01
                              yearStr = currentPeriodName.substring(1, 5);
                              year =
                                  int.tryParse(yearStr) ?? DateTime.now().year;
                            } else {
                              // Format: Y2025
                              yearStr = currentPeriodName.substring(1);
                              year =
                                  int.tryParse(yearStr) ?? DateTime.now().year;
                            }

                            // Go to previous year
                            int previousYear = year - 1;

                            // Check if the previous year exists in available periods
                            bool yearExists = _checkYearExists(
                                previousYear, state.timePeriods);

                            if (!yearExists) {
                              // Show message if year doesn't exist
                              HelperFunctions.showMessage(
                                context,
                                'Data for year $previousYear is not available',
                                Colors.orange,
                              );
                              return;
                            }

                            // Determine the new period name based on current period type
                            String newPeriodName = '';
                            if (_selectedPeriod.periodType == 'Y') {
                              newPeriodName = 'Y$previousYear';
                            } else if (_selectedPeriod.periodType == 'Q') {
                              // Extract quarter number
                              int quarterIndex = currentPeriodName.indexOf('q');
                              String quarter =
                                  currentPeriodName.substring(quarterIndex + 1);
                              newPeriodName = 'Y$previousYear${'q$quarter'}';
                            } else if (_selectedPeriod.periodType == 'M') {
                              // Extract month number
                              int monthIndex = currentPeriodName.indexOf('m');
                              String month =
                                  currentPeriodName.substring(monthIndex + 1);
                              newPeriodName = 'Y$previousYear${'m$month'}';
                            }

                            // Fetch data for the previous year
                            _ledgerBloc.add(LedgerFetch(
                              ReportType.revenueExpense,
                              periodName: newPeriodName,
                            ));
                          },
                        ),
                        Text(
                          'Year: ${_getYearFromPeriod(_selectedPeriod.periodName)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward),
                          tooltip: 'Next Year',
                          onPressed: () {
                            // Extract the year from the period name
                            String currentPeriodName =
                                _selectedPeriod.periodName;
                            String yearStr = '';
                            int year = 0;

                            if (currentPeriodName.contains('q')) {
                              // Format: Y2025q1
                              yearStr = currentPeriodName.substring(1, 5);
                              year =
                                  int.tryParse(yearStr) ?? DateTime.now().year;
                            } else if (currentPeriodName.contains('m')) {
                              // Format: Y2025m01
                              yearStr = currentPeriodName.substring(1, 5);
                              year =
                                  int.tryParse(yearStr) ?? DateTime.now().year;
                            } else {
                              // Format: Y2025
                              yearStr = currentPeriodName.substring(1);
                              year =
                                  int.tryParse(yearStr) ?? DateTime.now().year;
                            }

                            // Go to next year (but don't exceed current year)
                            int nextYear = year + 1;
                            int currentYear = DateTime.now().year;
                            if (nextYear > currentYear) {
                              nextYear = currentYear;
                            }

                            // Check if the next year exists in available periods
                            bool yearExists =
                                _checkYearExists(nextYear, state.timePeriods);

                            if (!yearExists) {
                              // Show message if year doesn't exist
                              HelperFunctions.showMessage(
                                context,
                                'Data for year $nextYear is not available',
                                Colors.orange,
                              );
                              return;
                            }

                            // Determine the new period name based on current period type
                            String newPeriodName = '';
                            if (_selectedPeriod.periodType == 'Y') {
                              newPeriodName = 'Y$nextYear';
                            } else if (_selectedPeriod.periodType == 'Q') {
                              // Extract quarter number
                              int quarterIndex = currentPeriodName.indexOf('q');
                              String quarter =
                                  currentPeriodName.substring(quarterIndex + 1);
                              newPeriodName = 'Y$nextYear${'q$quarter'}';
                            } else if (_selectedPeriod.periodType == 'M') {
                              // Extract month number
                              int monthIndex = currentPeriodName.indexOf('m');
                              String month =
                                  currentPeriodName.substring(monthIndex + 1);
                              newPeriodName = 'Y$nextYear${'m$month'}';
                            }

                            // Fetch data for the next year
                            _ledgerBloc.add(LedgerFetch(
                              ReportType.revenueExpense,
                              periodName: newPeriodName,
                            ));
                          },
                        ),
                      ],
                    ),
                    Text(
                      'Period: ${_selectedPeriod.periodName}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
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
                          titlesData: FlTitlesData(
                              show: true,
                              topTitles: const AxisTitles(
                                  axisNameWidget: Text("By Month")),
                              leftTitles:
                                  const AxisTitles(axisNameWidget: Text('\$')),
                              bottomTitles: AxisTitles(
                                  axisNameSize: 50,
                                  axisNameWidget: Padding(
                                    padding: const EdgeInsets.all(15.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        0,
                                        1,
                                        2,
                                        3,
                                        4,
                                        5,
                                        6,
                                        7,
                                        8,
                                        9,
                                        10,
                                        11,
                                        12
                                      ]
                                          .map((e) => Text(
                                                e.toString(),
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                ),
                                              ))
                                          .toList(),
                                    ),
                                  ))),
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
          );
        default:
          return const LoadingIndicator();
      }
    });
  }

  // Helper method to extract year from period name
  String _getYearFromPeriod(String periodName) {
    if (periodName.startsWith('Y')) {
      if (periodName.contains('q') || periodName.contains('m')) {
        // Format: Y2025q1 or Y2025m01
        return periodName.substring(1, 5);
      } else {
        // Format: Y2025
        return periodName.substring(1);
      }
    }
    return DateTime.now().year.toString();
  }

  // Helper method to check if a year exists in the available time periods
  bool _checkYearExists(int year, List<TimePeriod> timePeriods) {
    String yearStr = year.toString();

    // Check if any period starts with the year we're looking for
    for (TimePeriod period in timePeriods) {
      if (period.periodName.startsWith('Y$yearStr')) {
        return true;
      }
    }

    return false;
  }
}
