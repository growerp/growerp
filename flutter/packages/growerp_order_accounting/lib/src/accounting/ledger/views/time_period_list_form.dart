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
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_order_accounting/l10n/generated/order_accounting_localizations.dart';

import '../../accounting.dart';

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
  String classificationId = GlobalConfiguration().getValue("classificationId");
  late String entityName;
  late String periodType;
  String searchString = '';

  @override
  void initState() {
    super.initState();
    periodType = 'Y';
    entityName = classificationId == 'AppHotel' ? 'Room' : 'TimePeriod';
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
            '${state.message}',
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
                label: const Text('Y/Q/M'),
              ),
              body: Column(
                children: [
                  // Filter bar with search
                  ListFilterBar(
                    searchHint: 'Search time periods...',
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
