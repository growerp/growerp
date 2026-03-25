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

import '../blocs/liner_type_bloc.dart';

List<StyledColumn> getLinerTypeListColumns(BuildContext context) {
  bool isPhone = isAPhone(context);
  if (isPhone) {
    return [
      const StyledColumn(header: '', flex: 1),
      const StyledColumn(header: 'Info', flex: 4),
      const StyledColumn(header: '', flex: 1),
    ];
  }
  return [
    const StyledColumn(header: 'Name', flex: 3),
    const StyledColumn(header: 'Width Inc. (ft)', flex: 2),
    const StyledColumn(header: 'Roll Width (ft)', flex: 2),
    const StyledColumn(header: 'Weight (lb/sqft)', flex: 2),
    const StyledColumn(header: '', flex: 1),
  ];
}

List<Widget> getLinerTypeListRow({
  required BuildContext context,
  required LinerType linerType,
  required int index,
  required Bloc bloc,
}) {
  bool isPhone = isAPhone(context);
  List<Widget> cells = [];

  if (isPhone) {
    cells.add(
      CircleAvatar(
        minRadius: 20,
        backgroundColor: Theme.of(context).colorScheme.secondary,
        child: Text(
          (linerType.linerName ?? '').isNotEmpty
              ? linerType.linerName!.substring(0, 1).toUpperCase()
              : 'L',
          style: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
        ),
      ),
    );
    cells.add(
      Column(
        key: Key('item$index'),
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            linerType.linerName ?? '',
            key: Key('linerName$index'),
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            'Inc: ${linerType.widthIncrement ?? ''} ft | '
            'Roll: ${linerType.rollStockWidth ?? ''} ft | '
            'Wt: ${linerType.linerWeight ?? ''} lb/sqft',
            key: Key('info$index'),
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  } else {
    cells.add(Text(linerType.linerName ?? '', key: Key('linerName$index')));
    cells.add(Text(linerType.widthIncrement?.toString() ?? '',
        key: Key('widthIncrement$index'), textAlign: TextAlign.right));
    cells.add(Text(linerType.rollStockWidth?.toString() ?? '',
        key: Key('rollStockWidth$index'), textAlign: TextAlign.right));
    cells.add(Text(linerType.linerWeight?.toString() ?? '',
        key: Key('linerWeight$index'), textAlign: TextAlign.right));
  }

  cells.add(
    IconButton(
      key: Key('delete$index'),
      icon: const Icon(Icons.delete_forever),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      onPressed: () async {
        bool? result = await confirmDialog(
          context,
          "delete liner type ${linerType.linerName}?",
          "cannot be undone!",
        );
        if (result == true) {
          bloc.add(LinerTypeDelete(linerType));
        }
      },
    ),
  );

  return cells;
}
