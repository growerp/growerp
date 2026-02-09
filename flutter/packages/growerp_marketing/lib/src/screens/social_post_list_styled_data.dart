/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 */

import 'package:flutter/material.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:intl/intl.dart';

import '../bloc/social_post_bloc.dart';
import '../bloc/social_post_event.dart';

/// Returns column definitions for social post list based on device type
List<StyledColumn> getSocialPostListColumns(BuildContext context) {
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
    StyledColumn(header: 'Headline', flex: 3),
    StyledColumn(header: 'Platform', flex: 1),
    StyledColumn(header: 'Status', flex: 1),
    StyledColumn(header: 'Scheduled', flex: 1),
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
        title: const Text('Delete Social Post'),
        content: Text(
          'Are you sure you want to delete post "${post.headline ?? post.pseudoId}"?',
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
      bloc.add(SocialPostDelete(post));
    }
  }

  List<Widget> cells = [];

  if (isPhone) {
    // ID
    cells.add(
      Text(
        post.pseudoId ?? '',
        key: const Key('socialPostItem'),
      ),
    );

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
        Text(_formatDate(post.scheduledDate), key: Key('scheduledDate$index')));
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
