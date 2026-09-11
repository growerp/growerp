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

List<StyledColumn> getJobTitleListColumns(BuildContext context) {
  final localizations = HrLocalizations.of(context)!;
  if (isAPhone(context)) {
    return [
      StyledColumn(header: localizations.title, flex: 5),
      const StyledColumn(header: '', flex: 1),
    ];
  }
  return [
    StyledColumn(header: localizations.title, flex: 3),
    StyledColumn(header: localizations.description, flex: 5),
    const StyledColumn(header: '', flex: 1),
  ];
}

List<Widget> getJobTitleListRow({
  required BuildContext context,
  required JobTitle jobTitle,
  required int index,
  required JobTitleBloc bloc,
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
            jobTitle.title,
            key: Key('title$index'),
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            jobTitle.description ?? '',
            key: Key('description$index'),
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
        child: Text(jobTitle.title, key: Key('title$index')),
      ),
    );
    cells.add(Text(jobTitle.description ?? '', key: Key('description$index')));
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
          localizations.deleteConfirm(jobTitle.title),
          localizations.cannotBeUndone,
        );
        if (result == true) bloc.add(JobTitleDelete(jobTitle));
      },
    ),
  );
  return cells;
}
