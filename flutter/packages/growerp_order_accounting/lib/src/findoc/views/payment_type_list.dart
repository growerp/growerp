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
import 'package:growerp_order_accounting/src/findoc/findoc.dart';
import 'package:growerp_order_accounting/l10n/generated/order_accounting_localizations.dart';

import '../../accounting/accounting.dart';

class PaymentTypeList extends StatefulWidget {
  const PaymentTypeList({super.key});
  @override
  PaymentTypeListState createState() => PaymentTypeListState();
}

class PaymentTypeListState extends State<PaymentTypeList> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  late FinDocBloc finDocBloc;
  late GlAccountBloc glAccountBloc;
  String applicationId = GlobalConfiguration().getValue("applicationId");
  late String entityName;
  late bool showAll;
  String searchString = '';
  late OrderAccountingLocalizations _localizations;

  @override
  void initState() {
    super.initState();
    showAll = false;
    entityName = applicationId == 'AppHotel' ? 'Room' : 'PaymentType';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
    finDocBloc = context.read<FinDocBloc>()..add(const FinDocGetPaymentTypes());
    glAccountBloc = context.read<GlAccountBloc>()
      ..add(const GlAccountFetch(refresh: true, limit: 500));
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
                '${_localizations.fetchPaymentTypesFail} ${state.message}',
              ),
            );
          case FinDocStatus.success:
            // Filter list based on showAll toggle
            var filteredList = <dynamic>[];
            for (var item in state.paymentTypes) {
              if (showAll) {
                filteredList.add(item);
              } else {
                if (item.accountCode != '') filteredList.add(item);
              }
            }

            // Apply search filter
            if (searchString.isNotEmpty) {
              filteredList = filteredList.where((item) {
                final displayName =
                    '${item.paymentTypeName} -- '
                    '${item.isPayable ? 'Outgoing' : 'Incoming'} -- '
                    '${item.isApplied ? 'Y' : 'N'}';
                final query = searchString.toLowerCase();
                return displayName.toLowerCase().contains(query) ||
                    item.paymentTypeName.toLowerCase().contains(query) ||
                    (item.accountName ?? '').toLowerCase().contains(query) ||
                    (item.accountCode ?? '').toLowerCase().contains(query);
              }).toList();
            }

            // Build rows for StyledDataTable
            final rows = filteredList.asMap().entries.map((entry) {
              return getPaymentTypeListRow(
                context: context,
                paymentType: entry.value,
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
                  // Filter bar with search
                  ListFilterBar(
                    searchHint: 'Search payment type or account...',
                    searchController: _searchController,
                    focusNode: _searchFocusNode,
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
                          finDocBloc.add(const FinDocGetPaymentTypes()),
                      child: StyledDataTable(
                        columns: getPaymentTypeListColumns(context),
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
    _searchFocusNode.dispose();
    super.dispose();
  }
}
