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

import '../bloc/outreach_message_bloc.dart';
import '../bloc/outreach_message_event.dart';

TableData getOutreachMessageListTableData(Bloc bloc, String classificationId,
    BuildContext context, OutreachMessage item, int index,
    {dynamic extra}) {
  bool isPhone = isAPhone(context);
  final OutreachMessageBloc? messageBloc =
      bloc is OutreachMessageBloc ? bloc : null;

  Future<void> confirmDelete() async {
    if (messageBloc == null || item.messageId == null) return;
    final shouldDelete = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: Text(
          'Are you sure you want to delete this message to ${item.recipientName ?? item.recipientEmail ?? "Unknown"}?',
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
      messageBloc.add(OutreachMessageDelete(item.messageId!));
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
        tooltip: 'Delete message',
        icon: const Icon(Icons.delete),
        color: Colors.red.shade600,
        onPressed: item.messageId == null
            ? null
            : () {
                confirmDelete();
              },
      ),
    );
  }

  Color getStatusColor(String status) {
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

  String formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('MMM dd, yyyy').format(date);
  }

  List<TableRowContent> rowContent = [];
  if (isPhone) {
    rowContent.add(TableRowContent(
      name: 'Platform',
      width: 15,
      value: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Text(
          item.platform.substring(0, 1),
          key: const Key('messageItem'),
        ),
      ),
    ));
    rowContent.add(TableRowContent(
        name: const Text('Recipient\\nPlatform\\nStatus',
            textAlign: TextAlign.start),
        width: 65,
        value: Column(
          key: Key('item$index'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.recipientName ?? item.recipientEmail ?? 'Unknown',
              key: Key('recipient$index'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              item.platform,
              key: Key('platform$index'),
              style: const TextStyle(fontSize: 12),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: getStatusColor(item.status),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                item.status,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
                key: Key('status$index'),
              ),
            ),
          ],
        )));
  } else {
    rowContent.add(TableRowContent(
        name: const Text('Recipient', textAlign: TextAlign.start),
        width: 15,
        value: Text(
          item.recipientName ?? item.recipientEmail ?? 'Unknown',
          key: Key('recipient$index'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        )));
    rowContent.add(TableRowContent(
        name: const Text('Platform', textAlign: TextAlign.start),
        width: 10,
        value: Text(
          item.platform,
          key: Key('platform$index'),
        )));
    rowContent.add(TableRowContent(
        name: const Text('Message', textAlign: TextAlign.start),
        width: 25,
        value: Text(
          item.messageContent,
          key: Key('message$index'),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        )));
    rowContent.add(TableRowContent(
        name: const Text('Sent Date', textAlign: TextAlign.start),
        width: 12,
        value: Text(
          formatDate(item.sentDate),
          key: Key('sentDate$index'),
        )));
    rowContent.add(TableRowContent(
        name: const Text('Status', textAlign: TextAlign.start),
        width: 10,
        value: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: getStatusColor(item.status),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            item.status,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
            key: Key('status$index'),
          ),
        )));
    rowContent.add(buildDeleteAction());
  }
  if (isPhone) {
    rowContent.add(buildDeleteAction(width: 15, showLabel: false));
  }
  return TableData(
    rowHeight: isPhone ? 65 : 20,
    rowContent: rowContent,
  );
}
