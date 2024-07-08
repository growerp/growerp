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

// field headers
List<dynamic> getItemFieldNames(
    {int? itemIndex,
    String? classificationId,
    Location? item,
    BuildContext? context}) {
  return [
    if (isPhone(context)) Text('ShortId'),
    Text('Loc Id'),
    Text('Name'),
    Text(
      'Qty.',
      textAlign: TextAlign.right,
    ),
    if (!isPhone(context)) Text('#Assets'),
    Text(''), // space for buttons
  ];
}

// field lengths perc of screenwidth can be larger than 100 %: horizontal
List<double> getItemFieldWidth(
    {int? itemIndex, Location? item, BuildContext? context}) {
  return isPhone(context) ? [15, 15, 30, 10, 25] : [10, 30, 15, 15, 15];
}

// row height
double getRowHeight({BuildContext? context}) {
  return isPhone(context) ? 30 : 20;
}

// general settings
var padding = SpanPadding(trailing: 5, leading: 5);
SpanDecoration? getBackGround(BuildContext context, int index) {
  return index == 0
      ? SpanDecoration(color: Theme.of(context).colorScheme.tertiaryContainer)
      : null;
}

// fields content, using strings index not required
// widgets also allowed, then index is used for the key on the widgets
List<dynamic> getItemFieldContent(Location item,
    {int? itemIndex, BuildContext? context}) {
  Decimal qohTotal = Decimal.zero;
  for (Asset asset in item.assets) {
    qohTotal += asset.quantityOnHand ?? Decimal.zero;
  }
  return [
    if (isPhone(context))
      CircleAvatar(
        minRadius: 20,
        backgroundColor: Theme.of(context!).colorScheme.secondary,
        child: Text(
          item.pseudoId == null ? '' : item.pseudoId!.lastChar(3),
          style: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
        ),
      ),
    Text(item.pseudoId ?? '', key: Key('id$itemIndex')),
    Text(item.locationName ?? '', key: Key('name$itemIndex')),
    Text(
      qohTotal.toString(),
      key: Key('qoh$itemIndex'),
      textAlign: TextAlign.right,
    ),
    if (!isPhone(context))
      Text(item.assets.length.toString(), key: Key('assetsCount$itemIndex')),
  ];
}

// buttons
List<Widget> getRowActionButtons({
  Bloc<dynamic, dynamic>? bloc,
  BuildContext? context,
  Location? item,
  int? itemIndex,
}) {
  return [
    IconButton(
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.all(0),
        key: Key('delete$itemIndex'),
        icon: const Icon(Icons.delete_forever),
        tooltip: 'remove item',
        onPressed: () async {
          bool? result = await confirmDialog(
              context!, "delete ${item?.pseudoId ?? ''}?", "cannot be undone!");
          if (result == true) {
            bloc!.add(LocationDelete(item!));
          }
        }),
  ];
}
