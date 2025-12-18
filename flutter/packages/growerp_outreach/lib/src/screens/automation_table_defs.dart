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
import 'package:intl/intl.dart';
import '../bloc/outreach_campaign_bloc.dart';

/// Formats backend status for display
/// 'MKTG_CAMP_PLANNED' -> 'Planned'
String _formatStatus(String status) {
  final cleaned = status.replaceFirst('MKTG_CAMP_', '');
  if (cleaned.isEmpty) return status;
  return cleaned[0].toUpperCase() + cleaned.substring(1).toLowerCase();
}

/// Check if campaign is in an active/running state
bool _isActiveStatus(String status) {
  return status == 'MKTG_CAMP_INPROGRESS' || status == 'MKTG_CAMP_APPROVED';
}

/// Check if campaign is in failed state
bool _isFailedStatus(String status) {
  return status == 'MKTG_CAMP_FAILED';
}

/// Get status color based on campaign status
Color _getStatusColor(String status) {
  switch (status) {
    case 'MKTG_CAMP_INPROGRESS':
      return Colors.green;
    case 'MKTG_CAMP_APPROVED':
      return Colors.blue;
    case 'MKTG_CAMP_COMPLETED':
      return Colors.purple;
    case 'MKTG_CAMP_CANCELLED':
      return Colors.grey;
    case 'MKTG_CAMP_FAILED':
      return Colors.red;
    case 'MKTG_CAMP_PLANNED':
    default:
      return Colors.orange;
  }
}

TableData getActiveCampaignsTableData(Bloc bloc, String classificationId,
    BuildContext context, OutreachCampaign item, int index,
    {dynamic extra}) {
  bool isPhone = isAPhone(context);
  final isActive = _isActiveStatus(item.status);
  final isFailed = _isFailedStatus(item.status);

  List<TableRowContent> rowContent = [];
  if (isPhone) {
    rowContent.add(TableRowContent(
      name: 'Campaign',
      width: 40,
      value: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(_formatStatus(item.status),
              style: TextStyle(color: _getStatusColor(item.status))),
        ],
      ),
    ));
    rowContent.add(TableRowContent(
      name: 'Action',
      width: 20,
      value: IconButton(
        icon: Icon(
            isFailed
                ? Icons.replay
                : isActive
                    ? Icons.pause_circle_outline
                    : Icons.play_circle_outline,
            color: isFailed
                ? Colors.red
                : isActive
                    ? Colors.orange
                    : Colors.green),
        tooltip: isFailed
            ? 'Restart'
            : isActive
                ? 'Pause'
                : 'Start',
        onPressed: () {
          if (item.campaignId != null) {
            final outreachBloc = bloc as OutreachCampaignBloc;
            if (isFailed) {
              // Restart: change status to APPROVED to trigger re-run
              outreachBloc.add(OutreachCampaignUpdate(
                campaignId: item.campaignId!,
                status: 'MKTG_CAMP_APPROVED',
              ));
            } else if (isActive) {
              outreachBloc.add(OutreachCampaignPause(item.campaignId!));
            } else {
              outreachBloc.add(OutreachCampaignStart(item.campaignId!));
            }
          }
        },
      ),
    ));
  } else {
    rowContent.add(TableRowContent(
        name: 'Name',
        width: 20,
        value: Text(item.name, key: Key('name$index'))));
    rowContent.add(TableRowContent(
        name: 'Status',
        width: 10,
        value: Text(_formatStatus(item.status),
            style: TextStyle(color: _getStatusColor(item.status)))));
    rowContent.add(TableRowContent(
      name: 'Action',
      width: 10,
      value: IconButton(
        icon: Icon(
            isFailed
                ? Icons.replay
                : isActive
                    ? Icons.pause_circle_outline
                    : Icons.play_circle_outline,
            color: isFailed
                ? Colors.red
                : isActive
                    ? Colors.orange
                    : Colors.green),
        tooltip: isFailed
            ? 'Restart'
            : isActive
                ? 'Pause'
                : 'Start',
        onPressed: () {
          if (item.campaignId != null) {
            final outreachBloc = bloc as OutreachCampaignBloc;
            if (isFailed) {
              outreachBloc.add(OutreachCampaignUpdate(
                campaignId: item.campaignId!,
                status: 'MKTG_CAMP_APPROVED',
              ));
            } else if (isActive) {
              outreachBloc.add(OutreachCampaignPause(item.campaignId!));
            } else {
              outreachBloc.add(OutreachCampaignStart(item.campaignId!));
            }
          }
        },
      ),
    ));
  }

  return TableData(
    rowHeight: isPhone ? 60 : 50,
    rowContent: rowContent,
  );
}

TableData getRecentActivityTableData(Bloc bloc, String classificationId,
    BuildContext context, OutreachMessage item, int index,
    {dynamic extra}) {
  bool isPhone = isAPhone(context);

  // Format the sent date/time
  final timeStr = item.sentDate != null
      ? DateFormat('MMM d, HH:mm').format(item.sentDate!)
      : '';

  List<TableRowContent> rowContent = [];
  if (isPhone) {
    rowContent.add(TableRowContent(
      name: 'Message',
      width: 60,
      value: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.recipientName ?? 'Unknown',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          Text('${item.platform} • ${item.status} • $timeStr',
              style: TextStyle(
                  fontSize: 12,
                  color: item.status == 'FAILED' ? Colors.red : Colors.grey)),
        ],
      ),
    ));
  } else {
    rowContent.add(TableRowContent(
        name: 'Recipient',
        width: 15,
        value: Text(item.recipientName ?? 'Unknown')));
    rowContent.add(TableRowContent(
        name: 'Platform', width: 10, value: Text(item.platform)));
    rowContent.add(TableRowContent(
        name: 'Status',
        width: 10,
        value: Text(item.status,
            style: TextStyle(
                color: item.status == 'FAILED'
                    ? Colors.red
                    : item.status == 'SENT'
                        ? Colors.green
                        : Colors.grey))));
    rowContent.add(TableRowContent(
        name: 'Time',
        width: 12,
        value: Text(timeStr, style: const TextStyle(fontSize: 12))));
    rowContent.add(TableRowContent(
        name: 'Error',
        width: 15,
        value: Text(item.errorMessage ?? '',
            style: const TextStyle(color: Colors.red),
            overflow: TextOverflow.ellipsis)));
  }

  return TableData(
    rowHeight: isPhone ? 60 : 40,
    rowContent: rowContent,
  );
}
