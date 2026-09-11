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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_order_accounting/l10n/generated/order_accounting_localizations.dart';

import '../blocs/cash_book_category_bloc.dart';
import '../widgets/cash_book_category_list_styled_data.dart';
import 'cash_book_category_dialog.dart';

/// The categories the cash book offers. A company starts with a short default
/// selection out of its ledger accounts; here it is switched on or off and
/// categories of its own can be added.
class CashBookCategoryList extends StatefulWidget {
  const CashBookCategoryList({super.key});

  @override
  CashBookCategoryListState createState() => CashBookCategoryListState();
}

class CashBookCategoryListState extends State<CashBookCategoryList> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  late CashBookCategoryBloc _categoryBloc;
  bool isIncome = false; // start on the expense side: the longest list
  String searchString = '';
  late double bottom;
  double? right;

  @override
  void initState() {
    super.initState();
    _categoryBloc = context.read<CashBookCategoryBloc>()
      ..add(const CashBookCategoryFetch(refresh: true));
    bottom = 50;
  }

  Future<void> _openDialog(GlAccount? category) async {
    await showDialog(
      barrierDismissible: true,
      context: context,
      builder: (BuildContext context) => BlocProvider.value(
        value: _categoryBloc,
        child: CashBookCategoryDialog(category, isIncome: isIncome),
      ),
    );
  }

  /// in use first, then by name: the ones in daily use are at the top
  List<GlAccount> _visible(CashBookCategoryState state) {
    final list =
        List<GlAccount>.from(
              isIncome ? state.incomeCategories : state.expenseCategories,
            )
            .where(
              (c) =>
                  searchString.isEmpty ||
                  (c.accountName ?? '').toLowerCase().contains(
                    searchString.toLowerCase(),
                  ),
            )
            .toList();
    list.sort((a, b) {
      if ((a.isUsed ?? false) != (b.isUsed ?? false)) {
        return (a.isUsed ?? false) ? -1 : 1;
      }
      return (a.accountName ?? '').compareTo(b.accountName ?? '');
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = OrderAccountingLocalizations.of(context)!;
    bool isPhone = isAPhone(context);
    right = right ?? (isPhone ? 20 : 50);

    return BlocConsumer<CashBookCategoryBloc, CashBookCategoryState>(
      listener: (context, state) {
        if (state.status == CashBookCategoryStatus.failure) {
          HelperFunctions.showMessage(context, '${state.message}', Colors.red);
        }
        if (state.status == CashBookCategoryStatus.success &&
            state.message != null) {
          HelperFunctions.showMessage(context, switch (state.message) {
            'cashBookCategoryAddSuccess' =>
              localizations.cashBookCategoryAddSuccess,
            'cashBookCategoryUpdateSuccess' =>
              localizations.cashBookCategoryUpdateSuccess,
            _ => state.message!,
          }, Colors.green);
        }
      },
      builder: (context, state) {
        if (state.status == CashBookCategoryStatus.initial) {
          return const Center(child: LoadingIndicator());
        }
        final categories = _visible(state);
        return Column(
          children: [
            ListFilterBar(
              searchHint: localizations.searchCashBookCategoryHint,
              searchController: _searchController,
              onSearchChanged: (value) => setState(() => searchString = value),
              filters: [
                SegmentedButton<bool>(
                  key: const Key('directionFilter'),
                  showSelectedIcon: false,
                  segments: [
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
                  onSelectionChanged: (selection) =>
                      setState(() => isIncome = selection.first),
                ),
              ],
            ),
            Expanded(
              child: Stack(
                children: [
                  StyledDataTable(
                    columns: getCashBookCategoryListColumns(context),
                    rows: categories
                        .asMap()
                        .entries
                        .map(
                          (entry) => getCashBookCategoryListRow(
                            context: context,
                            category: entry.value,
                            index: entry.key,
                            bloc: _categoryBloc,
                          ),
                        )
                        .toList(),
                    isLoading:
                        state.status == CashBookCategoryStatus.loading &&
                        categories.isEmpty,
                    scrollController: _scrollController,
                    rowHeight: isPhone ? 64 : 56,
                    onRowTap: (index) => _openDialog(categories[index]),
                  ),
                  Positioned(
                    right: right,
                    bottom: bottom,
                    child: FloatingActionButton(
                      key: const Key('addNew'),
                      heroTag: 'cashBookCategoryAdd',
                      onPressed: () => _openDialog(null),
                      tooltip: localizations.newCashBookCategory,
                      child: const Icon(Icons.add),
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
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
