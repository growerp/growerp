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
import 'package:growerp_sales/l10n/generated/sales_localizations.dart';
import '../bloc/opportunity_bloc.dart';

class SearchOpportunityList extends StatefulWidget {
  const SearchOpportunityList({super.key});

  @override
  SearchOpportunityState createState() => SearchOpportunityState();
}

class SearchOpportunityState extends State<SearchOpportunityList> {
  late OpportunityBloc _opportunityBloc;
  List<Opportunity> opportunities = [];
  late SalesLocalizations _localizations;

  @override
  void initState() {
    super.initState();
    _opportunityBloc = context.read<OpportunityBloc>()
      ..add(const OpportunityFetch(limit: 0));
  }

  @override
  Widget build(BuildContext context) {
    _localizations = SalesLocalizations.of(context)!;
    return BlocConsumer<OpportunityBloc, OpportunityState>(
      listener: (context, state) {
        if (state.status == OpportunityStatus.failure) {
          HelperFunctions.showMessage(context, '${state.message}', Colors.red);
        }
      },
      builder: (context, state) {
        if (state.status == OpportunityStatus.failure) {
          return Center(
            child: Text(_localizations.fetchSearchError(state.message!)),
          );
        }
        if (state.status == OpportunityStatus.success) {
          opportunities = state.searchResults;
        }
        return Stack(
          children: [
            OpportunitySearchDialog(
              opportunityBloc: _opportunityBloc,
              widget: widget,
              opportunities: opportunities,
            ),
            if (state.status == OpportunityStatus.loading)
              const LoadingIndicator(),
          ],
        );
      },
    );
  }
}

class OpportunitySearchDialog extends StatelessWidget {
  const OpportunitySearchDialog({
    super.key,
    required OpportunityBloc opportunityBloc,
    required this.widget,
    required this.opportunities,
  }) : _opportunityBloc = opportunityBloc;

  final OpportunityBloc _opportunityBloc;
  final SearchOpportunityList widget;
  final List<Opportunity> opportunities;

  @override
  Widget build(BuildContext context) {
    final localizations = SalesLocalizations.of(context)!;
    final ScrollController scrollController = ScrollController();
    return Dialog(
      key: const Key('SearchDialog'),
      insetPadding: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: popUp(
        context: context,
        title: localizations.opportunitySearch,
        height: 500,
        width: 350,
        child: Column(
          children: [
            ListFilterBar(
              searchHint: localizations.searchInput,
              onSearchChanged: (value) {
                if (value.isNotEmpty) {
                  _opportunityBloc.add(
                    OpportunityFetch(limit: 5, searchString: value),
                  );
                }
              },
            ),
            const SizedBox(height: 20),
            Text(localizations.searchResults),
            Expanded(
              child: ListView.builder(
                key: const Key('listView'),
                shrinkWrap: true,
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: opportunities.length + 2,
                controller: scrollController,
                itemBuilder: (BuildContext context, int index) {
                  if (index == 0) {
                    return Visibility(
                      visible: opportunities.isEmpty,
                      child: Center(
                        heightFactor: 20,
                        child: Text(
                          localizations.noSearchItems,
                          key: const Key('empty'),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  index--;
                  return index >= opportunities.length
                      ? const Text('')
                      : Dismissible(
                          key: const Key('searchItem'),
                          direction: DismissDirection.startToEnd,
                          child: ListTile(
                            title: Text(
                              localizations.searchResult(
                                opportunities[index].pseudoId,
                                opportunities[index].opportunityName ?? '',
                              ),
                              key: Key("searchResult$index"),
                            ),
                            onTap: () =>
                                Navigator.of(context).pop(opportunities[index]),
                          ),
                        );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
