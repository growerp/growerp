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
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_order_accounting/growerp_order_accounting.dart';

class LedgerJournalList extends StatefulWidget {
  const LedgerJournalList({super.key});

  @override
  LedgerJournalsState createState() => LedgerJournalsState();
}

class LedgerJournalsState extends State<LedgerJournalList> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  late LedgerJournalBloc _ledgerJournalBloc;
  late double bottom;
  double? right;
  String searchString = '';
  double currentScroll = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _ledgerJournalBloc = context.read<LedgerJournalBloc>()
      ..add(const LedgerJournalFetch(refresh: true));
    _scrollController.addListener(_onScroll);
    bottom = 50;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = OrderAccountingLocalizations.of(context)!;
    bool isPhone = isAPhone(context);
    right = right ?? (isPhone ? 20 : 50);

    Widget tableView(List<LedgerJournal> ledgerJournals) {
      // Build rows for StyledDataTable
      final rows = ledgerJournals.asMap().entries.map((entry) {
        return getLedgerJournalListRow(
          context: context,
          ledgerJournal: entry.value,
          index: entry.key,
          ledgerJournalBloc: _ledgerJournalBloc,
        );
      }).toList();

      return StyledDataTable(
        columns: getLedgerJournalListColumns(context),
        rows: rows,
        isLoading: _isLoading && ledgerJournals.isEmpty,
        scrollController: _scrollController,
        rowHeight: isPhone ? 56 : 56,
        onRowTap: (index) {
          showDialog(
            barrierDismissible: true,
            context: context,
            builder: (BuildContext context) {
              return Dismissible(
                key: const Key('ledgerJournalItem'),
                direction: DismissDirection.startToEnd,
                child: BlocProvider.value(
                  value: _ledgerJournalBloc,
                  child: LedgerJournalDialog(ledgerJournals[index]),
                ),
              );
            },
          );
        },
      );
    }

    return BlocConsumer<LedgerJournalBloc, LedgerJournalState>(
      listener: (context, state) {
        if (state.status == LedgerJournalStatus.failure) {
          HelperFunctions.showMessage(context, '${state.message}', Colors.red);
        }
        if (state.status == LedgerJournalStatus.success) {
          HelperFunctions.showMessage(
            context,
            '${state.message}',
            Colors.green,
          );
        }
      },
      builder: (context, state) {
        // Update loading state (initial is considered loading)
        _isLoading = state.status == LedgerJournalStatus.initial;

        switch (state.status) {
          case LedgerJournalStatus.failure:
            return Center(
              child: Text(
                '${localizations.getLedgerJournalFail} ${state.message}',
              ),
            );
          case LedgerJournalStatus.success:
            final ledgerJournals = state.ledgerJournals;

            // Restore scroll position
            if (ledgerJournals.isNotEmpty && _scrollController.hasClients) {
              Future.delayed(const Duration(milliseconds: 100), () {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.jumpTo(currentScroll);
                  }
                });
              });
            }

            return Column(
              children: [
                // Filter bar with search
                ListFilterBar(
                  searchHint: 'Search in ID, name...',
                  searchController: _searchController,
                  onSearchChanged: (value) {
                    searchString = value;
                    _ledgerJournalBloc.add(
                      LedgerJournalFetch(refresh: true, searchString: value),
                    );
                  },
                ),
                // Main content with StyledDataTable
                Expanded(
                  child: Stack(
                    children: [
                      RefreshIndicator(
                        onRefresh: () async => _ledgerJournalBloc.add(
                          LedgerJournalFetch(
                            refresh: true,
                            searchString: searchString,
                          ),
                        ),
                        child: tableView(ledgerJournals),
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
                          child: FloatingActionButton(
                            key: const Key("addNew"),
                            heroTag: "ledgerJournalAdd",
                            onPressed: () async {
                              await showDialog(
                                barrierDismissible: true,
                                context: context,
                                builder: (BuildContext context) =>
                                    BlocProvider.value(
                                      value: _ledgerJournalBloc,
                                      child: LedgerJournalDialog(
                                        LedgerJournal(),
                                      ),
                                    ),
                              );
                            },
                            tooltip: localizations.addNew,
                            child: const Icon(Icons.add),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          default:
            return const Center(child: LoadingIndicator());
        }
      },
    );
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    currentScroll = _scrollController.offset;
    if (_isBottom) {
      _ledgerJournalBloc.add(LedgerJournalFetch(searchString: searchString));
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }
}
