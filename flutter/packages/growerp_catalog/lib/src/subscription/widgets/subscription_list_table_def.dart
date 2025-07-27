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

TableData getSubscriptionTableData(Bloc bloc, String classificationId,
    BuildContext context, Subscription item, int index,
    {dynamic extra}) {
  List<TableRowContent> rowContent = [];
  bool isPhone = isAPhone(context);

  rowContent.add(TableRowContent(
      name: 'Id',
      width: isPhone ? 15 : 8,
      value: Text(item.pseudoId ?? '', key: Key('id$index'))));

  rowContent.add(TableRowContent(
      name: 'Subscriber',
      width: isPhone ? 35 : 20,
      value: Text(item.subscriber!.name ?? "", key: Key('subscriber$index'))));

  rowContent.add(TableRowContent(
      name: 'Email',
      width: isPhone ? 35 : 20,
      value: Text(item.subscriber!.email ?? "", key: Key('email$index'))));

  rowContent.add(TableRowContent(
      name: 'From Date',
      width: 15,
      value: Text(item.fromDate != null ? item.fromDate.dateOnly() : '',
          key: Key('fromDate$index'), textAlign: TextAlign.right)));

  rowContent.add(TableRowContent(
      name: 'Thru Date',
      width: 15,
      value: Text(item.thruDate != null ? item.thruDate.dateOnly() : '',
          key: Key('thruDate$index'), textAlign: TextAlign.right)));

  rowContent.add(TableRowContent(
      name: '',
      width: 10,
      value: IconButton(
        key: Key('delete$index'),
        padding: EdgeInsets.zero,
        icon: const Icon(Icons.delete_forever),
        onPressed: () {
          // bloc.add(SubscriptionDelete(item));
        },
      )));

  return TableData(rowHeight: isPhone ? 40 : 20, rowContent: rowContent);
}
