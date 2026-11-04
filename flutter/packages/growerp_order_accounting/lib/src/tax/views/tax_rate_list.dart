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

import '../blocs/tax_rate_bloc.dart';
import '../widgets/tax_rate_list_styled_data.dart';
import 'tax_rate_dialog.dart';

/// The sales tax rates of the company. Without rates no tax is charged.
class TaxRateList extends StatefulWidget {
  const TaxRateList({super.key});

  @override
  TaxRateListState createState() => TaxRateListState();
}

class TaxRateListState extends State<TaxRateList> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  late TaxRateBloc _taxRateBloc;
  String searchString = '';

  @override
  void initState() {
    super.initState();
    _taxRateBloc = context.read<TaxRateBloc>()..add(const TaxRateFetch());
  }

  Future<void> _openDialog(TaxRate? taxRate) async {
    await showDialog(
      barrierDismissible: true,
      context: context,
      builder: (BuildContext context) => BlocProvider.value(
        value: _taxRateBloc,
        child: TaxRateDialog(taxRate),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = OrderAccountingLocalizations.of(context)!;
    final isPhone = isAPhone(context);

    return BlocConsumer<TaxRateBloc, TaxRateState>(
      listener: (context, state) {
        if (state.status == TaxRateStatus.failure) {
          HelperFunctions.showMessage(context, '${state.message}', Colors.red);
        }
        if (state.status == TaxRateStatus.success && state.message != null) {
          HelperFunctions.showMessage(context, switch (state.message) {
            'taxRateAddSuccess' => localizations.taxRateAddSuccess,
            'taxRateUpdateSuccess' => localizations.taxRateUpdateSuccess,
            'taxRateDeleteSuccess' => localizations.taxRateDeleteSuccess,
            _ => state.message!,
          }, Colors.green);
        }
      },
      builder: (context, state) {
        if (state.status == TaxRateStatus.initial) {
          return const Center(child: LoadingIndicator());
        }
        final rates = state.taxRates
            .where(
              (r) =>
                  searchString.isEmpty ||
                  (r.taxName ?? '').toLowerCase().contains(
                    searchString.toLowerCase(),
                  ),
            )
            .toList();
        return Column(
          children: [
            ListFilterBar(
              searchHint: localizations.searchTaxRateHint,
              searchController: _searchController,
              onSearchChanged: (value) => setState(() => searchString = value),
              filters: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(localizations.pricesIncludeTax),
                    Switch(
                      key: const Key('pricesIncludeTax'),
                      value: state.pricesIncludeTax,
                      onChanged: (value) => _taxRateBloc.add(
                        TaxSettingsUpdate(pricesIncludeTax: value),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Expanded(
              child: Stack(
                children: [
                  StyledDataTable(
                    columns: getTaxRateListColumns(context),
                    rows: rates
                        .asMap()
                        .entries
                        .map(
                          (entry) => getTaxRateListRow(
                            context: context,
                            taxRate: entry.value,
                            index: entry.key,
                          ),
                        )
                        .toList(),
                    isLoading:
                        state.status == TaxRateStatus.loading && rates.isEmpty,
                    scrollController: _scrollController,
                    rowHeight: isPhone ? 64 : 56,
                    onRowTap: (index) => _openDialog(rates[index]),
                  ),
                  Positioned(
                    right: isPhone ? 20 : 50,
                    bottom: 50,
                    child: FloatingActionButton(
                      key: const Key('addNew'),
                      heroTag: 'taxRateAdd',
                      onPressed: () => _openDialog(null),
                      tooltip: localizations.newTaxRate,
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
