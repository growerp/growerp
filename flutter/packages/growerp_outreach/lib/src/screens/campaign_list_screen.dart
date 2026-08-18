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

import '../bloc/outreach_campaign_bloc.dart';
import 'campaign_detail_screen.dart';
import 'campaign_list_styled_data.dart';
import 'package:growerp_outreach/l10n/generated/outreach_localizations.dart';

class CampaignListScreen extends StatefulWidget {
  const CampaignListScreen({super.key});

  @override
  CampaignListScreenState createState() => CampaignListScreenState();
}

class CampaignListScreenState extends State<CampaignListScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  late OutreachCampaignBloc _campaignBloc;
  List<OutreachCampaign> campaigns = const <OutreachCampaign>[];
  bool hasReachedMax = false;
  late double bottom;
  double? right;
  double currentScroll = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _campaignBloc = context.read<OutreachCampaignBloc>()
      ..add(const OutreachCampaignFetch(start: 0));
    bottom = 50;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = OutreachLocalizations.of(context)!;
    final isPhone = isAPhone(context);
    right = right ?? (isPhone ? 20 : 50);

    Widget tableView() {
      // Build rows for StyledDataTable
      final rows = campaigns.map((campaign) {
        final index = campaigns.indexOf(campaign);
        return getCampaignListRow(
          context: context,
          campaign: campaign,
          index: index,
          bloc: _campaignBloc,
        );
      }).toList();

      return StyledDataTable(
        columns: getCampaignListColumns(context),
        rows: rows,
        isLoading: _isLoading && campaigns.isEmpty,
        scrollController: _scrollController,
        rowHeight: isPhone ? 80 : 56,
        onRowTap: (index) {
          showDialog(
            barrierDismissible: true,
            context: context,
            builder: (BuildContext context) {
              return Dismissible(
                key: Key('campaign_${campaigns[index].campaignId}'),
                direction: DismissDirection.startToEnd,
                child: BlocProvider.value(
                  value: _campaignBloc,
                  child: CampaignDetailScreen(campaign: campaigns[index]),
                ),
              );
            },
          );
        },
      );
    }

    return BlocConsumer<OutreachCampaignBloc, OutreachCampaignState>(
      listener: (context, state) {
        if (state.status == OutreachCampaignStatus.failure) {
          HelperFunctions.showMessage(
            context,
            '${state.message}',
            Colors.red,
          );
        }
        if (state.status == OutreachCampaignStatus.success) {
          if ((state.message ?? '').isNotEmpty) {
            HelperFunctions.showMessage(
              context,
              state.message!,
              Colors.green,
            );
          }
        }
      },
      builder: (context, state) {
        // Update loading state
        _isLoading = state.status == OutreachCampaignStatus.loading;

        if (state.status == OutreachCampaignStatus.failure &&
            campaigns.isEmpty) {
          return const FatalErrorForm(
            message: 'Could not load campaigns!',
          );
        }

        campaigns = state.campaigns;
        if (campaigns.isNotEmpty && _scrollController.hasClients) {
          Future.delayed(const Duration(milliseconds: 100), () {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_scrollController.hasClients) {
                _scrollController.jumpTo(currentScroll);
              }
            });
          });
        }
        hasReachedMax = state.hasReachedMax;

        return Column(
          children: [
            // Filter bar with search
            ListFilterBar(
              searchHint: localizations.searchHintCampaigns,
              searchController: _searchController,
              onSearchChanged: (value) {
                _campaignBloc.add(OutreachCampaignFetch(
                  start: 0,
                  searchString: value.isEmpty ? null : value,
                ));
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
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FloatingActionButton(
                            key: const Key('generateAICampaign'),
                            heroTag: 'campaignBtn2',
                            onPressed: () async {
                              await showDialog(
                                barrierDismissible: true,
                                context: context,
                                builder: (BuildContext context) {
                                  return BlocProvider.value(
                                    value: _campaignBloc,
                                    child: const GenerateCampaignDialog(),
                                  );
                                },
                              );
                            },
                            tooltip: 'Generate campaign with AI',
                            child: const Icon(Icons.auto_awesome),
                          ),
                          const SizedBox(height: 10),
                          FloatingActionButton(
                            key: const Key('addNew'),
                            heroTag: 'campaignBtn1',
                            onPressed: () async {
                              await showDialog(
                                barrierDismissible: true,
                                context: context,
                                builder: (BuildContext context) {
                                  return BlocProvider.value(
                                    value: _campaignBloc,
                                    child: const CampaignDetailScreen(
                                      campaign: OutreachCampaign(
                                        name: '',
                                        platforms: '[]',
                                        status: 'MKTG_CAMP_PLANNED',
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                            tooltip: 'Add new campaign',
                            child: const Icon(Icons.add),
                          ),
                        ],
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

  void _onScroll() {
    currentScroll = _scrollController.offset;
    if (_isBottom && !hasReachedMax) {
      _campaignBloc.add(
        OutreachCampaignFetch(start: campaigns.length),
      );
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }
}

/// Collects a campaign goal and lets the backend build the whole campaign
/// with AI. The generated campaign is created server side and appears at the
/// top of the list.
class GenerateCampaignDialog extends StatefulWidget {
  const GenerateCampaignDialog({super.key});

  @override
  GenerateCampaignDialogState createState() => GenerateCampaignDialogState();
}

class GenerateCampaignDialogState extends State<GenerateCampaignDialog> {
  final _formKey = GlobalKey<FormState>();
  final _goalController = TextEditingController();
  final _audienceController = TextEditingController();

  /// same platforms the campaign detail screen supports
  static const List<String> _availablePlatforms = ['EMAIL', 'LINKEDIN'];
  final Set<String> _selectedPlatforms = {..._availablePlatforms};

  late OutreachCampaignBloc _campaignBloc;

  @override
  void initState() {
    super.initState();
    _campaignBloc = context.read<OutreachCampaignBloc>();
  }

  @override
  void dispose() {
    _goalController.dispose();
    _audienceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      key: const Key('GenerateCampaignDialog'),
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: popUp(
        context: context,
        title: 'Generate Campaign with AI',
        height: 550,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  key: const Key('campaignGoal'),
                  controller: _goalController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Campaign goal *',
                    hintText: 'What should this campaign achieve, and for whom? '
                        'e.g. book demos for our warehouse app with wholesalers',
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please describe the campaign goal'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('targetAudience'),
                  controller: _audienceController,
                  decoration: const InputDecoration(
                    labelText: 'Target audience (optional)',
                    hintText: 'Left empty the AI infers it from the goal',
                  ),
                ),
                const SizedBox(height: 16),
                ..._availablePlatforms.map(
                  (platform) => CheckboxListTile(
                    key: Key('platform$platform'),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(platform),
                    value: _selectedPlatforms.contains(platform),
                    onChanged: (checked) {
                      setState(() {
                        if (checked == true) {
                          _selectedPlatforms.add(platform);
                        } else {
                          _selectedPlatforms.remove(platform);
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(height: 24),
                BlocConsumer<OutreachCampaignBloc, OutreachCampaignState>(
                  listener: (context, state) {
                    if (state.status == OutreachCampaignStatus.success &&
                        (state.message ?? '').contains('AI')) {
                      Navigator.of(context).pop();
                    }
                    if (state.status == OutreachCampaignStatus.failure) {
                      HelperFunctions.showMessage(
                        context,
                        state.message ?? 'Failed to generate campaign',
                        Colors.red,
                      );
                    }
                  },
                  builder: (context, state) {
                    final isLoading =
                        state.status == OutreachCampaignStatus.loading;
                    return ElevatedButton.icon(
                      key: const Key('generateButton'),
                      onPressed: isLoading
                          ? null
                          : () {
                              if (_formKey.currentState?.validate() != true) {
                                return;
                              }
                              if (_selectedPlatforms.isEmpty) {
                                HelperFunctions.showMessage(
                                  context,
                                  'Please select at least one platform',
                                  Colors.red,
                                );
                                return;
                              }
                              _campaignBloc.add(
                                OutreachCampaignGenerateWithAI(
                                  campaignGoal: _goalController.text,
                                  targetAudience:
                                      _audienceController.text.isEmpty
                                          ? null
                                          : _audienceController.text,
                                  platforms: _selectedPlatforms.join(','),
                                ),
                              );
                            },
                      icon: isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.auto_awesome),
                      label: Text(
                        isLoading ? 'Generating...' : 'Generate Campaign',
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
