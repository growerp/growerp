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

import '../blocs/subscription_bloc.dart';

TableData getSubscriptionTableData(Bloc bloc, String classificationId,
    BuildContext context, Subscription item, int index,
    {dynamic extra}) {
  List<TableRowContent> rowContent = [];
  bool isPhone = isAPhone(context);

  rowContent.add(TableRowContent(
      name: 'Id',
      width: isPhone ? 15 : 6,
      value: Text(item.pseudoId ?? '', key: Key('id$index'))));

  var subscriber =
      Text(item.subscriber?.name ?? "", key: Key('subscriber$index'));
  var email = Text(item.subscriber?.email ?? "", key: Key('email$index'));

  if (isPhone) {
    rowContent.add(TableRowContent(
        name: 'Subscriber\nEmail',
        width: isPhone ? 45 : 20,
        value: Column(
          children: [subscriber, email],
        )));
  } else {
    rowContent.add(TableRowContent(
        name: 'Subscriber', width: isPhone ? 35 : 20, value: subscriber));
    rowContent.add(
        TableRowContent(name: 'Email', width: isPhone ? 35 : 20, value: email));
  }

  var fromDate = Text(item.fromDate != null ? item.fromDate.dateOnly() : '',
      key: Key('fromDate$index'), textAlign: TextAlign.left);
  var thruDate = Text(item.thruDate != null ? item.thruDate.dateOnly() : '',
      key: Key('thruDate$index'), textAlign: TextAlign.left);
  if (isPhone) {
    rowContent.add(TableRowContent(
        name: 'From Date\nThrue Date',
        width: 20,
        value: Column(children: [fromDate, thruDate])));
  } else {
    rowContent
        .add(TableRowContent(name: 'From Date', width: 8, value: fromDate));

    rowContent
        .add(TableRowContent(name: 'Thru Date', width: 8, value: thruDate));
  }
  if (!isPhone) {
    rowContent.add(TableRowContent(
        name: 'Purch.from Date',
        width: 8,
        value: Text(
            item.purchaseFromDate != null
                ? item.purchaseFromDate.dateOnly()
                : '',
            textAlign: TextAlign.left)));
  }
  if (!isPhone) {
    rowContent.add(TableRowContent(
        name: 'Purch.Thru Date',
        width: 8,
        value: Text(
            item.purchaseThruDate != null
                ? item.purchaseThruDate.dateOnly()
                : '',
            textAlign: TextAlign.left)));
  }
  rowContent.add(TableRowContent(
      name: '',
      width: 10,
      value: IconButton(
        key: Key('delete$index'),
        padding: EdgeInsets.zero,
        icon: const Icon(Icons.delete_forever),
        onPressed: () {
          context.read<SubscriptionBloc>().add(SubscriptionDelete(item));
        },
      )));

  return TableData(rowHeight: isPhone ? 45 : 20, rowContent: rowContent);
}
