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
            'Qty: ${workOrder.estimatedQuantity ?? ''} | ${workOrder.status?.name ?? ''}',
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
    cells.add(Text(workOrder.status?.name ?? '', key: Key('statusId$index')));
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
