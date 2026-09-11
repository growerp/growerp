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

List<StyledColumn> getEmployeeListColumns(BuildContext context) {
  final localizations = HrLocalizations.of(context)!;
  if (isAPhone(context)) {
    return [
      const StyledColumn(header: '', flex: 1),
      StyledColumn(header: localizations.name, flex: 5),
    ];
  }
  return [
    StyledColumn(header: localizations.name, flex: 3),
    StyledColumn(header: localizations.jobTitle, flex: 3),
    StyledColumn(header: localizations.department, flex: 3),
    StyledColumn(header: localizations.status, flex: 2),
  ];
}

List<Widget> getEmployeeListRow({
  required BuildContext context,
  required Employee employee,
  required int index,
}) {
  final cells = <Widget>[];
  if (isAPhone(context)) {
    cells.add(
      CircleAvatar(
        minRadius: 20,
        backgroundColor: Theme.of(context).colorScheme.secondary,
        child: Text(
          employee.firstName.isNotEmpty
              ? employee.firstName.substring(0, 1).toUpperCase()
              : 'E',
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
            employee.name,
            key: Key('name$index'),
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          // the same fields the desktop layout shows in their own column
          DefaultTextStyle(
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    employee.jobTitle ?? '',
                    key: Key('jobTitle$index'),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Text(' '),
                Flexible(
                  child: Text(
                    employee.department ?? '',
                    key: Key('department$index'),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Text(' '),
                Text(employee.status?.name ?? '', key: Key('status$index')),
              ],
            ),
          ),
        ],
      ),
    );
  } else {
    cells.add(
      SizedBox(
        key: Key('item$index'),
        child: Text(employee.name, key: Key('name$index')),
      ),
    );
    cells.add(Text(employee.jobTitle ?? '', key: Key('jobTitle$index')));
    cells.add(Text(employee.department ?? '', key: Key('department$index')));
    cells.add(Text(employee.status?.name ?? '', key: Key('status$index')));
  }
  return cells;
}
