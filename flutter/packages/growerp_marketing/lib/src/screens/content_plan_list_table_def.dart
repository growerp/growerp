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
import 'package:intl/intl.dart';

import '../bloc/content_plan_bloc.dart';
import '../bloc/content_plan_event.dart';

TableData getContentPlanListTableData(Bloc bloc, String classificationId,
    BuildContext context, ContentPlan item, int index,
    {dynamic extra}) {
  bool isPhone = isAPhone(context);
  final ContentPlanBloc? contentPlanBloc =
      bloc is ContentPlanBloc ? bloc : null;

  String formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('MMM d, yyyy').format(date);
  }

  Future<void> confirmDelete() async {
    if (contentPlanBloc == null || item.planId == null) return;
    final shouldDelete = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: const Text('Delete Content Plan'),
        content: Text(
          'Are you sure you want to delete plan "${item.theme ?? item.pseudoId}"?',
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
      contentPlanBloc.add(ContentPlanDelete(item));
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
        tooltip: 'Delete content plan',
        icon: const Icon(Icons.delete),
        color: Colors.red.shade600,
        onPressed: item.planId == null
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
          key: const Key('contentPlanItem'),
        ),
      ),
    ));
    rowContent.add(TableRowContent(
        name: const Text('ID\nTheme\nWeek Start', textAlign: TextAlign.start),
        width: 65,
        value: Column(
          key: Key('item$index'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.pseudoId ?? '', key: Key('id$index')),
            Text((item.theme ?? 'No theme').truncate(25),
                key: Key('theme$index')),
            Text(
              formatDate(item.weekStartDate),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
              key: Key('weekStartDate$index'),
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
        name: const Text('Theme', textAlign: TextAlign.start),
        width: 30,
        value: Text(
          item.theme ?? 'No theme',
          key: const Key('contentPlanItem'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        )));
    rowContent.add(TableRowContent(
        name: const Text('Week Start', textAlign: TextAlign.start),
        width: 15,
        value: Text(
          formatDate(item.weekStartDate),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.left,
          key: Key('weekStartDate$index'),
        )));
    rowContent.add(TableRowContent(
        name: const Text('Persona ID', textAlign: TextAlign.start),
        width: 15,
        value: Text(
          item.personaId ?? 'N/A',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.left,
          key: Key('personaId$index'),
        )));
    rowContent.add(TableRowContent(
        name: const Text('Modified', textAlign: TextAlign.start),
        width: 15,
        value: Text(
          formatDate(item.lastModifiedDate),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.left,
          key: Key('lastModifiedDate$index'),
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
