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
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../accounting.dart';

class BalanceSummaryListForm extends StatelessWidget {
  const BalanceSummaryListForm({super.key});

  @override
  Widget build(BuildContext context) => RepositoryProvider(
      create: (context) => AccountingAPIRepository(
          context.read<AuthBloc>().state.authenticate!.apiKey!),
      child: BlocProvider<LedgerBloc>(
          create: (BuildContext context) => LedgerBloc(AccountingAPIRepository(
              context.read<AuthBloc>().state.authenticate!.apiKey!)),
          child: const BalanceSummaryList()));
}

class BalanceSummaryList extends StatefulWidget {
  const BalanceSummaryList({super.key});

  @override
  BalanceSummaryListState createState() => BalanceSummaryListState();
}

class BalanceSummaryListState extends State<BalanceSummaryList> {
  final _itemScrollController = ItemScrollController();
  final _itemPositionsListener = ItemPositionsListener.create();
  late bool search;
  late LedgerBloc _balanceSummaryBloc;
  late bool started;
  late String periodName;

  @override
  void initState() {
    super.initState();
    started = false;
    search = false;
    _balanceSummaryBloc = context.read<LedgerBloc>();
    periodName = 'Y${DateTime.now().year}';
    _balanceSummaryBloc
        .add(LedgerFetch(ReportType.summary, periodName: periodName));
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
              var next = 'Y${int.parse(periodName.substring(1)) + 1}';
              var prev = 'Y${int.parse(periodName.substring(1)) - 1}';
              return Scaffold(
                  floatingActionButton: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (state.timePeriods
                            .any((item) => item.periodName == next))
                          FloatingActionButton.extended(
                              heroTag: 'next',
                              key: const Key("next"),
                              onPressed: () async {
                                periodName = next;
                                _balanceSummaryBloc.add(LedgerFetch(
                                    ReportType.summary,
                                    periodName: periodName));
                                periodName = next;
                              },
                              tooltip: 'Next Year',
                              icon: const Icon(Icons.arrow_right),
                              label: Text(next)),
                        const SizedBox(height: 10),
                        if (state.timePeriods
                            .any((item) => item.periodName == prev))
                          FloatingActionButton.extended(
                              heroTag: 'previous',
                              key: const Key("previous"),
                              onPressed: () async {
                                periodName = prev;
                                _balanceSummaryBloc.add(LedgerFetch(
                                    ReportType.summary,
                                    periodName: periodName));
                                periodName = prev;
                              },
                              tooltip: 'Previous year',
                              icon: const Icon(Icons.arrow_left),
                              label: Text(prev)),
                      ]),
                  body: RefreshIndicator(
                      onRefresh: (() async => context.read<LedgerBloc>().add(
                          LedgerFetch(ReportType.summary,
                              periodName: periodName))),
                      child: ScrollablePositionedList.builder(
                        key: const Key('listView'),
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: state.ledgerReport!.glAccounts.length + 1,
                        itemScrollController: _itemScrollController,
                        itemPositionsListener: _itemPositionsListener,
                        itemBuilder: (BuildContext context, int index) {
                          if (index == 0) {
                            return Column(children: [
                              BalanceSummaryListHeader(
                                  _itemScrollController, state.ledgerReport!),
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
                              glAccount: state.ledgerReport!.glAccounts[index],
                              index: index);
                        },
                      )));
            case LedgerStatus.failure:
              return const FatalErrorForm(
                  message: 'failed to get Balance Summary');
            default:
              return const LoadingIndicator();
          }
        });
  }
}
