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

TableData getTableData(Bloc bloc, String classificationId, BuildContext context,
    Asset item, int index,
    {dynamic extra}) {
  String currencyId = context
      .read<AuthBloc>()
      .state
      .authenticate!
      .company!
      .currency!
      .currencyId!;

  List<TableRowContent> rowContent = [];
  if (isPhone(context)) {
    rowContent.add(TableRowContent(
        name: 'ShortId',
        width: isPhone(context) ? 15 : 10,
        value: CircleAvatar(
          minRadius: 20,
          backgroundColor: Theme.of(context).colorScheme.secondary,
          child: Text(
            item.pseudoId.lastChar(3),
            style: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
          ),
        )));
  }
  if (!isPhone(context)) {
    rowContent.add(TableRowContent(
        name: 'AssetId',
        width: 10,
        value: Text(item.pseudoId, key: Key('id$index'))));
  }
  rowContent.add(TableRowContent(
      name: 'Name',
      width: isPhone(context) ? 40 : 25,
      value: Text(item.assetName ?? '', key: Key('name$index'))));
  rowContent.add(TableRowContent(
    name: const Text(
      'Qty.',
      textAlign: TextAlign.right,
    ),
    width: isPhone(context) ? 10 : 10,
    value: Text(
      item.quantityOnHand.toString(),
      key: Key('qoh$index'),
      textAlign: TextAlign.right,
    ),
  ));
  if (!isPhone(context)) {
    rowContent.add(TableRowContent(
        name: const Text('Cost'),
        width: 10,
        value: Text(item.acquireCost.currency(currencyId: currencyId))));
  }
  if (!isPhone(context)) {
    rowContent.add(TableRowContent(
        name: const Text('Loc Id'),
        width: 10,
        value: Text(item.location?.locationId ?? '')));
  }
  rowContent.add(TableRowContent(
      name: const Text('Active', textAlign: TextAlign.center),
      width: 8,
      value: Text(item.statusId == 'Deactivated' ? 'N' : 'Y',
          key: Key('status$index'), textAlign: TextAlign.center)));
  rowContent.add(TableRowContent(
    width: isPhone(context) ? 15 : 10,
    name: ' ',
    value: item.statusId == 'Available' || item.statusId == 'In Use'
        ? IconButton(
            key: Key('delete$index'),
            icon: const Icon(Icons.delete_forever),
            padding: EdgeInsets.zero,
            onPressed: () {
              bloc.add(AssetUpdate(item.copyWith(statusId: 'Deactivated')));
            })
        : IconButton(
            key: Key('delete$index'),
            icon: const Icon(Icons.event_available),
            padding: EdgeInsets.zero,
            onPressed: () {
              bloc.add(AssetUpdate(item.copyWith(statusId: 'Available')));
            }),
  ));
  return TableData(
      rowHeight: isPhone(context) ? 40 : 20, rowContent: rowContent);
}

// general settings
var padding = const SpanPadding(trailing: 5, leading: 5);
SpanDecoration? getBackGround(BuildContext context, int index) {
  return index == 0
      ? SpanDecoration(color: Theme.of(context).colorScheme.tertiaryContainer)
      : null;
}
