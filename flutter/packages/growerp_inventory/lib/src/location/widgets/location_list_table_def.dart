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

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_inventory/growerp_inventory.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

TableData getTableData(
  Bloc bloc,
  String classificationId,
  BuildContext context,
  Location item,
  int index, {
  dynamic extra,
}) {
  List<TableRowContent> rowContent = [];
  Decimal qohTotal = Decimal.zero;
  for (Asset asset in item.assets) {
    qohTotal += asset.quantityOnHand ?? Decimal.zero;
  }
  if (isPhone(context)) {
    rowContent.add(
      TableRowContent(
        name: 'ShortId',
        width: 15,
        value: CircleAvatar(
          minRadius: 20,
          backgroundColor: Theme.of(context).colorScheme.secondary,
          child: Text(
            item.pseudoId == null ? '' : item.pseudoId!.lastChar(3),
            style: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
          ),
        ),
      ),
    );
  }
  rowContent.add(
    TableRowContent(
      name: 'Loc Id',
      width: isPhone(context) ? 15 : 10,
      value: Text(item.pseudoId ?? '', key: Key('id$index')),
    ),
  );
  rowContent.add(
    TableRowContent(
      name: 'Name',
      width: isPhone(context) ? 30 : 30,
      value: Text(item.locationName ?? '', key: Key('name$index')),
    ),
  );
  rowContent.add(
    TableRowContent(
      name: const Text('Qty.', textAlign: TextAlign.right),
      width: isPhone(context) ? 16 : 15,
      value: Text(
        qohTotal.toString(),
        key: Key('qoh$index'),
        textAlign: TextAlign.right,
      ),
    ),
  );
  if (!isPhone(context)) {
    rowContent.add(
      TableRowContent(
        name: const Text('#Assets'),
        width: 10,
        value: Text(
          item.assets.length.toString(),
          key: Key('assetsCount$index'),
        ),
      ),
    );
  }
  rowContent.add(
    TableRowContent(
      width: isPhone(context) ? 15 : 15,
      name: ' ',
      value: IconButton(
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        key: Key('delete$index'),
        icon: const Icon(Icons.delete_forever),
        tooltip: 'remove item',
        onPressed: () async {
          bool? result = await confirmDialog(
            context,
            "delete ${item.pseudoId ?? ''}?",
            "cannot be undone!",
          );
          if (result == true) {
            bloc.add(LocationDelete(item));
          }
        },
      ),
    ),
  );

  return TableData(
    rowHeight: isPhone(context) ? 36 : 20,
    rowContent: rowContent,
  );
}

// general settings
var padding = const SpanPadding(trailing: 5, leading: 5);
SpanDecoration? getBackGround(BuildContext context, int index) {
  return index == 0
      ? SpanDecoration(color: Theme.of(context).colorScheme.tertiaryContainer)
      : null;
}
