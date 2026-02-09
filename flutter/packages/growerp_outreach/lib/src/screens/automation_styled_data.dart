/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 */

import 'package:flutter/material.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:intl/intl.dart';
import '../bloc/outreach_campaign_bloc.dart';

String _formatStatus(String status) {
  final cleaned = status.replaceFirst('MKTG_CAMP_', '');
  if (cleaned.isEmpty) return status;
  return cleaned[0].toUpperCase() + cleaned.substring(1).toLowerCase();
}

bool _isActiveStatus(String status) {
  return status == 'MKTG_CAMP_INPROGRESS' || status == 'MKTG_CAMP_APPROVED';
}

bool _isFailedStatus(String status) {
  return status == 'MKTG_CAMP_FAILED';
}

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

List<StyledColumn> getCampaignColumns(BuildContext context) {
  bool isPhone = isAPhone(context);
  if (isPhone) {
    return [
      const StyledColumn(header: 'Campaign', flex: 3),
      const StyledColumn(header: 'Action', flex: 1),
    ];
  }
  return [
    const StyledColumn(header: 'Name', flex: 2),
    const StyledColumn(header: 'Status', flex: 1),
    const StyledColumn(header: 'Action', flex: 1),
  ];
}

List<Widget> getCampaignRow({
  required BuildContext context,
  required OutreachCampaign campaign,
  required int index,
  required OutreachCampaignBloc bloc,
}) {
  bool isPhone = isAPhone(context);
  final isActive = _isActiveStatus(campaign.status);
  final isFailed = _isFailedStatus(campaign.status);

  if (isPhone) {
    return [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            campaign.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            _formatStatus(campaign.status),
            style: TextStyle(color: _getStatusColor(campaign.status)),
          ),
        ],
      ),
      IconButton(
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
              : Colors.green,
        ),
        onPressed: () {
          if (campaign.campaignId != null) {
            if (isFailed) {
              bloc.add(
                OutreachCampaignUpdate(
                  campaignId: campaign.campaignId!,
                  status: 'MKTG_CAMP_APPROVED',
                ),
              );
            } else if (isActive) {
              bloc.add(OutreachCampaignPause(campaign.campaignId!));
            } else {
              bloc.add(OutreachCampaignStart(campaign.campaignId!));
            }
          }
        },
      ),
    ];
  }
  return [
    Text(campaign.name, key: Key('name$index')),
    Text(
      _formatStatus(campaign.status),
      style: TextStyle(color: _getStatusColor(campaign.status)),
    ),
    IconButton(
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
            : Colors.green,
      ),
      onPressed: () {
        if (campaign.campaignId != null) {
          if (isFailed) {
            bloc.add(
              OutreachCampaignUpdate(
                campaignId: campaign.campaignId!,
                status: 'MKTG_CAMP_APPROVED',
              ),
            );
          } else if (isActive) {
            bloc.add(OutreachCampaignPause(campaign.campaignId!));
          } else {
            bloc.add(OutreachCampaignStart(campaign.campaignId!));
          }
        }
      },
    ),
  ];
}

List<StyledColumn> getMessageColumns(BuildContext context) {
  bool isPhone = isAPhone(context);
  if (isPhone) {
    return [const StyledColumn(header: 'Message', flex: 1)];
  }
  return [
    const StyledColumn(header: 'Recipient', flex: 2),
    const StyledColumn(header: 'Platform', flex: 1),
    const StyledColumn(header: 'Status', flex: 1),
    const StyledColumn(header: 'Time', flex: 1),
    const StyledColumn(header: 'Error', flex: 2),
  ];
}

List<Widget> getMessageRow({
  required BuildContext context,
  required OutreachMessage message,
  required int index,
}) {
  bool isPhone = isAPhone(context);
  final timeStr = message.sentDate != null
      ? DateFormat('MMM d, HH:mm').format(message.sentDate!)
      : '';

  if (isPhone) {
    return [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            message.recipientName ?? 'Unknown',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            '${message.platform} • ${message.status} • $timeStr',
            style: TextStyle(
              fontSize: 12,
              color: message.status == 'FAILED' ? Colors.red : Colors.grey,
            ),
          ),
        ],
      ),
    ];
  }
  return [
    Text(message.recipientName ?? 'Unknown'),
    Text(message.platform),
    Text(
      message.status,
      style: TextStyle(
        color: message.status == 'FAILED'
            ? Colors.red
            : message.status == 'SENT'
            ? Colors.green
            : Colors.grey,
      ),
    ),
    Text(timeStr, style: const TextStyle(fontSize: 12)),
    Text(
      message.errorMessage ?? '',
      style: const TextStyle(color: Colors.red),
      overflow: TextOverflow.ellipsis,
    ),
  ];
}
