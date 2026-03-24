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

import '../blocs/work_order_bloc.dart';

List<StyledColumn> getWorkOrderListColumns(BuildContext context) {
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
    const StyledColumn(header: 'Product', flex: 3),
    const StyledColumn(header: 'Qty', flex: 1),
    const StyledColumn(header: 'Status', flex: 2),
    const StyledColumn(header: 'Start Date', flex: 2),
    const StyledColumn(header: '', flex: 1),
  ];
}

List<Widget> getWorkOrderListRow({
  required BuildContext context,
  required WorkOrder workOrder,
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
          workOrder.pseudoId.lastChar(3),
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
          Text(workOrder.pseudoId, key: Key('pseudoId$index')),
          Text(
            workOrder.productName ?? '',
            key: Key('productName$index'),
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            'Qty: ${workOrder.estimatedQuantity ?? ''} | ${workOrder.statusId ?? ''}',
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
    cells.add(Text(workOrder.pseudoId, key: Key('item$index')));
    cells.add(Text(workOrder.productName ?? '', key: Key('productName$index')));
    cells.add(
      Text(
        workOrder.estimatedQuantity?.toString() ?? '',
        key: Key('quantity$index'),
        textAlign: TextAlign.right,
      ),
    );
    cells.add(Text(workOrder.statusId ?? '', key: Key('statusId$index')));
    cells.add(
      Text(
        workOrder.estimatedStartDate ?? '',
        key: Key('startDate$index'),
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
          "cancel work order ${workOrder.pseudoId}?",
          "cannot be undone!",
        );
        if (result == true) {
          bloc.add(WorkOrderDelete(workOrder));
        }
      },
    ),
  );

  return cells;
}
