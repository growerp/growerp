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
import 'package:growerp_inventory/growerp_inventory.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

// field headers
List<dynamic> getItemFieldNames(
    {int? itemIndex,
    String? classificationId,
    Asset? item,
    BuildContext? context}) {
  return [
    if (isPhone(context)) Text('ShortId'),
    if (!isPhone(context)) Text('AssetId'),
    Text('Name'),
    Text(
      'Qty.',
      textAlign: TextAlign.right,
    ),
    if (!isPhone(context)) Text('Cost'),
    if (!isPhone(context)) Text('Loc Id'),
    Text('Act'),
    Text(''), // space for buttons
  ];
}

// field lengths perc of screenwidth can be larger than 100 %: horizontal
List<double> getItemFieldWidth(
    {int? itemIndex, Asset? item, BuildContext? context}) {
  return isPhone(context) ? [15, 40, 10, 10, 15] : [10, 25, 10, 10, 8, 8, 10];
}

// row height
double getRowHeight({BuildContext? context}) {
  return isPhone(context) ? 40 : 20;
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
List<dynamic> getItemFieldContent(Asset item,
    {int? itemIndex, BuildContext? context}) {
  String currencyId = context!
      .read<AuthBloc>()
      .state
      .authenticate!
      .company!
      .currency!
      .currencyId!;

  return [
    if (isPhone(context))
      CircleAvatar(
        minRadius: 20,
        backgroundColor: Theme.of(context).colorScheme.secondary,
        child: Text(
          item.pseudoId.lastChar(3),
          style: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
        ),
      ),
    if (!isPhone(context)) Text(item.pseudoId, key: Key('id$itemIndex')),
    Text(item.assetName ?? '', key: Key('name$itemIndex')),
    Text(
      item.quantityOnHand.toString(),
      key: Key('qoh$itemIndex'),
      textAlign: TextAlign.right,
    ),
    if (!isPhone(context))
      Text(item.acquireCost.currency(currencyId: currencyId)),
    if (!isPhone(context)) Text(item.location?.locationId ?? ''),
    Text(item.statusId == 'Deactivated' ? 'N' : 'Y',
        key: Key('status$itemIndex'), textAlign: TextAlign.center)
  ];
}

// buttons
List<Widget> getRowActionButtons({
  Bloc<dynamic, dynamic>? bloc,
  BuildContext? context,
  Asset? item,
  int? itemIndex,
}) {
  return [
    item?.statusId == 'Available' || item?.statusId == 'In Use'
        ? IconButton(
            key: Key('delete$itemIndex'),
            icon: const Icon(Icons.delete_forever),
            onPressed: () {
              bloc!.add(AssetUpdate(item!.copyWith(statusId: 'Deactivated')));
            })
        : IconButton(
            key: Key('delete$itemIndex'),
            icon: const Icon(Icons.event_available),
            onPressed: () {
              bloc!.add(AssetUpdate(item!.copyWith(statusId: 'Available')));
            }),
  ];
}