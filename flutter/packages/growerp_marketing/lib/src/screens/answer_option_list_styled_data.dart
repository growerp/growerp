/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 */

import 'package:flutter/material.dart';
import 'package:growerp_core/growerp_core.dart';

/// Returns column definitions for answer option list based on device type
List<StyledColumn> getAnswerOptionListColumns(BuildContext context) {
  bool isPhone = isAPhone(context);

  if (isPhone) {
    return const [
      StyledColumn(header: '#', flex: 1),
      StyledColumn(header: 'Option', flex: 3),
      StyledColumn(header: 'Score', flex: 1),
      StyledColumn(header: '', flex: 1), // Actions
    ];
  }

  return const [
    StyledColumn(header: '#', flex: 1),
    StyledColumn(header: 'Option Text', flex: 4),
    StyledColumn(header: 'Score', flex: 1),
    StyledColumn(header: '', flex: 1), // Actions
  ];
}

/// Returns row data for answer option list
List<Widget> getAnswerOptionListRow({
  required BuildContext context,
  required int index,
  required TextEditingController textController,
  required TextEditingController scoreController,
  required VoidCallback onDelete,
}) {
  List<Widget> cells = [];

  // Sequence number
  cells.add(
    CircleAvatar(
      radius: 14,
      key: Key('optionSeq$index'),
      child: Text('${index + 1}', style: const TextStyle(fontSize: 12)),
    ),
  );

  // Option text field
  cells.add(
    TextFormField(
      key: Key('optionText$index'),
      controller: textController,
      decoration: const InputDecoration(
        labelText: 'Option Text',
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Required';
        }
        return null;
      },
    ),
  );

  // Score field
  cells.add(
    TextFormField(
      key: Key('optionScore$index'),
      controller: scoreController,
      decoration: const InputDecoration(
        labelText: 'Score',
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Required';
        }
        if (double.tryParse(value) == null) {
          return 'Number';
        }
        return null;
      },
    ),
  );

  // Delete button
  cells.add(
    IconButton(
      key: Key('deleteOption$index'),
      icon: const Icon(Icons.delete_forever, color: Colors.red),
      tooltip: 'Remove option',
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      onPressed: onDelete,
    ),
  );

  return cells;
}
