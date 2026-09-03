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
import 'package:global_configuration/global_configuration.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_order_accounting/growerp_order_accounting.dart';

class TimePeriodListForm extends StatelessWidget {
  const TimePeriodListForm({super.key});
  @override
  Widget build(BuildContext context) => BlocProvider<LedgerBloc>(
    create: (context) => LedgerBloc(context.read<RestClient>()),
    child: const TimePeriodList(),
  );
}

class TimePeriodList extends StatefulWidget {
  const TimePeriodList({super.key});
  @override
  TimePeriodListState createState() => TimePeriodListState();
}

class TimePeriodListState extends State<TimePeriodList> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  late LedgerBloc _ledgerBloc;
  String applicationId = GlobalConfiguration().getValue("applicationId");
  late String entityName;
  late String periodType;
  String searchString = '';

  @override
  void initState() {
    super.initState();
    periodType = 'Y';
    entityName = applicationId == 'AppHotel' ? 'Room' : 'TimePeriod';
    _ledgerBloc = context.read<LedgerBloc>()
      ..add(LedgerTimePeriods(periodType: periodType));
  }

  @override
  Widget build(BuildContext context) {
    final localizations = OrderAccountingLocalizations.of(context)!;
    bool isPhone = isAPhone(context);

    return BlocConsumer<LedgerBloc, LedgerState>(
      listenWhen: (previous, current) =>
          previous.status == LedgerStatus.loading,
      listener: (context, state) {
        if (state.status == LedgerStatus.failure) {
          HelperFunctions.showMessage(context, '${state.message}', Colors.red);
        }
        if (state.status == LedgerStatus.success) {
          HelperFunctions.showMessage(
            context,
            translateLedgerBlocMessage(state.message, localizations),
            Colors.green,
          );
        }
      },
      builder: (context, state) {
        switch (state.status) {
          case LedgerStatus.failure:
            return Center(
              child: Text('failed to fetch timePeriods: ${state.message}'),
            );
          case LedgerStatus.success:
            // Filter list based on search
            var filteredList = state.timePeriods;
            if (searchString.isNotEmpty) {
              filteredList = filteredList.where((item) {
                return item.periodName.toLowerCase().contains(
                  searchString.toLowerCase(),
                );
              }).toList();
            }

            // Build rows for StyledDataTable
            final rows = filteredList.asMap().entries.map((entry) {
              return getTimePeriodListRow(
                context: context,
                timePeriod: entry.value,
                index: entry.key,
                ledgerBloc: _ledgerBloc,
                localizations: localizations,
              );
            }).toList();

            return Scaffold(
              floatingActionButton: FloatingActionButton.extended(
                heroTag: "timePeriodNew",
                key: const Key("changePeriod"),
                onPressed: () async {
                  setState(() {
                    if (periodType == 'Y') {
                      periodType = 'Q';
                    } else if (periodType == 'Q') {
                      periodType = 'M';
                    } else if (periodType == 'M') {
                      periodType = 'Y';
                    }
                  });
                  _ledgerBloc.add(LedgerTimePeriods(periodType: periodType));
                },
                tooltip: 'Change period type(Y/Q/M)',
                label: Text(OrderAccountingLocalizations.of(context)!.yqm),
              ),
              body: Column(
                children: [
                  // Filter bar with search
                  ListFilterBar(
                    searchHint: OrderAccountingLocalizations.of(
                      context,
                    )!.searchHintTimePeriods,
                    searchController: _searchController,
                    onSearchChanged: (value) {
                      setState(() {
                        searchString = value;
                      });
                    },
                  ),
                  // Main content with StyledDataTable
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async => _ledgerBloc.add(
                        LedgerTimePeriods(periodType: periodType),
                      ),
                      child: StyledDataTable(
                        columns: getTimePeriodListColumns(
                          context,
                          localizations,
                        ),
                        rows: rows,
                        isLoading:
                            state.status == LedgerStatus.loading &&
                            filteredList.isEmpty,
                        scrollController: _scrollController,
                        rowHeight: isPhone ? 56 : 56,
                      ),
                    ),
                  ),
                ],
              ),
            );
          default:
            return const Center(child: LoadingIndicator());
        }
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
