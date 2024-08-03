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

import '../blocs/category_bloc.dart';

TableData getCategoryTableData(Bloc bloc, String classificationId,
    BuildContext context, Category item, int index,
    {dynamic extra}) {
  List<TableRowContent> rowContent = [];
  bool isPhone = isAPhone(context);

  rowContent.add(TableRowContent(
      name: '',
      width: 10,
      value: CircleAvatar(
        key: const Key('categoryItem'),
        child: item.image != null
            ? Image.memory(
                item.image!,
                height: 100,
              )
            : Text(item.categoryName.isEmpty ? '?' : item.categoryName[0]),
      )));
  rowContent.add(TableRowContent(
      name: 'Id', width: 15, value: Text(item.pseudoId, key: Key("id$index"))));
  rowContent.add(TableRowContent(
      name: 'Name',
      width: 35,
      value: Text(item.categoryName, key: Key("name$index"))));
  rowContent.add(TableRowContent(
      name: '#Prd',
      width: 15,
      value: Text("${item.nbrOfProducts}",
          key: Key("products$index"), textAlign: TextAlign.center)));

  rowContent.add(TableRowContent(
      name: '',
      width: 10,
      value: IconButton(
        key: Key('delete$index'),
        padding: EdgeInsets.zero,
        icon: const Icon(Icons.delete_forever),
        onPressed: () {
          bloc.add(CategoryDelete(item.copyWith(image: null)));
        },
      )));

  return TableData(rowHeight: isPhone ? 30 : 20, rowContent: rowContent);
}

// general settings
var categoryPadding = const SpanPadding(trailing: 5, leading: 5);
SpanDecoration? getCategoryBackGround(BuildContext context, int index) {
  return index == 0
      ? SpanDecoration(color: Theme.of(context).colorScheme.tertiaryContainer)
      : null;
}
