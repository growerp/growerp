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
