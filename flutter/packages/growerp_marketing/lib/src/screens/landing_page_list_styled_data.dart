/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 */

import 'package:flutter/material.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

import '../bloc/landing_page_bloc.dart';
import '../bloc/landing_page_event.dart';

/// Returns column definitions for landing page list based on device type
List<StyledColumn> getLandingPageListColumns(BuildContext context) {
  bool isPhone = isAPhone(context);

  if (isPhone) {
    return const [
      StyledColumn(header: '', flex: 1), // Avatar
      StyledColumn(header: 'Info', flex: 4),
      StyledColumn(header: '', flex: 1), // Actions
    ];
  }

  return const [
    StyledColumn(header: 'ID', flex: 1),
    StyledColumn(header: 'Title', flex: 2),
    StyledColumn(header: 'Headline', flex: 3),
    StyledColumn(header: 'Status', flex: 1),
    StyledColumn(header: 'Hook Type', flex: 1),
    StyledColumn(header: '', flex: 1), // Actions
  ];
}

Color _getStatusColor(String status) {
  switch (status.toUpperCase()) {
    case 'ACTIVE':
      return Colors.green;
    case 'PUBLISHED':
      return Colors.blue;
    case 'DRAFT':
      return Colors.orange;
    default:
      return Colors.red;
  }
}

/// Returns row data for landing page list
List<Widget> getLandingPageListRow({
  required BuildContext context,
  required LandingPage page,
  required int index,
  required LandingPageBloc bloc,
}) {
  bool isPhone = isAPhone(context);

  Future<void> confirmDelete() async {
    if (page.landingPageId == null) return;
    final shouldDelete = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Landing Page'),
        content: Text(
          'Are you sure you want to delete "${page.title}"?',
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
      bloc.add(LandingPageDelete(page.landingPageId!));
    }
  }

  List<Widget> cells = [];

  if (isPhone) {
    // Avatar
    cells.add(
      CircleAvatar(
        key: const Key('landingPageItem'),
        child: Text(page.pseudoId?.lastChar(3) ?? '?'),
      ),
    );

    // Combined info cell
    cells.add(
      Column(
        key: Key('landingPageInfo$index'),
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            page.title.truncate(25),
            key: Key('title$index'),
            style: const TextStyle(fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (page.pseudoId != null)
            Text(
              page.pseudoId!,
              key: Key('id$index'),
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _getStatusColor(page.status).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              page.status,
              key: Key('status$index'),
              style: TextStyle(
                fontSize: 11,
                color: _getStatusColor(page.status),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  } else {
    // ID
    cells.add(Text(page.pseudoId ?? '', key: Key('id$index')));

    // Title
    cells.add(
      Text(
        page.title,
        key: Key('title$index'),
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
    );

    // Headline
    cells.add(
      Text(
        page.headline ?? 'N/A',
        key: Key('headline$index'),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );

    // Status with color
    cells.add(
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _getStatusColor(page.status).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          page.status,
          key: Key('status$index'),
          style: TextStyle(
            fontSize: 12,
            color: _getStatusColor(page.status),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );

    // Hook Type
    cells.add(Text(page.hookType ?? 'N/A', key: Key('hookType$index')));
  }

  // Delete action
  cells.add(
    IconButton(
      key: Key('delete$index'),
      icon: const Icon(Icons.delete, color: Colors.red),
      tooltip: 'Delete landing page',
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      onPressed: page.landingPageId == null ? null : confirmDelete,
    ),
  );

  return cells;
}
