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

import '../bloc/master_content_bloc.dart';
import '../bloc/master_content_event.dart';

/// Returns column definitions for master content list based on device type
List<StyledColumn> getMasterContentListColumns(BuildContext context) {
  bool isPhone = isAPhone(context);

  if (isPhone) {
    return const [
      StyledColumn(header: 'ID', flex: 1),
      StyledColumn(header: 'Info', flex: 4),
      StyledColumn(header: '', flex: 1), // Actions
    ];
  }

  return const [
    StyledColumn(header: 'ID', flex: 1),
    StyledColumn(header: 'Type', flex: 1),
    StyledColumn(header: 'PNP', flex: 1),
    StyledColumn(header: 'Title', flex: 3),
    StyledColumn(header: 'Status', flex: 1),
    StyledColumn(header: '', flex: 1), // Actions
  ];
}

Color _getStatusColor(String status) {
  switch (status.toUpperCase()) {
    case 'ADAPTED':
      return Colors.green;
    case 'APPROVED':
      return Colors.blue;
    case 'DRAFT':
      return Colors.orange;
    default:
      return Colors.grey;
  }
}

/// Returns row data for master content list
List<Widget> getMasterContentListRow({
  required BuildContext context,
  required MasterContent content,
  required int index,
  required MasterContentBloc bloc,
}) {
  bool isPhone = isAPhone(context);

  Future<void> confirmDelete() async {
    if (content.masterContentId == null) return;
    final shouldDelete = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Master Content'),
        content: Text(
          'Are you sure you want to delete "${content.title ?? content.pseudoId}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
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
      bloc.add(MasterContentDelete(content));
    }
  }

  List<Widget> cells = [];

  if (isPhone) {
    cells.add(Text(content.pseudoId ?? '', key: const Key('masterContentItem')));
    cells.add(
      Column(
        key: Key('masterContentInfo$index'),
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${content.contentType} · ${content.pnpType}',
            key: Key('contentType$index'),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Text(
            (content.title ?? 'No title').truncate(40),
            key: Key('title$index'),
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color:
                      _getStatusColor(content.status).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  content.status,
                  style: TextStyle(
                    fontSize: 10,
                    color: _getStatusColor(content.status),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                content.approvedDate != null
                    ? Icons.check_circle
                    : Icons.hourglass_empty,
                key: Key('approvalIcon$index'),
                size: 14,
                color:
                    content.approvedDate != null ? Colors.green : Colors.grey,
              ),
            ],
          ),
        ],
      ),
    );
  } else {
    cells.add(
        Text(content.pseudoId ?? '', key: const Key('masterContentItem')));
    cells.add(Text(content.contentType,
        key: Key('contentType$index'),
        style: const TextStyle(fontWeight: FontWeight.bold)));
    cells.add(Text(content.pnpType, key: Key('pnpType$index')));
    cells.add(
      Text(
        (content.title ?? 'No title').truncate(40),
        key: Key('title$index'),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
    cells.add(
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor(content.status).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              content.status,
              style: TextStyle(
                fontSize: 12,
                color: _getStatusColor(content.status),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            content.approvedDate != null
                ? Icons.check_circle
                : Icons.hourglass_empty,
            key: Key('approvalIcon$index'),
            size: 16,
            color: content.approvedDate != null ? Colors.green : Colors.grey,
          ),
        ],
      ),
    );
  }

  cells.add(
    IconButton(
      key: Key('delete$index'),
      icon: const Icon(Icons.delete, color: Colors.red),
      tooltip: 'Delete master content',
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      onPressed: content.masterContentId == null ? null : confirmDelete,
    ),
  );

  return cells;
}
