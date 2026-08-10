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

import '../bloc/outreach_campaign_bloc.dart';
import 'package:growerp_outreach/l10n/generated/outreach_localizations.dart';

/// Formats backend status for display
/// 'MKTG_CAMP_PLANNED' -> 'Planned'
String _formatStatus(String status) {
  final cleaned = status.replaceFirst('MKTG_CAMP_', '');
  if (cleaned.isEmpty) return status;
  return cleaned[0].toUpperCase() + cleaned.substring(1).toLowerCase();
}

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
    final localizations = OutreachLocalizations.of(context)!;
    return Dialog(
      key: const Key('SearchCampaignDialog'),
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: popUp(
        context: context,
        title: 'Search Campaigns',
        child: Column(
          children: [
            ListFilterBar(
              searchHint: localizations.searchHintCampaigns,
              searchController: searchBoxController,
              focusNode: searchFocusNode,
              onSearchChanged: (value) {
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
                          '${campaign.pseudoId ?? 'N/A'} - ${_formatStatus(campaign.status)}',
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
