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
import 'package:growerp_sales/l10n/generated/sales_localizations.dart';

import '../bloc/opportunity_bloc.dart';
import '../widgets/opportunity_list_styled_data.dart';
import 'views.dart';

class OpportunityList extends StatefulWidget {
  const OpportunityList({super.key});

  @override
  OpportunitiesState createState() => OpportunitiesState();
}

class OpportunitiesState extends State<OpportunityList> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  late OpportunityBloc _opportunityBloc;
  List<Opportunity> opportunities = const <Opportunity>[];
  late double bottom;
  double? right;
  late SalesLocalizations _localizations;
  String searchString = '';
  bool _isLoading = true;
  bool hasReachedMax = false;
  double currentScroll = 0;

  @override
  void initState() {
    super.initState();
    _opportunityBloc = context.read<OpportunityBloc>()
      ..add(const OpportunityFetch(refresh: true, limit: 15));
    _scrollController.addListener(_onScroll);
    bottom = 50;
  }

  @override
  Widget build(BuildContext context) {
    _localizations = SalesLocalizations.of(context)!;
    final isPhone = isAPhone(context);
    right = right ?? (isPhone ? 20 : 50);

    Widget tableView() {
      // Build rows for StyledDataTable
      final rows = opportunities.map((opportunity) {
        final index = opportunities.indexOf(opportunity);
        return getOpportunityListRow(
          context: context,
          opportunity: opportunity,
          index: index,
          bloc: _opportunityBloc,
          localizations: _localizations,
        );
      }).toList();

      return StyledDataTable(
        columns: getOpportunityListColumns(context, _localizations),
        rows: rows,
        isLoading: _isLoading && opportunities.isEmpty,
        scrollController: _scrollController,
        rowHeight: isPhone ? 60 : 56,
        onRowTap: (index) {
          showDialog(
            barrierDismissible: true,
            context: context,
            builder: (BuildContext context) {
              return Dismissible(
                key: const Key('opportunityItem'),
                direction: DismissDirection.startToEnd,
                child: BlocProvider.value(
                  value: _opportunityBloc,
                  child: OpportunityDialog(opportunities[index]),
                ),
              );
            },
          );
        },
      );
    }

    return BlocConsumer<OpportunityBloc, OpportunityState>(
      listener: (context, state) {
        if (state.status == OpportunityStatus.failure) {
          HelperFunctions.showMessage(context, '${state.message}', Colors.red);
        }
        if (state.status == OpportunityStatus.success) {
          if ((state.message ?? '').isNotEmpty) {
            HelperFunctions.showMessage(
              context,
              '${state.message}',
              Colors.green,
            );
          }
        }
      },
      builder: (context, state) {
        // Update loading state
        _isLoading = state.status == OpportunityStatus.loading;

        if (state.status == OpportunityStatus.failure &&
            opportunities.isEmpty) {
          return Center(
            child: Text(_localizations.fetchError(state.message ?? '')),
          );
        }

        opportunities = state.opportunities;
        hasReachedMax = state.hasReachedMax;
        if (opportunities.isNotEmpty && _scrollController.hasClients) {
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
              searchHint: _localizations.opportunitySearch,
              searchController: _searchController,
              onSearchChanged: (value) {
                searchString = value;
                _opportunityBloc.add(
                  OpportunityFetch(refresh: true, searchString: value),
                );
              },
            ),
            // Main content area with StyledDataTable
            Expanded(
              child: Stack(
                children: [
                  tableView(),
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
                        key: const Key('addNew'),
                        onPressed: () async {
                          await showDialog(
                            barrierDismissible: true,
                            context: context,
                            builder: (BuildContext context) =>
                                BlocProvider.value(
                                  value: _opportunityBloc,
                                  child: OpportunityDialog(Opportunity()),
                                ),
                          );
                        },
                        tooltip: _localizations.addNew,
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
    super.dispose();
  }

  void _onScroll() {
    currentScroll = _scrollController.offset;
    if (_isBottom && !hasReachedMax) {
      _opportunityBloc.add(OpportunityFetch(searchString: searchString));
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }
}
