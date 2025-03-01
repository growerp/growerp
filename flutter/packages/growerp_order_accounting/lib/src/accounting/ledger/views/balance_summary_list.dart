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

import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
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
  final TextEditingController _periodSearchBoxController =
      TextEditingController();
  NumberFormat formatter = NumberFormat("00");
  late bool search;
  late LedgerBloc _ledgerBloc;
  late bool started;
  late TimePeriod _selectedPeriod;

  @override
  void initState() {
    super.initState();
    started = false;
    search = false;
    _selectedPeriod =
        TimePeriod(periodName: 'Y${DateTime.now().year}', periodType: 'Y');
    _ledgerBloc = context.read<LedgerBloc>()
      ..add(LedgerFetch(ReportType.summary,
          periodName: _selectedPeriod.periodName));
    _selectedPeriod =
        TimePeriod(periodName: 'Y${DateTime.now().year}', periodType: 'Y');
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LedgerBloc, LedgerState>(
        listenWhen: (previous, current) =>
            previous.status == LedgerStatus.loading,
        listener: (context, state) {
          if (state.status == LedgerStatus.failure) {
            HelperFunctions.showMessage(
                context, '${state.message}', Colors.red);
          }
          if (state.status == LedgerStatus.success) {
            started = true;
            HelperFunctions.showMessage(
                context, '${state.message}', Colors.green);
          }
        },
        builder: (context, state) {
          switch (state.status) {
            case LedgerStatus.success:
              _selectedPeriod = state.ledgerReport!.period!;
              return Column(
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.end, children: [
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
                                const InputDecoration(labelText: 'Time period'),
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
                            labelText: 'Time period',
                          ),
                        ),
                        itemAsString: (TimePeriod? u) =>
                            " ${u!.periodName}", // invisible char for test
                        onChanged: (TimePeriod? newValue) {
                          setState(() => _selectedPeriod = newValue!);
                          _ledgerBloc.add(LedgerFetch(ReportType.summary,
                              periodName: newValue!.periodName));
                        },
                        items: state.timePeriods,
                        validator: (value) =>
                            value == null ? 'field required' : null,
                      ),
                    ),
                    if (_selectedPeriod.periodType != 'Y')
                      OutlinedButton(
                          child: const Text('Y'),
                          onPressed: () => _ledgerBloc.add(LedgerFetch(
                              ReportType.summary,
                              periodName:
                                  _selectedPeriod.periodName.substring(0, 5)))),
                    if (_selectedPeriod.periodType != 'Q')
                      OutlinedButton(
                          child: const Text('Q'),
                          onPressed: () {
                            String currentQuarter =
                                formatter.format(DateTime.now().month / 4 + 1);
                            _ledgerBloc.add(LedgerFetch(ReportType.summary,
                                periodName:
                                    '${_selectedPeriod.periodName.substring(0, 5)}'
                                    'q$currentQuarter'));
                          }),
                    if (_selectedPeriod.periodType != 'M')
                      OutlinedButton(
                          child: const Text('M'),
                          onPressed: () => _ledgerBloc.add(LedgerFetch(
                              ReportType.summary,
                              periodName:
                                  '${_selectedPeriod.periodName.substring(0, 5)}'
                                  'm${formatter.format(DateTime.now().month)}'))),
                  ]),
                  BalanceSummaryListHeader(_itemScrollController,
                      state.ledgerReport!, isPhone(context)),
                  Expanded(
                    child: RefreshIndicator(
                        onRefresh: (() async => _ledgerBloc.add(LedgerFetch(
                            ReportType.summary,
                            periodName: _selectedPeriod.periodName))),
                        child: ScrollablePositionedList.builder(
                          key: const Key('listView'),
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: state.ledgerReport!.glAccounts.length + 1,
                          itemScrollController: _itemScrollController,
                          itemPositionsListener: _itemPositionsListener,
                          itemBuilder: (BuildContext context, int index) {
                            if (index == 0) {
                              return Column(children: [
                                Visibility(
                                    visible:
                                        state.ledgerReport!.glAccounts.isEmpty,
                                    child: Center(
                                        heightFactor: 20,
                                        child: Text(
                                            started
                                                ? 'No balanceSummary.accountList found'
                                                : '',
                                            key: const Key('empty'),
                                            textAlign: TextAlign.center)))
                              ]);
                            }
                            index--;
                            return BalanceSummaryListItem(
                                glAccount:
                                    state.ledgerReport!.glAccounts[index],
                                index: index);
                          },
                        )),
                  ),
                ],
              );
            case LedgerStatus.failure:
              return const FatalErrorForm(
                  message: 'failed to get Balance Summary');
            default:
              return const LoadingIndicator();
          }
        });
  }
}
