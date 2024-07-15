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

TableData getTableData(Bloc bloc, String classificationId, BuildContext context,
    List<Location> locations) {
  List<TableRowContent> rowContent = [];
  for (final (index, location) in locations.indexed) {
    Decimal qohTotal = Decimal.zero;
    for (Asset asset in location.assets) {
      qohTotal += asset.quantityOnHand ?? Decimal.zero;
    }
    if (isPhone(context))
      rowContent.add(TableRowContent(
          fieldName: 'ShortId',
          fieldWidth: 15,
          fieldContent: CircleAvatar(
            minRadius: 20,
            backgroundColor: Theme.of(context).colorScheme.secondary,
            child: Text(
              location.pseudoId == null ? '' : location.pseudoId!.lastChar(3),
              style:
                  TextStyle(color: Theme.of(context).colorScheme.onSecondary),
            ),
          )));
    rowContent.add(TableRowContent(
        fieldName: 'Loc Id',
        fieldWidth: isPhone(context) ? 15 : 10,
        fieldContent: Text(location.pseudoId ?? '', key: Key('id$index'))));
    rowContent.add(TableRowContent(
        fieldName: 'Name',
        fieldWidth: isPhone(context) ? 30 : 30,
        fieldContent:
            Text(location.locationName ?? '', key: Key('name$index'))));
    rowContent.add(TableRowContent(
      fieldName: Text(
        'Qty.',
        textAlign: TextAlign.right,
      ),
      fieldWidth: isPhone(context) ? 10 : 15,
      fieldContent: Text(
        qohTotal.toString(),
        key: Key('qoh$index'),
        textAlign: TextAlign.right,
      ),
    ));
    if (!isPhone(context))
      rowContent.add(TableRowContent(
          fieldName: Text('#Assets'),
          fieldWidth: 10,
          fieldContent: Text(location.assets.length.toString(),
              key: Key('assetsCount$index'))));
    rowContent.add(TableRowContent(
        fieldWidth: isPhone(context) ? 25 : 15,
        fieldName: ' ',
        fieldContent: IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.all(0),
            key: Key('delete$index'),
            icon: const Icon(Icons.delete_forever),
            tooltip: 'remove item',
            onPressed: () async {
              bool? result = await confirmDialog(context,
                  "delete ${location.pseudoId ?? ''}?", "cannot be undone!");
              if (result == true) {
                bloc.add(LocationDelete(location));
              }
            })));
  }
  return TableData(
      rowHeight: isPhone(context) ? 30 : 20, rowContent: rowContent);
}

// general settings
var padding = SpanPadding(trailing: 5, leading: 5);
SpanDecoration? getBackGround(BuildContext context, int index) {
  return index == 0
      ? SpanDecoration(color: Theme.of(context).colorScheme.tertiaryContainer)
      : null;
}
