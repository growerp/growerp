/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../bloc/outreach_campaign_bloc.dart';
import 'automation_styled_data.dart';

class AutomationScreen extends StatefulWidget {
  const AutomationScreen({super.key});

  @override
  State<AutomationScreen> createState() => _AutomationScreenState();
}

class _AutomationScreenState extends State<AutomationScreen> {
  final _campaignsScrollController = ScrollController();
  final _messagesScrollController = ScrollController();

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
      const OutreachRecentMessagesFetch(),
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
            final rows = state.campaigns.map((campaign) {
              final index = state.campaigns.indexOf(campaign);
              return getCampaignRow(
                context: context,
                campaign: campaign,
                index: index,
                bloc: context.read<OutreachCampaignBloc>(),
              );
            }).toList();

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Active Campaigns',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Expanded(
                  child: StyledDataTable(
                    columns: getCampaignColumns(context),
                    rows: rows,
                    scrollController: _campaignsScrollController,
                  ),
                ),
              ],
            );
          }

          Widget recentActivityTable() {
            if (state.messages.isEmpty) {
              return const Center(child: Text('No recent activity'));
            }
            final rows = state.messages.map((message) {
              final index = state.messages.indexOf(message);
              return getMessageRow(
                context: context,
                message: message,
                index: index,
              );
            }).toList();

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Recent Activity',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Expanded(
                  child: StyledDataTable(
                    columns: getMessageColumns(context),
                    rows: rows,
                    scrollController: _messagesScrollController,
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
    _messagesScrollController.dispose();
    super.dispose();
  }
}
