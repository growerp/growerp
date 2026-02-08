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
import 'package:growerp_order_accounting/src/findoc/findoc.dart';
import 'package:growerp_order_accounting/l10n/generated/order_accounting_localizations.dart';

import '../../accounting/accounting.dart';

class ItemTypeList extends StatefulWidget {
  const ItemTypeList({super.key});
  @override
  ItemTypeListState createState() => ItemTypeListState();
}

class ItemTypeListState extends State<ItemTypeList> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  late FinDocBloc finDocBloc;
  late GlAccountBloc glAccountBloc;
  String classificationId = GlobalConfiguration().getValue("classificationId");
  late String entityName;
  late bool showAll;
  String searchString = '';
  late OrderAccountingLocalizations _localizations;

  @override
  void initState() {
    super.initState();
    showAll = false;
    entityName = classificationId == 'AppHotel' ? 'Room' : 'ItemType';
    finDocBloc = context.read<FinDocBloc>()..add(const FinDocGetItemTypes());
    glAccountBloc = context.read<GlAccountBloc>()
      ..add(const GlAccountFetch(refresh: true, limit: 100));
  }

  @override
  Widget build(BuildContext context) {
    _localizations = OrderAccountingLocalizations.of(context)!;
    bool isPhone = isAPhone(context);

    return BlocConsumer<FinDocBloc, FinDocState>(
      listenWhen: (previous, current) =>
          previous.status == FinDocStatus.loading,
      listener: (context, state) {
        if (state.status == FinDocStatus.failure) {
          HelperFunctions.showMessage(context, '${state.message}', Colors.red);
        }
        if (state.status == FinDocStatus.success) {
          HelperFunctions.showMessage(
            context,
            '${state.message}',
            Colors.green,
          );
        }
      },
      builder: (context, state) {
        switch (state.status) {
          case FinDocStatus.failure:
            return Center(
              child: Text(
                '${_localizations.fetchItemTypesFail} ${state.message}',
              ),
            );
          case FinDocStatus.success:
            // Filter list based on showAll toggle
            var filteredList = <dynamic>[];
            for (var item in state.itemTypes) {
              if (showAll) {
                filteredList.add(item);
              } else {
                if (item.accountCode != '') filteredList.add(item);
              }
            }

            // Apply search filter
            if (searchString.isNotEmpty) {
              filteredList = filteredList.where((item) {
                final combined =
                    '${item.itemTypeName} ${item.direction} '
                            '${item.accountName ?? ''} ${item.accountCode ?? ''}'
                        .toLowerCase();
                return combined.contains(searchString.toLowerCase());
              }).toList();
            }

            // Build rows for StyledDataTable
            final rows = filteredList.asMap().entries.map((entry) {
              return getItemTypeListRow(
                context: context,
                itemType: entry.value,
                index: entry.key,
                finDocBloc: finDocBloc,
                glAccountBloc: glAccountBloc,
              );
            }).toList();

            return Scaffold(
              floatingActionButton: FloatingActionButton.extended(
                heroTag: 'showAll',
                key: const Key("switchShow"),
                onPressed: () {
                  setState(() {
                    showAll = !showAll;
                  });
                },
                tooltip: _localizations.showAllUsed,
                label: showAll
                    ? Text(_localizations.all)
                    : Text(_localizations.onlyUsed),
              ),
              body: Column(
                children: [
                  // Filter bar with search and showAll toggle
                  ListFilterBar(
                    searchHint: 'Search item type or account...',
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
                      onRefresh: () async =>
                          finDocBloc.add(const FinDocGetItemTypes()),
                      child: StyledDataTable(
                        columns: getItemTypeListColumns(context),
                        rows: rows,
                        isLoading:
                            state.status == FinDocStatus.loading &&
                            filteredList.isEmpty,
                        scrollController: _scrollController,
                        rowHeight: isPhone ? 72 : 56,
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
