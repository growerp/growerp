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

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

import '../bloc/outreach_campaign_bloc.dart';
import 'campaign_detail_screen.dart';
import 'campaign_list_table_def.dart';
import 'search_campaign_list.dart';

// Table padding and background decoration
const campaignPadding = SpanPadding(trailing: 5, leading: 5);

SpanDecoration? getCampaignBackGround(BuildContext context, int index) {
  return index == 0
      ? SpanDecoration(color: Theme.of(context).colorScheme.tertiaryContainer)
      : null;
}

class CampaignListScreen extends StatefulWidget {
  const CampaignListScreen({super.key});

  @override
  CampaignListScreenState createState() => CampaignListScreenState();
}

class CampaignListScreenState extends State<CampaignListScreen> {
  final _scrollController = ScrollController();
  final _horizontalController = ScrollController();
  late OutreachCampaignBloc _campaignBloc;
  List<OutreachCampaign> campaigns = const <OutreachCampaign>[];
  bool hasReachedMax = false;
  late double bottom;
  double? right;
  double currentScroll = 0;

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
    final isPhone = ResponsiveBreakpoints.of(context).isMobile;
    right = right ?? (isPhone ? 20 : 50);

    return Builder(
      builder: (BuildContext context) {
        Widget tableView() {
          if (campaigns.isEmpty) {
            return const Center(
              child: Text(
                'No campaigns found',
                style: TextStyle(fontSize: 20.0),
              ),
            );
          }

          // get table data formatted for tableView
          var (
            List<List<TableViewCell>> tableViewCells,
            List<double> fieldWidths,
            double? rowHeight,
          ) = get2dTableData<OutreachCampaign>(
            getCampaignListTableData,
            bloc: _campaignBloc,
            classificationId: 'AppAdmin',
            context: context,
            items: campaigns,
          );

          return TableView.builder(
            diagonalDragBehavior: DiagonalDragBehavior.free,
            verticalDetails: ScrollableDetails.vertical(
              controller: _scrollController,
            ),
            horizontalDetails: ScrollableDetails.horizontal(
              controller: _horizontalController,
            ),
            cellBuilder: (context, vicinity) =>
                tableViewCells[vicinity.row][vicinity.column],
            columnBuilder: (index) => index >= tableViewCells[0].length
                ? null
                : TableSpan(
                    padding: campaignPadding,
                    backgroundDecoration: getCampaignBackGround(
                      context,
                      index,
                    ),
                    extent: FixedTableSpanExtent(fieldWidths[index]),
                  ),
            pinnedColumnCount: 1,
            rowBuilder: (index) => index >= tableViewCells.length
                ? null
                : TableSpan(
                    padding: campaignPadding,
                    backgroundDecoration: getCampaignBackGround(
                      context,
                      index,
                    ),
                    extent: FixedTableSpanExtent(rowHeight!),
                    recognizerFactories: <Type, GestureRecognizerFactory>{
                      TapGestureRecognizer:
                          GestureRecognizerFactoryWithHandlers<
                              TapGestureRecognizer>(
                        () => TapGestureRecognizer(),
                        (TapGestureRecognizer t) => t.onTap = () {
                          if (index == 0) return;
                          showDialog(
                            barrierDismissible: true,
                            context: context,
                            builder: (BuildContext context) {
                              return index > campaigns.length
                                  ? const BottomLoader()
                                  : Dismissible(
                                      key: Key(
                                          'campaign_${campaigns[index - 1].campaignId}'),
                                      direction: DismissDirection.startToEnd,
                                      child: BlocProvider.value(
                                        value: _campaignBloc,
                                        child: CampaignDetailScreen(
                                          campaign: campaigns[index - 1],
                                        ),
                                      ),
                                    );
                            },
                          );
                        },
                      ),
                    },
                  ),
            pinnedRowCount: 1,
          );
        }

        blocListener(context, state) {
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
        }

        blocBuilder(context, state) {
          if (state.status == OutreachCampaignStatus.failure) {
            return const FatalErrorForm(
              message: "Could not load campaigns!",
            );
          } else {
            campaigns = state.campaigns;
            if (campaigns.isNotEmpty && _scrollController.hasClients) {
              Future.delayed(const Duration(milliseconds: 100), () {
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) {
                    if (_scrollController.hasClients) {
                      _scrollController.jumpTo(currentScroll);
                    }
                  },
                );
              });
            }
            hasReachedMax = state.hasReachedMax;
            return Stack(
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
                      children: [
                        FloatingActionButton(
                          key: const Key("search"),
                          heroTag: "campaignBtn0",
                          onPressed: () async {
                            // find campaign to show
                            await showDialog(
                              barrierDismissible: true,
                              context: context,
                              builder: (BuildContext context) {
                                return BlocProvider.value(
                                  value: _campaignBloc,
                                  child: const SearchCampaignList(),
                                );
                              },
                            ).then(
                              (value) async => value != null
                                  ? await showDialog(
                                      barrierDismissible: true,
                                      context: context,
                                      builder: (BuildContext context) {
                                        return BlocProvider.value(
                                          value: _campaignBloc,
                                          child: CampaignDetailScreen(
                                            campaign: value,
                                          ),
                                        );
                                      },
                                    )
                                  : const SizedBox.shrink(),
                            );
                          },
                          child: const Icon(Icons.search),
                        ),
                        const SizedBox(height: 10),
                        FloatingActionButton(
                          key: const Key("addNew"),
                          heroTag: "campaignBtn1",
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
            );
          }
        }

        return BlocConsumer<OutreachCampaignBloc, OutreachCampaignState>(
          listener: blocListener,
          builder: blocBuilder,
        );
      },
    );
  }

  void _onScroll() {
    if (_isBottom) {
      _campaignBloc.add(OutreachCampaignFetch(start: campaigns.length));
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
    _scrollController.dispose();
    _horizontalController.dispose();
    super.dispose();
  }
}
