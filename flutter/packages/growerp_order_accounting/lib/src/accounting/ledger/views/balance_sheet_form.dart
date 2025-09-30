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

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_simple_treeview/flutter_simple_treeview.dart';
import 'package:intl/intl.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

import '../../accounting.dart';

class BalanceSheetForm extends StatelessWidget {
  // ignore: use_super_parameters
  const BalanceSheetForm({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LedgerBloc(context.read<RestClient>()),
      child: const BalanceSheetListForm(),
    );
  }
}

class BalanceSheetListForm extends StatefulWidget {
  const BalanceSheetListForm({super.key});

  @override
  BalanceSheetFormState createState() => BalanceSheetFormState();
}

class BalanceSheetFormState extends State<BalanceSheetListForm> {
  NumberFormat formatter = NumberFormat("00");
  TreeController? _controller;
  Iterable<TreeNode> _nodes = [];
  late int level;
  late LedgerBloc _ledgerBloc;
  late bool expanded;
  var assets = Decimal.parse('0');
  var equity = Decimal.parse('0');
  var distribution = Decimal.parse('0');
  var liability = Decimal.parse('0');
  var income = Decimal.parse('0');
  late TimePeriod _selectedPeriod;
  late double bottom;
  double? right;

  @override
  void initState() {
    super.initState();
    _controller = TreeController(allNodesExpanded: false);
    _ledgerBloc = context.read<LedgerBloc>();
    _selectedPeriod = TimePeriod(
      periodName: 'Y${DateTime.now().year}',
      periodType: 'Y',
    );
    _ledgerBloc.add(
      LedgerFetch(ReportType.sheet, periodName: _selectedPeriod.periodName),
    );
    level = 0;
    expanded = false;
    _controller!.expandNode(const Key('ASSETS'));
    bottom = 50;
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = ResponsiveBreakpoints.of(context).isMobile;
    right = right ?? (isPhone ? 20 : 50);
    //convert balanceSheetDetail list into TreeNodes
    Iterable<TreeNode> convert(List<GlAccount> glAccounts) {
      // convert single leaf/balanceSheetDetail
      TreeNode getTreeNode(GlAccount glAccount) {
        // recursive function
        if (glAccount.accountCode != null &&
            glAccount.accountCode != 'INCOME') {
          final result = TreeNode(
            key: ValueKey(glAccount.accountCode),
            content: Row(
              children: [
                SizedBox(
                  width: (isPhone ? 210 : 400) - (level * 10),
                  child: Text(
                    "${int.tryParse(glAccount.accountCode!.substring(0, 2)) == null ? '' : glAccount.accountCode} ${glAccount.accountName}",
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: Text(
                    Constant.numberFormat.format(
                      (glAccount.postedBalance ?? Decimal.zero).toDouble(),
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
            children: glAccount.children.map(getTreeNode).toList(),
          );
          return result;
        } else {
          return TreeNode();
        }
      }

      // main: do the actual conversion
      final treeNodes = <TreeNode>[];
      for (final element in glAccounts) {
        if (element.accountCode == 'EQUITY') {
          equity = element.postedBalance ?? Decimal.zero;
        }
        if (element.accountCode == 'DISTRIBUTION') {
          distribution = element.postedBalance ?? Decimal.zero;
        }
        if (element.accountCode == 'ASSET') {
          assets = element.postedBalance ?? Decimal.zero;
        }
        if (element.accountCode == 'LIABILITY') {
          liability = element.postedBalance ?? Decimal.zero;
        }
        if (element.accountCode == 'INCOME') {
          income = element.postedBalance ?? Decimal.zero;
        }
        treeNodes.add(getTreeNode(element));
      }
      final Iterable<TreeNode> iterable = treeNodes;
      return iterable;
    }

    return BlocConsumer<LedgerBloc, LedgerState>(
      listener: (context, state) {
        if (state.status == LedgerStatus.failure) {
          HelperFunctions.showMessage(context, '${state.message}', Colors.red);
        }
      },
      builder: (context, state) {
        switch (state.status) {
          case LedgerStatus.success:
            _selectedPeriod = state.ledgerReport!.period!;
            _nodes = convert(state.ledgerReport!.glAccounts);
            List totals = [
              {"text": _local.totalAssets, "amount": assets},
              {
                "text": _local.totalEquityAndDistribution,
                "amount": equity + distribution,
              },
              {
                "text": _local.totalLiabilityAndEquity,
                "amount": liability + equity,
              },
              {"text": _local.totalUnbookedNetIncome, "amount": income},
              {
                "text": _local.liabilityEquityUnbookedNetIncome,
                "amount": liability + equity + income,
              },
            ];
            return Stack(
              children: [
                RefreshIndicator(
                  onRefresh: (() async => context.read<LedgerBloc>().add(
                        LedgerFetch(
                          ReportType.sheet,
                          periodName: _selectedPeriod.periodName,
                        ),
                      )),
                  child: ListView(
                    children: <Widget>[
                      const SizedBox(height: 10),
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
                                  tooltip: _local.previousYear,
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
                                    } else if (currentPeriodName.contains(
                                      'q',
                                    )) {
                                      // Format: Y2025q1
                                      yearStr = currentPeriodName.substring(
                                        1,
                                        5,
                                      );
                                      year =
                                          int.tryParse(yearStr) ??
                                          DateTime.now().year;
                                    } else if (currentPeriodName.contains(
                                      'm',
                                    )) {
                                      // Format: Y2025m01
                                      yearStr = currentPeriodName.substring(
                                        1,
                                        5,
                                      );
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
                                            previousYear.toString()),
                                        Colors.orange,
                                      );
                                      return;
                                    }

                                    // Determine the new period name based on current period type
                                    String newPeriodName = '';
                                    if (_selectedPeriod.periodType == 'Y') {
                                      newPeriodName = 'Y$previousYear';
                                    } else if (_selectedPeriod.periodType ==
                                        'Q') {
                                      // Extract quarter number
                                      int quarterIndex = currentPeriodName
                                          .indexOf('q');
                                      String quarter = currentPeriodName
                                          .substring(quarterIndex + 1);
                                      newPeriodName =
                                          'Y$previousYear${'q$quarter'}';
                                    } else if (_selectedPeriod.periodType ==
                                        'M') {
                                      // Extract month number
                                      int monthIndex = currentPeriodName
                                          .indexOf('m');
                                      String month = currentPeriodName
                                          .substring(monthIndex + 1);
                                      newPeriodName =
                                          'Y$previousYear${'m$month'}';
                                    }

                                    // Fetch data for the previous year
                                    _ledgerBloc.add(
                                      LedgerFetch(
                                        ReportType.sheet,
                                        periodName: newPeriodName,
                                      ),
                                    );
                                  },
                                ),
                                Text(
                                  '${_local.year} ${_getYearFromPeriod(_selectedPeriod.periodName)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
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
                                    } else if (currentPeriodName.contains(
                                      'q',
                                    )) {
                                      // Format: Y2025q1
                                      yearStr = currentPeriodName.substring(
                                        1,
                                        5,
                                      );
                                      year =
                                          int.tryParse(yearStr) ??
                                          DateTime.now().year;
                                    } else if (currentPeriodName.contains(
                                      'm',
                                    )) {
                                      // Format: Y2025m01
                                      yearStr = currentPeriodName.substring(
                                        1,
                                        5,
                                      );
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
                                            nextYear.toString()),
                                        Colors.orange,
                                      );
                                      return;
                                    }

                                    // Determine the new period name based on current period type
                                    String newPeriodName = '';
                                    if (_selectedPeriod.periodType == 'Y') {
                                      newPeriodName = 'Y$nextYear';
                                    } else if (_selectedPeriod.periodType ==
                                        'Q') {
                                      // Extract quarter number
                                      int quarterIndex = currentPeriodName
                                          .indexOf('q');
                                      String quarter = currentPeriodName
                                          .substring(quarterIndex + 1);
                                      newPeriodName =
                                          'Y$nextYear${'q$quarter'}';
                                    } else if (_selectedPeriod.periodType ==
                                        'M') {
                                      // Extract month number
                                      int monthIndex = currentPeriodName
                                          .indexOf('m');
                                      String month = currentPeriodName
                                          .substring(monthIndex + 1);
                                      newPeriodName = 'Y$nextYear${'m$month'}';
                                    }

                                    // Fetch data for the next year
                                    _ledgerBloc.add(
                                      LedgerFetch(
                                        ReportType.sheet,
                                        periodName: newPeriodName,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Text(
                                  '${_local.period} ${_selectedPeriod.periodName}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                if (!expanded)
                                  OutlinedButton(
                                    child: Text(_local.expand),
                                    onPressed: () => setState(() {
                                      expanded = !expanded;
                                      _controller!.expandAll();
                                    }),
                                  ),
                                if (expanded)
                                  OutlinedButton(
                                    child: Text(_local.collapse),
                                    onPressed: () => setState(() {
                                      expanded = !expanded;
                                      _controller!.collapseAll();
                                    }),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const SizedBox(width: 20),
                          SizedBox(
                            width: isPhone ? 220 : 410,
                            child: Text(_local.glAccountIdAndName),
                          ),
                          SizedBox(
                            width: 100,
                            child: Text(_local.postedHeader,
                                textAlign: TextAlign.right),
                          ),
                        ],
                      ),
                      const Divider(),
                      TreeView(
                        treeController: _controller,
                        nodes: _nodes as List<TreeNode>,
                        indent: 10,
                      ),
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.all(30.0),
                        child: Table(
                          columnWidths: const <int, TableColumnWidth>{
                            0: FixedColumnWidth(250),
                            1: FixedColumnWidth(100),
                          },
                          defaultVerticalAlignment:
                              TableCellVerticalAlignment.middle,
                          children: <TableRow>[
                            for (var item in totals)
                              TableRow(
                                children: <Widget>[
                                  TableCell(child: Text(item["text"])),
                                  TableCell(
                                    child: Text(
                                      Constant.numberFormat.format(
                                        (item["amount"] as Decimal).toDouble(),
                                      ),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
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
                                  ReportType.sheet,
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
                                    ReportType.sheet,
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
                                ReportType.sheet,
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
            );
          case LedgerStatus.failure:
            return FatalErrorForm(message: _local.getBalanceSheetFail);
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
