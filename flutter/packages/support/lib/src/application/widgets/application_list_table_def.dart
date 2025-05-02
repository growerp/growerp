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

import '../blocs/application_bloc.dart';

TableData getApplicationTableData(Bloc bloc, String classificationId,
    BuildContext context, Application item, int index,
    {dynamic extra}) {
  List<TableRowContent> rowContent = [];
  bool isPhone = isAPhone(context);
  rowContent.add(TableRowContent(
      name: 'Id',
      width: 13,
      value: Text(item.applicationId, key: Key("id$index"))));
  rowContent.add(TableRowContent(
      name: 'Version',
      width: 20,
      value: Text(item.version ?? '', key: Key("version$index"))));
  rowContent.add(TableRowContent(
      name: 'Backend URL',
      width: 40,
      value: Text(item.backendUrl ?? '', key: Key("backendUrl$index"))));

  rowContent.add(TableRowContent(
    // just for testing needs key
    name: 'ShortId',
    width: 0,
    value: const Text(
      '',
      key: Key('applicationItem'),
    ),
  ));
  rowContent.add(TableRowContent(
      name: '',
      width: 10,
      value: IconButton(
        key: Key('delete$index'),
        padding: EdgeInsets.zero,
        icon: const Icon(Icons.delete_forever),
        onPressed: () {
          bloc.add(ApplicationDelete(item));
        },
      )));

  return TableData(rowHeight: isPhone ? 38 : 20, rowContent: rowContent);
}

// general settings
var applicationPadding = const SpanPadding(trailing: 5, leading: 5);
SpanDecoration? getApplicationBackGround(BuildContext context, int index) {
  return index == 0
      ? SpanDecoration(color: Theme.of(context).colorScheme.tertiaryContainer)
      : null;
}
