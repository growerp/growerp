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
import 'package:responsive_framework/responsive_framework.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

import '../bloc/outreach_campaign_bloc.dart';
import 'automation_table_defs.dart';

class AutomationScreen extends StatefulWidget {
  const AutomationScreen({super.key});

  @override
  State<AutomationScreen> createState() => _AutomationScreenState();
}

class _AutomationScreenState extends State<AutomationScreen> {
  final _campaignsScrollController = ScrollController();
  final _campaignsHorizontalController = ScrollController();
  final _messagesScrollController = ScrollController();
  final _messagesHorizontalController = ScrollController();

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    context.read<OutreachCampaignBloc>().add(
          const OutreachCampaignFetch(status: 'ACTIVE'),
        );
    context.read<OutreachCampaignBloc>().add(
          OutreachRecentMessagesFetch(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = ResponsiveBreakpoints.of(context).isMobile;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _refreshData,
        tooltip: 'Refresh',
        child: const Icon(Icons.refresh),
      ),
      body: BlocConsumer<OutreachCampaignBloc, OutreachCampaignState>(
        listener: (context, state) {
          if (state.status == OutreachCampaignStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message ?? 'An error occurred')),
            );
          }
        },
        builder: (context, state) {
          if (state.status == OutreachCampaignStatus.loading &&
              state.campaigns.isEmpty &&
              state.messages.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          Widget activeCampaignsTable() {
            if (state.campaigns.isEmpty) {
              return const Center(child: Text('No active campaigns'));
            }
            var (
              List<List<TableViewCell>> tableViewCells,
              List<double> fieldWidths,
              double? rowHeight,
            ) = get2dTableData<OutreachCampaign>(
              getActiveCampaignsTableData,
              bloc: context.read<OutreachCampaignBloc>(),
              classificationId: 'AppAdmin',
              context: context,
              items: state.campaigns,
            );

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('Active Campaigns',
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                Expanded(
                  child: TableView.builder(
                    diagonalDragBehavior: DiagonalDragBehavior.free,
                    verticalDetails: ScrollableDetails.vertical(
                        controller: _campaignsScrollController),
                    horizontalDetails: ScrollableDetails.horizontal(
                        controller: _campaignsHorizontalController),
                    cellBuilder: (context, vicinity) =>
                        tableViewCells[vicinity.row][vicinity.column],
                    columnBuilder: (index) => index >= tableViewCells[0].length
                        ? null
                        : TableSpan(
                            padding: const SpanPadding(trailing: 5, leading: 5),
                            extent: FixedTableSpanExtent(fieldWidths[index]),
                            backgroundDecoration: SpanDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .tertiaryContainer),
                          ),
                    rowBuilder: (index) => index >= tableViewCells.length
                        ? null
                        : TableSpan(
                            padding: const SpanPadding(trailing: 5, leading: 5),
                            extent: FixedTableSpanExtent(rowHeight!),
                          ),
                    pinnedRowCount: 1,
                  ),
                ),
              ],
            );
          }

          Widget recentActivityTable() {
            if (state.messages.isEmpty) {
              return const Center(child: Text('No recent activity'));
            }
            var (
              List<List<TableViewCell>> tableViewCells,
              List<double> fieldWidths,
              double? rowHeight,
            ) = get2dTableData<OutreachMessage>(
              getRecentActivityTableData,
              bloc: context.read<OutreachCampaignBloc>(),
              classificationId: 'AppAdmin',
              context: context,
              items: state.messages,
            );

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('Recent Activity',
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                Expanded(
                  child: TableView.builder(
                    diagonalDragBehavior: DiagonalDragBehavior.free,
                    verticalDetails: ScrollableDetails.vertical(
                        controller: _messagesScrollController),
                    horizontalDetails: ScrollableDetails.horizontal(
                        controller: _messagesHorizontalController),
                    cellBuilder: (context, vicinity) =>
                        tableViewCells[vicinity.row][vicinity.column],
                    columnBuilder: (index) => index >= tableViewCells[0].length
                        ? null
                        : TableSpan(
                            padding: const SpanPadding(trailing: 5, leading: 5),
                            extent: FixedTableSpanExtent(fieldWidths[index]),
                            backgroundDecoration: SpanDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .tertiaryContainer),
                          ),
                    rowBuilder: (index) => index >= tableViewCells.length
                        ? null
                        : TableSpan(
                            padding: const SpanPadding(trailing: 5, leading: 5),
                            extent: FixedTableSpanExtent(rowHeight!),
                          ),
                    pinnedRowCount: 1,
                  ),
                ),
              ],
            );
          }

          if (isPhone) {
            return Column(
              children: [
                Expanded(child: activeCampaignsTable()),
                const Divider(),
                Expanded(child: recentActivityTable()),
              ],
            );
          } else {
            return Row(
              children: [
                Expanded(child: activeCampaignsTable()),
                const VerticalDivider(),
                Expanded(child: recentActivityTable()),
              ],
            );
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _campaignsScrollController.dispose();
    _campaignsHorizontalController.dispose();
    _messagesScrollController.dispose();
    _messagesHorizontalController.dispose();
    super.dispose();
  }
}
