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

import '../blocs/routing_bloc.dart';

List<StyledColumn> getRoutingListColumns(BuildContext context) {
  bool isPhone = isAPhone(context);
  if (isPhone) {
    return [
      const StyledColumn(header: '', flex: 1),
      const StyledColumn(header: 'Info', flex: 4),
      const StyledColumn(header: '', flex: 1),
    ];
  }
  return [
    const StyledColumn(header: 'ID', flex: 1),
    const StyledColumn(header: 'Routing Name', flex: 4),
    const StyledColumn(header: 'Tasks', flex: 1),
    const StyledColumn(header: '', flex: 1),
  ];
}

List<Widget> getRoutingListRow({
  required BuildContext context,
  required Routing routing,
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
          (routing.routingId).lastChar(3),
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
            routing.routingName ?? '',
            key: Key('routingName$index'),
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            '${routing.routingTasks.length} task(s)',
            key: Key('taskCount$index'),
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  } else {
    cells.add(Text(routing.routingId.lastChar(6), key: Key('item$index')));
    cells.add(Text(routing.routingName ?? '', key: Key('routingName$index')));
    cells.add(
      Text(
        routing.routingTasks.length.toString(),
        key: Key('taskCount$index'),
        textAlign: TextAlign.center,
      ),
    );
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
          "delete routing ${routing.routingName}?",
          "cannot be undone!",
        );
        if (result == true) {
          bloc.add(RoutingDelete(routing));
        }
      },
    ),
  );

  return cells;
}
