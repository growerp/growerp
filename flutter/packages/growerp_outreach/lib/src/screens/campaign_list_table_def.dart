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

import '../bloc/outreach_campaign_bloc.dart';

/// Formats backend status for display
/// 'MKTG_CAMP_PLANNED' -> 'Planned'
String _formatStatus(String status) {
  final cleaned = status.replaceFirst('MKTG_CAMP_', '');
  if (cleaned.isEmpty) return status;
  return cleaned[0].toUpperCase() + cleaned.substring(1).toLowerCase();
}

TableData getCampaignListTableData(
  Bloc bloc,
  String classificationId,
  BuildContext context,
  OutreachCampaign campaign,
  int index, {
  dynamic extra,
}) {
  final isPhone = ResponsiveBreakpoints.of(context).isMobile;
  final OutreachCampaignBloc? campaignBloc =
      bloc is OutreachCampaignBloc ? bloc : null;

  Future<void> confirmDelete() async {
    if (campaignBloc == null || campaign.campaignId == null) return;
    final shouldDelete = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: const Text('Delete Campaign'),
        content: Text(
          'Are you sure you want to delete "${campaign.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            key: Key('deleteConfirm$index'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (shouldDelete == true) {
      campaignBloc.add(OutreachCampaignDelete(campaign.campaignId!));
    }
  }

  TableRowContent buildDeleteAction(
      {double width = 10, bool showLabel = true}) {
    return TableRowContent(
      name: showLabel
          ? const Text('Actions', textAlign: TextAlign.start)
          : const Text(''),
      width: width,
      value: IconButton(
        key: Key('delete$index'),
        tooltip: 'Delete campaign',
        icon: const Icon(Icons.delete),
        color: Colors.red.shade600,
        onPressed: campaign.campaignId == null
            ? null
            : () {
                confirmDelete();
              },
      ),
    );
  }

  List<TableRowContent> rowContent = [];
  if (isPhone) {
    rowContent.add(TableRowContent(
      name: 'ID',
      width: 15,
      value: CircleAvatar(
        child: Text(
          campaign.pseudoId == null ? '' : campaign.pseudoId!.lastChar(3),
          key: const Key('campaignItem'),
        ),
      ),
    ));
    rowContent.add(TableRowContent(
        name: const Text('ID\nName\nStatus', textAlign: TextAlign.start),
        width: 65,
        value: Column(
          key: Key('item$index'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(campaign.pseudoId ?? '', key: Key('id$index')),
            Text(campaign.name.truncate(25), key: Key('name$index')),
            Text(_formatStatus(campaign.status), key: Key('status$index')),
          ],
        )));
    rowContent.add(buildDeleteAction(width: 20));
  } else {
    rowContent.add(TableRowContent(
      name: 'ID',
      width: 8,
      value: Text(
        campaign.pseudoId ?? '',
        key: Key('id${campaign.pseudoId}'),
      ),
    ));
    rowContent.add(TableRowContent(
      name: 'Name',
      width: 30,
      value: Text(
        campaign.name,
        key: Key('name${campaign.pseudoId}'),
      ),
    ));
    rowContent.add(TableRowContent(
      name: 'Status',
      width: 10,
      value: Text(
        _formatStatus(campaign.status),
        key: Key('status${campaign.pseudoId}'),
      ),
    ));
    rowContent.add(TableRowContent(
      name: 'Sent',
      width: 8,
      value: Text(
        campaign.messagesSent.toString(),
        key: Key('sent${campaign.pseudoId}'),
      ),
    ));
    rowContent.add(TableRowContent(
      name: 'Resp',
      width: 8,
      value: Text(
        campaign.responsesReceived.toString(),
        key: Key('resp${campaign.pseudoId}'),
      ),
    ));
    rowContent.add(TableRowContent(
      name: 'Leads',
      width: 8,
      value: Text(
        campaign.leadsGenerated.toString(),
        key: Key('leads${campaign.pseudoId}'),
      ),
    ));
    rowContent.add(TableRowContent(
      name: 'Platforms',
      width: 20,
      value: Text(
        campaign.platforms
            .replaceAll('[', '')
            .replaceAll(']', '')
            .replaceAll('"', ''),
        key: Key('platforms${campaign.pseudoId}'),
        overflow: TextOverflow.ellipsis,
      ),
    ));
    rowContent.add(buildDeleteAction(width: 8));
  }

  return TableData(
    rowHeight: isPhone ? 80 : 50,
    rowContent: rowContent,
  );
}
