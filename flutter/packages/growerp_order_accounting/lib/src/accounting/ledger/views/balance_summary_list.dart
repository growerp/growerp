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
// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_order_accounting/l10n/generated/order_accounting_localizations.dart';
import 'package:intl/intl.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../accounting.dart';

class BalanceSummaryList extends StatefulWidget {
  const BalanceSummaryList({super.key});

  @override
  BalanceSummaryListState createState() => BalanceSummaryListState();
}

class BalanceSummaryListState extends State<BalanceSummaryList> {
  final _itemScrollController = ItemScrollController();
  final _itemPositionsListener = ItemPositionsListener.create();
  NumberFormat formatter = NumberFormat("00");
  late bool search;
  late LedgerBloc _ledgerBloc;
  late bool started;
  late TimePeriod _selectedPeriod;
  late double bottom;
  double? right;
  late OrderAccountingLocalizations _local;

  @override
  void initState() {
    super.initState();
    started = false;
    search = false;
    _selectedPeriod = TimePeriod(
      periodName: 'Y${DateTime.now().year}',
      periodType: 'Y',
    );
    _ledgerBloc = context.read<LedgerBloc>()
      ..add(
        LedgerFetch(ReportType.summary, periodName: _selectedPeriod.periodName),
      );
    _selectedPeriod = TimePeriod(
      periodName: 'Y${DateTime.now().year}',
      periodType: 'Y',
    );
    bottom = 50;
  }

