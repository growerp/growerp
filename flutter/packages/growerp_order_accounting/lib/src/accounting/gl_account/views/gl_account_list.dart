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

class GlAccountList extends StatefulWidget {
  const GlAccountList({super.key});

  @override
  GlAccountsState createState() => GlAccountsState();
}

class GlAccountsState extends State<GlAccountList> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  late GlAccountBloc _glAccountBloc;
  late bool trialBalance;
  late int limit;
  late double bottom;
  double? right;
  String searchString = '';
  double currentScroll = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    trialBalance = false;
    limit = 20;
    _scrollController.addListener(_onScroll);
    _glAccountBloc = context.read<GlAccountBloc>()
      ..add(GlAccountFetch(refresh: true, limit: limit));
    bottom = 50;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = OrderAccountingLocalizations.of(context)!;
    final coreLocalizations = CoreLocalizations.of(context)!;
    bool isPhone = isAPhone(context);
    right = right ?? (isPhone ? 20 : 50);
    limit = (MediaQuery.of(context).size.height / 100).round();

    Widget tableView(List<GlAccount> glAccounts) {
      // Build rows for StyledDataTable
      final rows = glAccounts.asMap().entries.map((entry) {
        return getGlAccountListRow(
          context: context,
          glAccount: entry.value,
          index: entry.key,
        );
      }).toList();

      return StyledDataTable(
        columns: getGlAccountListColumns(context, localizations),
        rows: rows,
        isLoading: _isLoading && glAccounts.isEmpty,
        scrollController: _scrollController,
        rowHeight: isPhone ? 56 : 56,
        onRowTap: (index) {
          showDialog(
            barrierDismissible: true,
            context: context,
            builder: (BuildContext context) {
              return Dismissible(
                key: const Key('glAccountItem'),
                direction: DismissDirection.startToEnd,
                child: BlocProvider.value(
                  value: _glAccountBloc,
                  child: GlAccountDialog(glAccounts[index]),
                ),
              );
            },
          );
        },
      );
    }

    return BlocConsumer<GlAccountBloc, GlAccountState>(
      listener: (context, state) {
        if (state.status == GlAccountStatus.failure) {
          HelperFunctions.showMessage(context, '${state.message}', Colors.red);
        }
        if (state.status == GlAccountStatus.success) {
          HelperFunctions.showMessage(
            context,
            '${state.message}',
            Colors.green,
          );
        }
      },
      builder: (context, state) {
        // Update loading state
        _isLoading = state.status == GlAccountStatus.loading;

        switch (state.status) {
          case GlAccountStatus.failure:
            return Center(
              child: Text(
                '${localizations.fetchGlAccountFail} ${state.message}',
              ),
            );
          case GlAccountStatus.success:
            final glAccounts = state.glAccounts;

            // Restore scroll position
            if (glAccounts.isNotEmpty && _scrollController.hasClients) {
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
                  searchHint: localizations.searchGlAccountHint,
                  searchController: _searchController,
                  onSearchChanged: (value) {
                    searchString = value;
                    _glAccountBloc.add(
                      GlAccountFetch(
                        refresh: true,
                        searchString: value,
                        limit: limit,
                        trialBalance: trialBalance,
                      ),
                    );
                  },
                ),
                // Main content with StyledDataTable
                Expanded(
                  child: Stack(
                    children: [
                      RefreshIndicator(
                        onRefresh: () async => _glAccountBloc.add(
                          GlAccountFetch(
                            refresh: true,
                            limit: limit,
                            trialBalance: trialBalance,
                            searchString: searchString,
                          ),
                        ),
                        child: tableView(glAccounts),
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
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              FloatingActionButton(
                                heroTag: 'glAccountFiles',
                                key: const Key("upDownload"),
                                onPressed: () async {
                                  await showDialog(
                                    barrierDismissible: true,
                                    context: context,
                                    builder: (BuildContext context) {
                                      return BlocProvider.value(
                                        value: _glAccountBloc,
                                        child: const GlAccountFilesDialog(),
                                      );
                                    },
                                  );
                                },
                                tooltip: localizations.glAccountFiles,
                                child: const Icon(Icons.file_copy),
                              ),
                              const SizedBox(height: 10),
                              FloatingActionButton(
                                heroTag: "trialBalance",
                                key: const Key("tb"),
                                onPressed: () {
                                  bool refresh = false;
                                  if (trialBalance == false) {
                                    trialBalance = true;
                                    limit = 999;
                                  } else {
                                    trialBalance = false;
                                    refresh = true;
                                    limit = 20;
                                  }
                                  _glAccountBloc.add(
                                    GlAccountFetch(
                                      trialBalance: trialBalance,
                                      limit: limit,
                                      refresh: refresh,
                                      searchString: searchString,
                                    ),
                                  );
                                },
                                tooltip: localizations.trialBalance,
                                child: Text(
                                  localizations.tb,
                                  style: trialBalance
                                      ? const TextStyle(
                                          decoration:
                                              TextDecoration.lineThrough,
                                        )
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 10),
                              FloatingActionButton(
                                heroTag: "addNew",
                                key: const Key("addNew"),
                                onPressed: () async {
                                  await showDialog(
                                    barrierDismissible: true,
                                    context: context,
                                    builder: (BuildContext context) {
                                      return BlocProvider.value(
                                        value: _glAccountBloc,
                                        child: GlAccountDialog(GlAccount()),
                                      );
                                    },
                                  );
                                },
                                tooltip: coreLocalizations.addNew,
                                child: const Icon(Icons.add),
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
      _glAccountBloc.add(
        GlAccountFetch(
          trialBalance: trialBalance,
          limit: limit,
          searchString: searchString,
        ),
      );
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }
}
