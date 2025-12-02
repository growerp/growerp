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

import '../bloc/persona_bloc.dart';
import '../bloc/persona_event.dart';

TableData getPersonaListTableData(Bloc bloc, String classificationId,
    BuildContext context, Persona item, int index,
    {dynamic extra}) {
  bool isPhone = isAPhone(context);
  final PersonaBloc? personaBloc = bloc is PersonaBloc ? bloc : null;

  Future<void> confirmDelete() async {
    if (personaBloc == null || item.personaId == null) return;
    final shouldDelete = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: const Text('Delete Persona'),
        content: Text(
          'Are you sure you want to delete "${item.name}"?',
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
      personaBloc.add(PersonaDelete(item));
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
        tooltip: 'Delete persona',
        icon: const Icon(Icons.delete),
        color: Colors.red.shade600,
        onPressed: item.personaId == null
            ? null
            : () {
                confirmDelete();
              },
      ),
    );
  }

  List<TableRowContent> rowContent = [];
  if (isPhone) {
    rowContent.add(TableRowContent(
      name: 'ID',
      width: 15,
      value: CircleAvatar(
        child: Text(
          item.pseudoId == null ? '' : item.pseudoId!.lastChar(3),
          key: const Key('personaItem'),
        ),
      ),
    ));
    rowContent.add(TableRowContent(
        name: const Text('ID\nName\nDemographics', textAlign: TextAlign.start),
        width: 65,
        value: Column(
          key: Key('item$index'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.pseudoId ?? '', key: Key('id$index')),
            Text(item.name.truncate(25), key: Key('name$index')),
            Text(
              item.demographics?.truncate(30) ?? '',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
              key: Key('demographics$index'),
            ),
          ],
        )));
  } else {
    rowContent.add(TableRowContent(
        name: const Text('ID', textAlign: TextAlign.start),
        width: 8,
        value: Text(
          item.pseudoId ?? '',
          key: Key('id$index'),
        )));
    rowContent.add(TableRowContent(
        name: const Text('Name', textAlign: TextAlign.start),
        width: 18,
        value: Text(
          item.name,
          key: const Key('personaItem'),
        )));
    rowContent.add(TableRowContent(
        name: const Text('Demographics', textAlign: TextAlign.start),
        width: 20,
        value: Text(
          item.demographics ?? 'N/A',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.left,
          key: Key('demographics$index'),
        )));
    rowContent.add(TableRowContent(
        name: const Text('Pain Points', textAlign: TextAlign.start),
        width: 20,
        value: Text(
          item.painPoints ?? 'N/A',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.left,
          key: Key('painPoints$index'),
        )));
    rowContent.add(TableRowContent(
        name: const Text('Goals', textAlign: TextAlign.start),
        width: 18,
        value: Text(
          item.goals ?? 'N/A',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.left,
          key: Key('goals$index'),
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
