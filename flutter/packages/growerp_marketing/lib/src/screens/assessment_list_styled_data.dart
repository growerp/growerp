/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 */

import 'package:flutter/material.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

import '../bloc/assessment_bloc.dart';

/// Returns column definitions for assessment list based on device type
List<StyledColumn> getAssessmentListColumns(BuildContext context) {
  bool isPhone = isAPhone(context);

  if (isPhone) {
    return const [
      StyledColumn(header: '', flex: 1), // Avatar
      StyledColumn(header: 'Info', flex: 3),
      StyledColumn(header: '', flex: 1), // Actions
    ];
  }

  return const [
    StyledColumn(header: 'ID', flex: 1),
    StyledColumn(header: 'Name', flex: 2),
    StyledColumn(header: 'Description', flex: 3),
    StyledColumn(header: 'Status', flex: 1),
    StyledColumn(header: '', flex: 1), // Actions
  ];
}

Color _getStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'active':
      return Colors.green;
    case 'draft':
      return Colors.orange;
    default:
      return Colors.red;
  }
}

/// Returns row data for assessment list
List<Widget> getAssessmentListRow({
  required BuildContext context,
  required Assessment assessment,
  required int index,
  required AssessmentBloc bloc,
}) {
  bool isPhone = isAPhone(context);

  Future<void> confirmDelete() async {
    if (assessment.assessmentId == null) return;
    final shouldDelete = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Assessment'),
        content: Text(
          'Are you sure you want to delete "${assessment.assessmentName}"?',
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
      bloc.add(AssessmentDelete(assessment));
    }
  }

  List<Widget> cells = [];

  if (isPhone) {
    // Avatar
    cells.add(
      CircleAvatar(
        key: const Key('assessmentItem'),
        child: Text(
          (assessment.pseudoId ?? assessment.assessmentId ?? 'N/A').lastChar(3),
        ),
      ),
    );

    // Combined info cell
    cells.add(
      Column(
        key: Key('assessmentInfo$index'),
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            assessment.assessmentName.truncate(25),
            key: Key('name$index'),
            style: const TextStyle(fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            assessment.pseudoId ?? assessment.assessmentId ?? 'N/A',
            key: Key('id$index'),
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _getStatusColor(assessment.status).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              assessment.status,
              key: Key('status$index'),
              style: TextStyle(
                fontSize: 11,
                color: _getStatusColor(assessment.status),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  } else {
    // ID
    cells.add(
      Text(
        assessment.pseudoId ?? assessment.assessmentId ?? 'N/A',
        key: Key('id$index'),
      ),
    );

    // Name
    cells.add(
      Text(
        assessment.assessmentName,
        key: Key('name$index'),
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
    );

    // Description
    cells.add(
      Text(
        assessment.description ?? 'N/A',
        key: Key('description$index'),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );

    // Status with color
    cells.add(
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _getStatusColor(assessment.status).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          assessment.status,
          key: Key('status$index'),
          style: TextStyle(
            fontSize: 12,
            color: _getStatusColor(assessment.status),
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
      icon: const Icon(Icons.delete_forever, color: Colors.red),
      tooltip: 'Delete assessment',
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      onPressed: assessment.assessmentId == null ? null : confirmDelete,
    ),
  );

  return cells;
}
