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

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_order_accounting/l10n/generated/order_accounting_localizations.dart';

import '../blocs/cash_book_bloc.dart';
import '../widgets/cash_book_list_styled_data.dart';
import 'cash_book_dialog.dart';

/// Simplified cash in / cash out list: every ledger transaction on the
/// cash & bank account, with a direction filter and totals of the loaded rows.
class CashBookList extends StatefulWidget {
  const CashBookList({super.key});

  @override
  CashBookListState createState() => CashBookListState();
}

class CashBookListState extends State<CashBookList> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  late CashBookBloc _cashBookBloc;
  late double bottom;
  double? right;
  String searchString = '';
  bool? isIncome; // null = all
  double currentScroll = 0;
  bool _isLoading = true;
  late String currencyId;

  @override
  void initState() {
    super.initState();
    _cashBookBloc = context.read<CashBookBloc>()
      ..add(const CashBookFetch(refresh: true))
      ..add(const CashBookCategoriesFetch());
    currencyId =
        context
            .read<AuthBloc>()
            .state
            .authenticate
            ?.company
            ?.currency
            ?.currencyId ??
        'USD';
    _scrollController.addListener(_onScroll);
    bottom = 50;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _searchFocusNode.requestFocus(),
    );
  }

  Future<void> _openDialog(CashBookEntry entry) async {
    await showDialog(
      barrierDismissible: true,
      context: context,
      builder: (BuildContext context) => BlocProvider.value(
        value: _cashBookBloc,
        child: CashBookDialog(entry),
      ),
    );
    _searchFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = OrderAccountingLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    bool isPhone = isAPhone(context);
    right = right ?? (isPhone ? 20 : 50);

    Widget totalsBar(List<CashBookEntry> entries) {
      Decimal sum(bool income) => entries
          .where((e) => e.isIncome == income)
          .fold(Decimal.zero, (t, e) => t + (e.amount ?? Decimal.zero));
      final totalIn = sum(true), totalOut = sum(false);
      Widget total(String label, Decimal value, Color color, String key) =>
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: '$label '),
                TextSpan(
                  text: value.currency(currencyId: currencyId),
                  style: TextStyle(color: color, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            key: Key(key),
          );
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Wrap(
          spacing: 20,
          children: [
            total(
              localizations.cashTotalIn,
              totalIn,
              colorScheme.success,
              'totalIn',
            ),
            total(
              localizations.cashTotalOut,
              totalOut,
              colorScheme.danger,
              'totalOut',
            ),
            total(
              localizations.cashNet,
              totalIn - totalOut,
              colorScheme.onSurface,
              'totalNet',
            ),
          ],
        ),
      );
    }

    Widget tableView(List<CashBookEntry> entries) {
      if (!_isLoading && entries.isEmpty) {
        return Center(child: Text(localizations.noCashBookEntries));
      }
      final rows = entries.asMap().entries.map((entry) {
        return getCashBookListRow(
          context: context,
          entry: entry.value,
          index: entry.key,
          currencyId: currencyId,
        );
      }).toList();
      return StyledDataTable(
        columns: getCashBookListColumns(context),
        rows: rows,
        isLoading: _isLoading && entries.isEmpty,
        scrollController: _scrollController,
        rowHeight: isPhone ? 64 : 56,
        onRowTap: (index) => _openDialog(entries[index]),
      );
    }

    return BlocConsumer<CashBookBloc, CashBookState>(
      listener: (context, state) {
        if (state.status == CashBookStatus.failure) {
          HelperFunctions.showMessage(context, '${state.message}', Colors.red);
          _searchFocusNode.requestFocus();
        }
        if (state.status == CashBookStatus.success && state.message != null) {
          HelperFunctions.showMessage(context, switch (state.message) {
            'cashBookAddSuccess' => localizations.cashBookAddSuccess,
            'cashBookUpdateSuccess' => localizations.cashBookUpdateSuccess,
            'cashBookDeleteSuccess' => localizations.cashBookDeleteSuccess,
            _ => state.message!,
          }, Colors.green);
          _searchFocusNode.requestFocus();
        }
      },
      builder: (context, state) {
        _isLoading = state.status == CashBookStatus.initial;
        if (state.status == CashBookStatus.initial) {
          return const Center(child: LoadingIndicator());
        }
        final entries = state.entries;

        if (entries.isNotEmpty && _scrollController.hasClients) {
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
            ListFilterBar(
              searchHint: localizations.searchCashBookHint,
              searchController: _searchController,
              focusNode: _searchFocusNode,
              onSearchChanged: (value) {
                searchString = value;
                _cashBookBloc.add(
                  CashBookSearchChanged(
                    searchString: value,
                    isIncome: isIncome,
                  ),
                );
              },
              filters: [
                SegmentedButton<bool?>(
                  key: const Key('directionFilter'),
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: null,
                      label: Text(
                        localizations.cashAll,
                        key: const Key('filterAll'),
                      ),
                    ),
                    ButtonSegment(
                      value: true,
                      label: Text(
                        localizations.cashIn,
                        key: const Key('filterIn'),
                      ),
                    ),
                    ButtonSegment(
                      value: false,
                      label: Text(
                        localizations.cashOut,
                        key: const Key('filterOut'),
                      ),
                    ),
                  ],
                  selected: {isIncome},
                  onSelectionChanged: (selection) {
                    setState(() => isIncome = selection.first);
                    _cashBookBloc.add(
                      CashBookFetch(
                        refresh: true,
                        searchString: searchString,
                        isIncome: isIncome,
                      ),
                    );
                  },
                ),
              ],
            ),
            totalsBar(entries),
            Expanded(
              child: Stack(
                children: [
                  RefreshIndicator(
                    onRefresh: () async => _cashBookBloc.add(
                      CashBookFetch(
                        refresh: true,
                        searchString: searchString,
                        isIncome: isIncome,
                      ),
                    ),
                    child: tableView(entries),
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
                        heroTag: "cashBookAdd",
                        onPressed: () => _openDialog(
                          CashBookEntry(isIncome: isIncome ?? true),
                        ),
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
      },
    );
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    currentScroll = _scrollController.offset;
    if (_isBottom && !_cashBookBloc.state.hasReachedMax) {
      _cashBookBloc.add(
        CashBookFetch(searchString: searchString, isIncome: isIncome),
      );
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    return _scrollController.offset >= (maxScroll * 0.9);
  }
}
