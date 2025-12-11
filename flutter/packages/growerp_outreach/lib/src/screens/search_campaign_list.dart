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

import '../bloc/outreach_campaign_bloc.dart';

class SearchCampaignList extends StatefulWidget {
  const SearchCampaignList({super.key});

  @override
  SearchCampaignListState createState() => SearchCampaignListState();
}

class SearchCampaignListState extends State<SearchCampaignList> {
  final TextEditingController searchBoxController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();
  late OutreachCampaignBloc _campaignBloc;

  @override
  void initState() {
    super.initState();
    _campaignBloc = context.read<OutreachCampaignBloc>();
  }

  @override
  void dispose() {
    searchBoxController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      key: const Key('SearchCampaignDialog'),
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: popUp(
        context: context,
        title: 'Search Campaigns',
        child: Column(
          children: [
            TextFormField(
              key: const Key('searchField'),
              controller: searchBoxController,
              focusNode: searchFocusNode,
              textInputAction: TextInputAction.search,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Search campaigns',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    searchBoxController.clear();
                    _campaignBloc.add(
                      const OutreachCampaignSearchRequested(query: ''),
                    );
                  },
                ),
              ),
              onFieldSubmitted: (value) {
                _campaignBloc.add(
                  OutreachCampaignSearchRequested(query: value),
                );
              },
            ),
            const SizedBox(height: 20),
            Expanded(
              child: BlocBuilder<OutreachCampaignBloc, OutreachCampaignState>(
                builder: (context, state) {
                  final searchStatus = state.searchStatus;
                  if (searchStatus == OutreachCampaignStatus.loading) {
                    return const LoadingIndicator();
                  }
                  if (searchStatus == OutreachCampaignStatus.failure) {
                    return Center(
                      child: Text(
                        state.searchError ?? 'Search failed, please try again.',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  if (state.searchResults.isEmpty) {
                    final message =
                        searchStatus == OutreachCampaignStatus.initial
                            ? 'Enter a search term to begin.'
                            : 'No campaigns matched your search.';
                    return Center(
                      child: Text(message),
                    );
                  }
                  return ListView.builder(
                    itemCount: state.searchResults.length,
                    itemBuilder: (context, index) {
                      final campaign = state.searchResults[index];
                      return ListTile(
                        key: Key('campaignSearchItem$index'),
                        title: Text(campaign.name),
                        subtitle: Text(
                          '${campaign.pseudoId ?? 'N/A'} - ${campaign.status}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => Navigator.of(context).pop(campaign),
                      );
                    },
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
