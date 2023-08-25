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

import 'package:growerp_core/growerp_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_order_accounting/growerp_order_accounting.dart';
import '../../accounting.dart';

class LedgerJournalListForm extends StatelessWidget {
  const LedgerJournalListForm({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
      create: (BuildContext context) => LedgerJournalBloc(
          AccountingAPIRepository(
              context.read<AuthBloc>().state.authenticate!.apiKey!))
        ..add(const LedgerJournalFetch()),
      child: const LedgerJournalList());
}

class LedgerJournalList extends StatefulWidget {
  const LedgerJournalList({super.key});

  @override
  LedgerJournalsState createState() => LedgerJournalsState();
}

class LedgerJournalsState extends State<LedgerJournalList> {
  final ScrollController _scrollController = ScrollController();
  late LedgerJournalBloc _ledgerJournalBloc;

  @override
  void initState() {
    super.initState();
    _ledgerJournalBloc = context.read<LedgerJournalBloc>();
    _scrollController.addListener(_onScroll);
  }

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<LedgerJournalBloc, LedgerJournalState>(
          listener: (context, state) {
        if (state.status == LedgerJournalStatus.failure) {
          HelperFunctions.showMessage(context, '${state.message}', Colors.red);
        }
        if (state.status == LedgerJournalStatus.success) {
          HelperFunctions.showMessage(
              context, '${state.message}', Colors.green);
        }
      }, builder: (context, state) {
        switch (state.status) {
          case LedgerJournalStatus.failure:
            return Center(
                child:
                    Text('failed to fetch ledgerJournals: ${state.message}'));
          case LedgerJournalStatus.success:
            return Scaffold(
                floatingActionButton: FloatingActionButton(
                    key: const Key("addNew"),
                    onPressed: () async {
                      await showDialog(
                          barrierDismissible: true,
                          context: context,
                          builder: (BuildContext context) => BlocProvider.value(
                              value: _ledgerJournalBloc,
                              child: LedgerJournalDialog(LedgerJournal())));
                    },
                    tooltip: 'Add New',
                    child: const Icon(Icons.add)),
                body: Column(children: [
                  const LedgerJournalListHeader(),
                  Expanded(
                      child: RefreshIndicator(
                          onRefresh: (() async => _ledgerJournalBloc
                              .add(const LedgerJournalFetch(refresh: true))),
                          child: ListView.builder(
                              key: const Key('listView'),
                              shrinkWrap: true,
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: state.hasReachedMax
                                  ? state.ledgerJournals.length + 1
                                  : state.ledgerJournals.length + 2,
                              controller: _scrollController,
                              itemBuilder: (BuildContext context, int index) {
                                if (index == 0) {
                                  return Visibility(
                                      visible: state.ledgerJournals.isEmpty,
                                      child: const Center(
                                          heightFactor: 20,
                                          child: Text(
                                              'No active ledgerJournals found',
                                              key: Key('empty'),
                                              textAlign: TextAlign.center)));
                                }
                                index--;
                                return index >= state.ledgerJournals.length
                                    ? const BottomLoader()
                                    : Dismissible(
                                        key: const Key('ledgerJournalItem'),
                                        direction: DismissDirection.startToEnd,
                                        child: LedgerJournalListItem(
                                            ledgerJournal:
                                                state.ledgerJournals[index],
                                            index: index));
                              })))
                ]));
          default:
            return const Center(child: CircularProgressIndicator());
        }
      });

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) _ledgerJournalBloc.add(const LedgerJournalFetch());
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }
}
