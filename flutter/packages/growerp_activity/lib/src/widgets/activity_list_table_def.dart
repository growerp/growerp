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
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

import '../blocs/activity_bloc.dart';

TableData getTableData(Bloc bloc, String classificationId, BuildContext context,
    Activity item, int index,
    {dynamic extra}) {
  List<TableRowContent> rowContent = [];
  bool isPhone = isAPhone(context);
  rowContent.add(TableRowContent(
      // testing purposes
      name: '',
      width: 0,
      value: const Text('', key: Key('activityItem'))));

  rowContent.add(TableRowContent(
      name: 'Id',
      width: isPhone ? 15 : 8,
      value: Text(item.pseudoId, key: Key('id$index'))));

  rowContent.add(TableRowContent(
      name: 'Name',
      width: isPhone ? 35 : 20,
      value: Text(item.activityName, key: Key('name$index'))));

  rowContent.add(TableRowContent(
      name: const Text('Assignee', textAlign: TextAlign.left),
      width: 30,
      value: Text("${item.originator?.firstName} ${item.originator?.lastName}",
          key: Key('orgName$index'))));

  rowContent.add(TableRowContent(
      name: '',
      width: 10,
      value: IconButton(
        key: Key('delete$index'),
        padding: EdgeInsets.zero,
        icon: const Icon(Icons.delete_forever),
        onPressed: () {
          bloc.add(
              ActivityUpdate(item.copyWith(statusId: ActivityStatus.closed)));
        },
      )));

  return TableData(rowHeight: isPhone ? 40 : 20, rowContent: rowContent);
}

// general settings
var padding = const SpanPadding(trailing: 5, leading: 5);
SpanDecoration? getBackGround(BuildContext context, int index) {
  return index == 0
      ? SpanDecoration(color: Theme.of(context).colorScheme.tertiaryContainer)
      : null;
}
