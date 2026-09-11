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
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

import '../../../growerp_hr.dart';

List<StyledColumn> getDepartmentListColumns(BuildContext context) {
  final localizations = HrLocalizations.of(context)!;
  if (isAPhone(context)) {
    return [
      StyledColumn(header: localizations.name, flex: 5),
      const StyledColumn(header: '', flex: 1),
    ];
  }
  return [
    StyledColumn(header: localizations.name, flex: 4),
    StyledColumn(header: localizations.manager, flex: 4),
    const StyledColumn(header: '', flex: 1),
  ];
}

List<Widget> getDepartmentListRow({
  required BuildContext context,
  required Department department,
  required int index,
  required DepartmentBloc bloc,
}) {
  final localizations = HrLocalizations.of(context)!;
  final cells = <Widget>[];
  if (isAPhone(context)) {
    cells.add(
      Column(
        key: Key('item$index'),
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            department.name,
            key: Key('name$index'),
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            department.managerName ?? '',
            key: Key('manager$index'),
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  } else {
    cells.add(
      SizedBox(
        key: Key('item$index'),
        child: Text(department.name, key: Key('name$index')),
      ),
    );
    cells.add(Text(department.managerName ?? '', key: Key('manager$index')));
  }
  cells.add(
    IconButton(
      key: Key('delete$index'),
      icon: const Icon(Icons.delete_forever),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      onPressed: () async {
        final result = await confirmDialog(
          context,
          localizations.deleteConfirm(department.name),
          localizations.cannotBeUndone,
        );
        if (result == true) bloc.add(DepartmentDelete(department));
      },
    ),
  );
  return cells;
}
