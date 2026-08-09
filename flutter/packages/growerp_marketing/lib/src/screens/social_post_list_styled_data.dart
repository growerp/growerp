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
import 'package:intl/intl.dart';

import '../bloc/social_post_bloc.dart';
import '../bloc/social_post_event.dart';
import 'package:growerp_marketing/l10n/generated/marketing_localizations.dart';

/// Returns column definitions for social post list based on device type
List<StyledColumn> getSocialPostListColumns(BuildContext context) {
  final localizations = MarketingLocalizations.of(context)!;
  bool isPhone = isAPhone(context);

  if (isPhone) {
    return [
      StyledColumn(header: localizations.tableHdrId, flex: 1),
      StyledColumn(header: localizations.tableHdrInfo, flex: 4),
      StyledColumn(header: '', flex: 1), // Actions
    ];
  }

  return [
    StyledColumn(header: localizations.tableHdrId, flex: 1),
    StyledColumn(header: localizations.tableHdrType, flex: 1),
    StyledColumn(header: localizations.tableHdrHeadline, flex: 3),
    StyledColumn(header: localizations.tableHdrPlatform, flex: 1),
    StyledColumn(header: localizations.tableHdrStatus, flex: 1),
    StyledColumn(header: localizations.tableHdrScheduled, flex: 1),
    StyledColumn(header: '', flex: 1), // Actions
  ];
}

Color _getStatusColor(String status) {
  switch (status.toUpperCase()) {
    case 'PUBLISHED':
      return Colors.green;
    case 'SCHEDULED':
      return Colors.blue;
    case 'DRAFT':
      return Colors.orange;
    default:
      return Colors.grey;
  }
}

String _formatDate(DateTime? date) {
  if (date == null) return '-';
  return DateFormat('MMM d, yyyy').format(date);
}

/// Returns row data for social post list
List<Widget> getSocialPostListRow({
  required BuildContext context,
  required SocialPost post,
  required int index,
  required SocialPostBloc bloc,
}) {
  bool isPhone = isAPhone(context);

  Future<void> confirmDelete() async {
    if (post.postId == null) return;
    final shouldDelete = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
        title: Text(MarketingLocalizations.of(context)!.deleteSocialPost),
        content: Text(
          'Are you sure you want to delete post "${post.headline ?? post.pseudoId}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(MarketingLocalizations.of(context)!.cancel),
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
      bloc.add(SocialPostDelete(post));
    }
  }

  List<Widget> cells = [];

  if (isPhone) {
    // ID
    cells.add(Text(post.pseudoId ?? '', key: const Key('socialPostItem')));

    // Combined info cell
    cells.add(
      Column(
        key: Key('socialPostInfo$index'),
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            post.type,
            key: Key('type$index'),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Text(
            (post.headline ?? 'No headline').truncate(40),
            key: Key('headline$index'),
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _getStatusColor(post.status).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              post.status,
              style: TextStyle(
                fontSize: 10,
                color: _getStatusColor(post.status),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  } else {
    // ID
    cells.add(Text(post.pseudoId ?? '', key: const Key('socialPostItem')));

    // Type
    cells.add(
      Text(
        post.type,
        key: Key('type$index'),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );

    // Headline
    cells.add(
      Text(
        (post.headline ?? 'No headline').truncate(40),
        key: Key('headline$index'),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );

    // Platform
    cells.add(Text(post.platform ?? '-', key: Key('platform$index')));

    // Status with color
    cells.add(
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _getStatusColor(post.status).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          post.status,
          style: TextStyle(
            fontSize: 12,
            color: _getStatusColor(post.status),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );

    // Scheduled
    cells.add(
      Text(_formatDate(post.scheduledDate), key: Key('scheduledDate$index')),
    );
  }

  // Delete action
  cells.add(
    IconButton(
      key: Key('delete$index'),
      icon: const Icon(Icons.delete, color: Colors.red),
      tooltip: 'Delete social post',
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      onPressed: post.postId == null ? null : confirmDelete,
    ),
  );

  return cells;
}
