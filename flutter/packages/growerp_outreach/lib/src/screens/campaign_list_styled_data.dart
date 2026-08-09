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
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

import '../bloc/outreach_campaign_bloc.dart';
import 'package:growerp_outreach/l10n/generated/outreach_localizations.dart';

/// Returns column definitions for campaign list based on device type
List<StyledColumn> getCampaignListColumns(BuildContext context) {
  final localizations = OutreachLocalizations.of(context)!;
  bool isPhone = isAPhone(context);

  if (isPhone) {
    return [
      StyledColumn(header: '', flex: 1), // Avatar
      StyledColumn(header: localizations.tableHdrInfo, flex: 4),
      StyledColumn(header: '', flex: 1), // Actions
    ];
  }

  return [
    StyledColumn(header: localizations.tableHdrId, flex: 1),
    StyledColumn(header: localizations.tableHdrName, flex: 3),
    StyledColumn(header: localizations.tableHdrStatus, flex: 1),
    StyledColumn(header: localizations.tableHdrSent, flex: 1),
    StyledColumn(header: localizations.tableHdrResp, flex: 1),
    StyledColumn(header: localizations.tableHdrTargets, flex: 1),
    StyledColumn(header: localizations.tableHdrPlatforms, flex: 2),
    StyledColumn(header: '', flex: 1), // Actions
  ];
}

/// Formats backend status for display
/// 'MKTG_CAMP_PLANNED' -> 'Planned'
String _formatStatus(String status) {
  final cleaned = status.replaceFirst('MKTG_CAMP_', '');
  if (cleaned.isEmpty) return status;
  return cleaned[0].toUpperCase() + cleaned.substring(1).toLowerCase();
}

Color _getStatusColor(String status) {
  switch (status) {
    case 'MKTG_CAMP_ACTIVE':
      return Colors.green;
    case 'MKTG_CAMP_COMPLETED':
      return Colors.blue;
    case 'MKTG_CAMP_CANCELLED':
      return Colors.red;
    case 'MKTG_CAMP_PLANNED':
    default:
      return Colors.orange;
  }
}

/// Returns row data for campaign list
List<Widget> getCampaignListRow({
  required BuildContext context,
  required OutreachCampaign campaign,
  required int index,
  required OutreachCampaignBloc bloc,
}) {
  bool isPhone = isAPhone(context);

  Future<void> confirmDelete() async {
    if (campaign.campaignId == null) return;
    final shouldDelete = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
        title: Text(OutreachLocalizations.of(context)!.deleteCampaign),
        content: Text('Are you sure you want to delete "${campaign.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(OutreachLocalizations.of(context)!.cancel),
          ),
          TextButton(
            key: Key('deleteConfirm$index'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (shouldDelete == true) {
      bloc.add(OutreachCampaignDelete(campaign.campaignId!));
    }
  }

  List<Widget> cells = [];

  if (isPhone) {
    // Avatar
    cells.add(
      CircleAvatar(
        key: const Key('campaignItem'),
        child: Text(campaign.pseudoId?.lastChar(3) ?? '?'),
      ),
    );

    // Combined info cell
    cells.add(
      Column(
        key: Key('campaignInfo$index'),
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            campaign.name.truncate(25),
            key: Key('name$index'),
            style: const TextStyle(fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (campaign.pseudoId != null)
            Text(
              campaign.pseudoId!,
              key: Key('id$index'),
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _getStatusColor(campaign.status).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _formatStatus(campaign.status),
              key: Key('status$index'),
              style: TextStyle(
                fontSize: 11,
                color: _getStatusColor(campaign.status),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  } else {
    // ID (wrapped so the constant 'campaignItem' key is present on desktop too —
    // tests count it to determine the number of rows)
    cells.add(
      SizedBox(
        key: const Key('campaignItem'),
        child: Text(campaign.pseudoId ?? '', key: Key('id$index')),
      ),
    );

    // Name
    cells.add(
      Text(
        campaign.name,
        key: Key('name$index'),
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
    );

    // Status with color
    cells.add(
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _getStatusColor(campaign.status).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          _formatStatus(campaign.status),
          key: Key('status$index'),
          style: TextStyle(
            fontSize: 12,
            color: _getStatusColor(campaign.status),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );

    // Sent
    cells.add(
      Text(
        campaign.messagesSent.toString(),
        key: Key('sent$index'),
        textAlign: TextAlign.center,
      ),
    );

    // Responses
    cells.add(
      Text(
        campaign.responsesReceived.toString(),
        key: Key('resp$index'),
        textAlign: TextAlign.center,
      ),
    );

    // Targets (total uploaded outreach messages/prospects)
    cells.add(
      Text(
        campaign.numSent.toString(),
        key: Key('leads$index'),
        textAlign: TextAlign.center,
      ),
    );

    // Platforms
    cells.add(
      Text(
        campaign.platforms
            .replaceAll('[', '')
            .replaceAll(']', '')
            .replaceAll('"', ''),
        key: Key('platforms$index'),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  // Delete action
  cells.add(
    IconButton(
      key: Key('delete$index'),
      icon: const Icon(Icons.delete, color: Colors.red),
      tooltip: 'Delete campaign',
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      onPressed: campaign.campaignId == null ? null : confirmDelete,
    ),
  );

  return cells;
}