  @override
  Widget build(BuildContext context) {
    _local = OrderAccountingLocalizations.of(context)!;
    right = right ?? (isAPhone(context) ? 20 : 50);
    return BlocConsumer<LedgerBloc, LedgerState>(
      listenWhen: (previous, current) =>
          previous.status == LedgerStatus.loading,
      listener: (context, state) {
        if (state.status == LedgerStatus.failure) {
          HelperFunctions.showMessage(context, '${state.message}', Colors.red);
        }
        if (state.status == LedgerStatus.success) {
          started = true;
          HelperFunctions.showMessage(
            context,
            '${state.message}',
            Colors.green,
          );
        }
      },
      builder: (context, state) {
        switch (state.status) {
          case LedgerStatus.success:
            _selectedPeriod = state.ledgerReport!.period!;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
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

                              if (currentPeriodName.startsWith('Y')) {
                                // Format: Y2025
                                yearStr = currentPeriodName.substring(1);
                                year =
                                    int.tryParse(yearStr) ??
                                    DateTime.now().year;
                              } else if (currentPeriodName.contains('q')) {
                                // Format: Y2025q1
                                yearStr = currentPeriodName.substring(1, 5);
                                year =
                                    int.tryParse(yearStr) ??
                                    DateTime.now().year;
                              } else if (currentPeriodName.contains('m')) {
                                // Format: Y2025m01
                                yearStr = currentPeriodName.substring(1, 5);
                                year =
                                    int.tryParse(yearStr) ??
                                    DateTime.now().year;
                              }

                              // Go to previous year
                              int previousYear = year - 1;

                              // Check if the previous year exists in available periods
                              bool yearExists = _checkYearExists(
                                previousYear,
                                state.timePeriods,
                              );

                              if (!yearExists) {
                                // Show message if year doesn't exist
                                HelperFunctions.showMessage(
                                  context,
                                  _local.dataForYearNotAvailable(
                                    previousYear.toString(),
                                  ),
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
                                int quarterIndex = currentPeriodName.indexOf(
                                  'q',
                                );
                                String quarter = currentPeriodName.substring(
                                  quarterIndex + 1,
                                );
                                newPeriodName = 'Y$previousYear${'q$quarter'}';
                              } else if (_selectedPeriod.periodType == 'M') {
                                // Extract month number
                                int monthIndex = currentPeriodName.indexOf('m');
                                String month = currentPeriodName.substring(
                                  monthIndex + 1,
                                );
                                newPeriodName = 'Y$previousYear${'m$month'}';
                              }

                              // Fetch data for the previous year
                              _ledgerBloc.add(
                                LedgerFetch(
                                  ReportType.summary,
                                  periodName: newPeriodName,
                                ),
                              );
                            },
                          ),
                          Text(
                            '${_local.year} ${_getYearFromPeriod(_selectedPeriod.periodName)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.arrow_forward),
                            tooltip: _local.nextYear,
                            onPressed: () {
                              // Extract the year from the period name
                              String currentPeriodName =
                                  _selectedPeriod.periodName;
                              String yearStr = '';
                              int year = 0;

                              if (currentPeriodName.startsWith('Y')) {
                                // Format: Y2025
                                yearStr = currentPeriodName.substring(1);
                                year =
                                    int.tryParse(yearStr) ??
                                    DateTime.now().year;
                              } else if (currentPeriodName.contains('q')) {
                                // Format: Y2025q1
                                yearStr = currentPeriodName.substring(1, 5);
                                year =
                                    int.tryParse(yearStr) ??
                                    DateTime.now().year;
                              } else if (currentPeriodName.contains('m')) {
                                // Format: Y2025m01
                                yearStr = currentPeriodName.substring(1, 5);
                                year =
                                    int.tryParse(yearStr) ??
                                    DateTime.now().year;
                              }

                              // Go to next year (but don't exceed current year)
                              int nextYear = year + 1;
                              int currentYear = DateTime.now().year;
                              if (nextYear > currentYear) {
                                nextYear = currentYear;
                              }

                              // Check if the next year exists in available periods
                              bool yearExists = _checkYearExists(
                                nextYear,
                                state.timePeriods,
                              );

                              if (!yearExists) {
                                // Show message if year doesn't exist
                                HelperFunctions.showMessage(
                                  context,
                                  _local.dataForYearNotAvailable(
                                    nextYear.toString(),
                                  ),
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
                                int quarterIndex = currentPeriodName.indexOf(
                                  'q',
                                );
                                String quarter = currentPeriodName.substring(
                                  quarterIndex + 1,
                                );
                                newPeriodName = 'Y$nextYear${'q$quarter'}';
                              } else if (_selectedPeriod.periodType == 'M') {
                                // Extract month number
                                int monthIndex = currentPeriodName.indexOf('m');
                                String month = currentPeriodName.substring(
                                  monthIndex + 1,
                                );
                                newPeriodName = 'Y$nextYear${'m$month'}';
                              }

                              // Fetch data for the next year
                              _ledgerBloc.add(
                                LedgerFetch(
                                  ReportType.summary,
                                  periodName: newPeriodName,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      Text(
                        '${_local.period} ${_selectedPeriod.periodName}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                BalanceSummaryListHeader(
                  _itemScrollController,
                  state.ledgerReport!,
                  isPhone(context),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      RefreshIndicator(
                        onRefresh: (() async => _ledgerBloc.add(
                          LedgerFetch(
                            ReportType.summary,
                            periodName: _selectedPeriod.periodName,
                          ),
                        )),
                        child: ScrollablePositionedList.builder(
                          key: const Key('listView'),
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: state.ledgerReport!.glAccounts.length + 1,
                          itemScrollController: _itemScrollController,
                          itemPositionsListener: _itemPositionsListener,
                          itemBuilder: (BuildContext context, int index) {
                            if (index == 0) {
                              return Column(
                                children: [
                                  Visibility(
                                    visible:
                                        state.ledgerReport!.glAccounts.isEmpty,
                                    child: Center(
                                      heightFactor: 20,
                                      child: Text(
                                        started
                                            ? _local.noBalanceSummaryFound
                                            : '',
                                        key: const Key('empty'),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }
                            index--;
                            return BalanceSummaryListItem(
                              glAccount: state.ledgerReport!.glAccounts[index],
                              index: index,
                            );
                          },
                        ),
                      ),
                      Positioned(
                        right: right,
                        bottom: bottom,
                        child: GestureDetector(
                          onPanUpdate: (details) {
                            setState(() {
                              right = right! - details.delta.dx;
                              bottom -= details.delta.dy;
                            });
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Only show buttons for period types that are not currently selected
                              // Year button
                              if (_selectedPeriod.periodType != 'Y')
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: FloatingActionButton(
                                    heroTag: 'yearButton',
                                    mini: true,
                                    backgroundColor: Colors.blue,
                                    child: Text(
                                      _local.yearLetter,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    onPressed: () => _ledgerBloc.add(
                                      LedgerFetch(
                                        ReportType.summary,
                                        periodName: _selectedPeriod.periodName
                                            .substring(0, 5),
                                      ),
                                    ),
                                  ),
                                ),
                              // Quarter button
                              if (_selectedPeriod.periodType != 'Q')
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: FloatingActionButton(
                                    heroTag: 'quarterButton',
                                    mini: true,
                                    backgroundColor: Colors.green,
                                    child: Text(
                                      _local.quarterLetter,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    onPressed: () {
                                      String currentQuarter = formatter.format(
                                        DateTime.now().month / 4 + 1,
                                      );
                                      _ledgerBloc.add(
                                        LedgerFetch(
                                          ReportType.summary,
                                          periodName:
                                              '${_selectedPeriod.periodName.substring(0, 5)}'
                                              'q$currentQuarter',
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              // Month button
                              if (_selectedPeriod.periodType != 'M')
                                FloatingActionButton(
                                  heroTag: 'monthButton',
                                  mini: true,
                                  backgroundColor: Colors.orange,
                                  child: Text(
                                    _local.monthLetter,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  onPressed: () => _ledgerBloc.add(
                                    LedgerFetch(
                                      ReportType.summary,
                                      periodName:
                                          '${_selectedPeriod.periodName.substring(0, 5)}'
                                          'm${formatter.format(DateTime.now().month)}',
                                    ),
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
          case LedgerStatus.failure:
            return FatalErrorForm(message: _local.getBalanceSummaryFail);
          default:
            return const LoadingIndicator();
        }
      },
    );
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
