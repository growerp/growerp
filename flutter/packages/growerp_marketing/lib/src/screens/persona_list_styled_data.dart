/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 */

import 'package:flutter/material.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

import '../bloc/persona_bloc.dart';
import '../bloc/persona_event.dart';

/// Returns column definitions for persona list based on device type
List<StyledColumn> getPersonaListColumns(BuildContext context) {
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
    StyledColumn(header: 'Name', flex: 2),
    StyledColumn(header: 'Demographics', flex: 2),
    StyledColumn(header: 'Pain Points', flex: 2),
    StyledColumn(header: 'Goals', flex: 2),
    StyledColumn(header: '', flex: 1), // Actions
  ];
}

/// Returns row data for persona list
List<Widget> getPersonaListRow({
  required BuildContext context,
  required Persona persona,
  required int index,
  required PersonaBloc bloc,
}) {
  bool isPhone = isAPhone(context);

  Future<void> confirmDelete() async {
    if (persona.personaId == null) return;
    final shouldDelete = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Persona'),
        content: Text(
          'Are you sure you want to delete "${persona.name}"?',
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
      bloc.add(PersonaDelete(persona));
    }
  }

  List<Widget> cells = [];

  if (isPhone) {
    // Avatar
    cells.add(
      CircleAvatar(
        key: const Key('personaItem'),
        child: Text(persona.pseudoId?.lastChar(3) ?? '?'),
      ),
    );

    // Combined info cell
    cells.add(
      Column(
        key: Key('personaInfo$index'),
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            persona.name.truncate(25),
            key: Key('name$index'),
            style: const TextStyle(fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (persona.pseudoId != null)
            Text(
              persona.pseudoId!,
              key: Key('id$index'),
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          if (persona.demographics != null)
            Text(
              persona.demographics!.truncate(30),
              key: Key('demographics$index'),
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  } else {
    // ID
    cells.add(Text(persona.pseudoId ?? '', key: Key('id$index')));

    // Name
    cells.add(
      Text(
        persona.name,
        key: Key('name$index'),
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
    );

    // Demographics
    cells.add(
      Text(
        persona.demographics ?? 'N/A',
        key: Key('demographics$index'),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );

    // Pain Points
    cells.add(
      Text(
        persona.painPoints ?? 'N/A',
        key: Key('painPoints$index'),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );

    // Goals
    cells.add(
      Text(
        persona.goals ?? 'N/A',
        key: Key('goals$index'),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  // Delete action
  cells.add(
    IconButton(
      key: Key('delete$index'),
      icon: const Icon(Icons.delete, color: Colors.red),
      tooltip: 'Delete persona',
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      onPressed: persona.personaId == null ? null : confirmDelete,
    ),
  );

  return cells;
}
