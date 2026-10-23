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
import 'package:growerp_order_accounting/growerp_order_accounting.dart';

/// Read-only list of the central currency exchange rates, refreshed weekly
/// by the backend for all tenants.
class CurrencyExchangeList extends StatelessWidget {
  const CurrencyExchangeList({super.key});
  @override
  Widget build(BuildContext context) =>
      BlocProvider<DataFetchBloc<ExchangeRates>>(
        create: (context) => DataFetchBloc<ExchangeRates>(),
        child: const CurrencyExchangeListView(),
      );
}

class CurrencyExchangeListView extends StatefulWidget {
  const CurrencyExchangeListView({super.key});
  @override
  CurrencyExchangeListViewState createState() =>
      CurrencyExchangeListViewState();
}

class CurrencyExchangeListViewState extends State<CurrencyExchangeListView> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  late DataFetchBloc<ExchangeRates> _rateBloc;
  String searchString = '';

  @override
  void initState() {
    super.initState();
    _rateBloc = context.read<DataFetchBloc<ExchangeRates>>();
    _fetch();
  }

  void _fetch() => _rateBloc.add(
    GetDataEvent<ExchangeRates>(
      () => context.read<RestClient>().getExchangeRates(),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final localizations = OrderAccountingLocalizations.of(context)!;

    return BlocBuilder<
      DataFetchBloc<ExchangeRates>,
      DataFetchState<ExchangeRates>
    >(
      builder: (context, state) {
        if (state.status == DataFetchStatus.failure) {
          return Center(
            child: Text(
              '${localizations.fetchExchangeRatesFail} ${state.message}',
            ),
          );
        }
        final rates = state.data is ExchangeRates
            ? (state.data as ExchangeRates).exchangeRates
            : <ExchangeRate>[];
        final filteredList = rates.where((rate) {
          final combined = '${rate.fromCurrencyId} ${rate.toCurrencyId}'
              .toLowerCase();
          return combined.contains(searchString.toLowerCase());
        }).toList();

        final rows = filteredList.asMap().entries.map((entry) {
          final rate = entry.value;
          final index = entry.key;
          return <Widget>[
            Text(rate.fromCurrencyId, key: Key('fromCurrency$index')),
            Text(rate.toCurrencyId, key: Key('toCurrency$index')),
            Text(rate.rate?.toString() ?? '', key: Key('rate$index')),
            Text(
              rate.fromDate.toLocalizedDateOnly(context),
              key: Key('rateDate$index'),
            ),
          ];
        }).toList();

        return Column(
          children: [
            ListFilterBar(
              searchHint: localizations.searchHintExchangeRates,
              searchController: _searchController,
              onSearchChanged: (value) {
                setState(() {
                  searchString = value;
                });
              },
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => _fetch(),
                child: StyledDataTable(
                  key: const Key('exchangeRateList'),
                  columns: [
                    StyledColumn(header: localizations.from),
                    StyledColumn(header: localizations.to),
                    StyledColumn(header: localizations.exchangeRate),
                    StyledColumn(header: localizations.date),
                  ],
                  rows: rows,
                  isLoading: state.status != DataFetchStatus.success,
                  scrollController: _scrollController,
                ),
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
