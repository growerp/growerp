/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
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
    // wrap so the row's 'item$index' tap-key exists on desktop too (tests tap it
    // to open the row)
    cells.add(SizedBox(
      key: Key('item$index'),
      child: Text(linerType.linerName ?? '', key: Key('linerName$index')),
    ));
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
