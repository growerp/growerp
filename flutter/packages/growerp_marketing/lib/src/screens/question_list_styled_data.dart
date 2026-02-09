/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 */

import 'package:flutter/material.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

import '../bloc/question_bloc.dart';
import '../bloc/question_event.dart';

/// Returns column definitions for question list based on device type
List<StyledColumn> getQuestionListColumns(BuildContext context) {
  bool isPhone = isAPhone(context);

  if (isPhone) {
    return const [
      StyledColumn(header: '', flex: 1), // Sequence
      StyledColumn(header: 'Info', flex: 4),
      StyledColumn(header: '', flex: 1), // Actions
    ];
  }

  return const [
    StyledColumn(header: '#', flex: 1),
    StyledColumn(header: 'Question Text', flex: 4),
    StyledColumn(header: 'Type', flex: 1),
    StyledColumn(header: 'Options', flex: 1),
    StyledColumn(header: '', flex: 1), // Actions
  ];
}

/// Returns row data for question list
List<Widget> getQuestionListRow({
  required BuildContext context,
  required AssessmentQuestion question,
  required int index,
  required QuestionBloc bloc,
}) {
  bool isPhone = isAPhone(context);

  Future<void> confirmDelete() async {
    if (question.assessmentQuestionId == null) return;
    final shouldDelete = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Question'),
        content: const Text(
          'Are you sure you want to delete this question?',
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
      bloc.add(QuestionDelete(question.assessmentQuestionId ?? ''));
    }
  }

  List<Widget> cells = [];

  if (isPhone) {
    // Sequence number
    cells.add(
      CircleAvatar(
        key: const Key('questionItem'),
        child: Text('${question.questionSequence ?? index + 1}'),
      ),
    );

    // Combined info cell
    cells.add(
      Column(
        key: Key('questionInfo$index'),
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            (question.questionText ?? 'Untitled Question').truncate(30),
            key: Key('name$index'),
            style: const TextStyle(fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '${question.options?.length ?? 0} options · ${question.questionType ?? 'text'}',
            key: Key('id$index'),
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  } else {
    // Sequence
    cells.add(
      Text(
        '${question.questionSequence ?? index + 1}',
        key: Key('id$index'),
      ),
    );

    // Question text
    cells.add(
      Text(
        question.questionText ?? 'Untitled Question',
        key: Key('name$index'),
        style: const TextStyle(fontWeight: FontWeight.w500),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );

    // Type
    cells.add(
      Text(
        question.questionType ?? 'text',
        key: Key('type$index'),
      ),
    );

    // Options count
    cells.add(
      Text(
        '${question.options?.length ?? 0}',
        key: Key('options$index'),
      ),
    );
  }

  // Delete action
  cells.add(
    IconButton(
      key: Key('delete$index'),
      icon: const Icon(Icons.delete_forever, color: Colors.red),
      tooltip: 'Delete question',
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      onPressed: question.assessmentQuestionId == null ? null : confirmDelete,
    ),
  );

  return cells;
}
