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

import '../bloc/outreach_campaign_bloc.dart';
import 'campaign_detail_screen.dart';
import 'campaign_list_styled_data.dart';

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
              searchHint: 'Search campaigns...',
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
                      child: FloatingActionButton(
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
