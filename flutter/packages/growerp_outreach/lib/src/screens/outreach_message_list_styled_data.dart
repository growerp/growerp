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

import '../bloc/outreach_message_bloc.dart';
import '../bloc/outreach_message_event.dart';
import 'package:growerp_outreach/l10n/generated/outreach_localizations.dart';

/// Returns column definitions for outreach message list based on device type
List<StyledColumn> getOutreachMessageListColumns(BuildContext context) {
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
    StyledColumn(header: localizations.tableHdrRecipient, flex: 2),
    StyledColumn(header: localizations.tableHdrPlatform, flex: 1),
    StyledColumn(header: localizations.tableHdrMessage, flex: 3),
    StyledColumn(header: localizations.tableHdrSentDate, flex: 1),
    StyledColumn(header: localizations.tableHdrStatus, flex: 1),
    StyledColumn(header: '', flex: 1), // Actions
  ];
}

Color _getStatusColor(String status) {
  switch (status.toUpperCase()) {
    case 'SENT':
      return Colors.green;
    case 'RESPONDED':
      return Colors.blue;
    case 'FAILED':
      return Colors.red;
    case 'PENDING':
    default:
      return Colors.orange;
  }
}

String _formatDate(BuildContext context, DateTime? date) {
  if (date == null) return 'N/A';
  return date.toLocalizedString(context, format: 'MMM dd, yyyy');
}

/// Returns row data for outreach message list
List<Widget> getOutreachMessageListRow({
  required BuildContext context,
  required OutreachMessage message,
  required int index,
  required OutreachMessageBloc bloc,
}) {
  bool isPhone = isAPhone(context);

  Future<void> confirmDelete() async {
    if (message.messageId == null) return;
    final shouldDelete = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
        title: Text(OutreachLocalizations.of(context)!.deleteMessage),
        content: Text(
          'Are you sure you want to delete this message to "${message.recipientName ?? message.recipientEmail ?? "Unknown"}"?',
        ),
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
      bloc.add(OutreachMessageDelete(message.messageId!));
    }
  }

  List<Widget> cells = [];

  if (isPhone) {
    // Avatar
    cells.add(
      CircleAvatar(
        key: const Key('messageItem'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Text(message.platform.substring(0, 1)),
      ),
    );

    // Combined info cell
    cells.add(
      Column(
        key: Key('messageInfo$index'),
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            (message.recipientName ?? message.recipientEmail ?? 'Unknown')
                .truncate(25),
            key: Key('recipient$index'),
            style: const TextStyle(fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            message.platform,
            key: Key('platform$index'),
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _getStatusColor(message.status).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              message.status,
              key: Key('status$index'),
              style: TextStyle(
                fontSize: 11,
                color: _getStatusColor(message.status),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  } else {
    // Recipient
    cells.add(
      Text(
        message.recipientName ?? message.recipientEmail ?? 'Unknown',
        key: Key('recipient$index'),
        style: const TextStyle(fontWeight: FontWeight.w500),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );

    // Platform
    cells.add(Text(message.platform, key: Key('platform$index')));

    // Message content
    cells.add(
      Text(
        message.messageContent,
        key: Key('message$index'),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );

    // Sent Date
    cells.add(
      Text(_formatDate(context, message.sentDate), key: Key('sentDate$index')),
    );

    // Status with color
    cells.add(
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _getStatusColor(message.status).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          message.status,
          key: Key('status$index'),
          style: TextStyle(
            fontSize: 12,
            color: _getStatusColor(message.status),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // Delete action
  cells.add(
    IconButton(
      key: Key('delete$index'),
      icon: const Icon(Icons.delete, color: Colors.red),
      tooltip: 'Delete message',
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      onPressed: message.messageId == null ? null : confirmDelete,
    ),
  );

  return cells;
}
