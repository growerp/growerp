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
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_marketing/l10n/generated/marketing_localizations.dart';
import '../bloc/opportunity_bloc.dart';

class SearchOpportunityList extends StatefulWidget {
  const SearchOpportunityList({super.key});

  @override
  SearchOpportunityState createState() => SearchOpportunityState();
}

class SearchOpportunityState extends State<SearchOpportunityList> {
  late OpportunityBloc _opportunityBloc;
  List<Opportunity> opportunities = [];
  late MarketingLocalizations localizations;

  @override
  void initState() {
    super.initState();
    _opportunityBloc = context.read<OpportunityBloc>()
      ..add(const OpportunityFetch(limit: 0));
  }

  @override
  Widget build(BuildContext context) {
    localizations = MarketingLocalizations.of(context)!;
    return BlocConsumer<OpportunityBloc, OpportunityState>(
      listener: (context, state) {
        if (state.status == OpportunityStatus.failure) {
          HelperFunctions.showMessage(context, '${state.message}', Colors.red);
        }
      },
      builder: (context, state) {
        if (state.status == OpportunityStatus.failure) {
          return Center(
            child: Text(localizations.fetchSearchError(state.message!)),
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
    final ScrollController scrollController = ScrollController();
    final localizations = MarketingLocalizations.of(context)!;
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
            TextFormField(
              key: const Key('searchField'),
              textInputAction: TextInputAction.search,
              autofocus: true,
              decoration: InputDecoration(labelText: localizations.searchInput),
              validator: (value) {
                if (value!.isEmpty) {
                  return localizations.enterSearchValue;
                }
                return null;
              },
              onFieldSubmitted: (value) => _opportunityBloc.add(
                OpportunityFetch(limit: 5, searchString: value),
              ),
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
