/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 */

import 'package:flutter/material.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:intl/intl.dart';

import '../bloc/content_plan_bloc.dart';
import '../bloc/content_plan_event.dart';

/// Returns column definitions for content plan list based on device type
List<StyledColumn> getContentPlanListColumns(BuildContext context) {
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
    StyledColumn(header: 'Theme', flex: 3),
    StyledColumn(header: 'Week Start', flex: 1),
    StyledColumn(header: 'Persona', flex: 1),
    StyledColumn(header: 'Modified', flex: 1),
    StyledColumn(header: '', flex: 1), // Actions
  ];
}

String _formatDate(DateTime? date) {
  if (date == null) return 'N/A';
  return DateFormat('MMM d, yyyy').format(date);
}

/// Returns row data for content plan list
List<Widget> getContentPlanListRow({
  required BuildContext context,
  required ContentPlan plan,
  required int index,
  required ContentPlanBloc bloc,
}) {
  bool isPhone = isAPhone(context);

  Future<void> confirmDelete() async {
    if (plan.planId == null) return;
    final shouldDelete = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Content Plan'),
        content: Text(
          'Are you sure you want to delete plan "${plan.theme ?? plan.pseudoId}"?',
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
      bloc.add(ContentPlanDelete(plan));
    }
  }

  List<Widget> cells = [];

  if (isPhone) {
    // Avatar
    cells.add(
      CircleAvatar(
        key: const Key('contentPlanItem'),
        child: Text(plan.pseudoId?.lastChar(3) ?? '?'),
      ),
    );

    // Combined info cell
    cells.add(
      Column(
        key: Key('contentPlanInfo$index'),
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            (plan.theme ?? 'No theme').truncate(25),
            key: Key('theme$index'),
            style: const TextStyle(fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (plan.pseudoId != null)
            Text(
              plan.pseudoId!,
              key: Key('id$index'),
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          Text(
            _formatDate(plan.weekStartDate),
            key: Key('weekStartDate$index'),
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  } else {
    // ID
    cells.add(Text(plan.pseudoId ?? '', key: Key('id$index')));

    // Theme
    cells.add(
      Text(
        plan.theme ?? 'No theme',
        key: const Key('contentPlanItem'),
        style: const TextStyle(fontWeight: FontWeight.w500),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );

    // Week Start
    cells.add(
        Text(_formatDate(plan.weekStartDate), key: Key('weekStartDate$index')));

    // Persona ID
    cells.add(Text(plan.personaId ?? 'N/A', key: Key('personaId$index')));

    // Modified
    cells.add(Text(_formatDate(plan.lastModifiedDate),
        key: Key('lastModifiedDate$index')));
  }

  // Delete action
  cells.add(
    IconButton(
      key: Key('delete$index'),
      icon: const Icon(Icons.delete, color: Colors.red),
      tooltip: 'Delete content plan',
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      onPressed: plan.planId == null ? null : confirmDelete,
    ),
  );

  return cells;
}
