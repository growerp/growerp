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

import '../user.dart';

TableData getTableData(Bloc bloc, String classificationId, BuildContext context,
    User item, int index) {
  bool isPhone = isAPhone(context);
  List<TableRowContent> rowContent = [];
  rowContent.add(TableRowContent(
    name: ' ',
    width: isPhone ? 10 : 5,
    value: CircleAvatar(
      backgroundColor: Colors.green,
      child: item.image != null
          ? Image.memory(item.image!)
          : Text(item.firstName != null ? item.firstName![0] : '?'),
    ),
  ));
  rowContent.add(TableRowContent(
      name: Text(isPhone ? 'Name\nEmail' : 'Name', textAlign: TextAlign.start),
      width: isPhone ? 50 : 20,
      value: Text(
        "${item.firstName ?? ''} "
        "${item.lastName ?? ''} ${isPhone ? item.email ?? ' ' : ''}",
        key: Key('name$index'),
      )));
  if (!isPhone) {
    rowContent.add(TableRowContent(
        name: 'Email',
        width: 15,
        value: Text(
          item.email ?? ' ',
          textAlign: TextAlign.left,
          key: Key('email$index'),
        )));
  }
  if (!isPhone) {
    rowContent.add(TableRowContent(
        name: 'Login Name',
        width: 15,
        value: Text((!item.loginDisabled! ? item.loginName ?? ' ' : ' '),
            key: Key('username$index'))));
  }
  rowContent.add(TableRowContent(
      name: 'Company',
      width: 15,
      value: Text(item.company?.name ?? ' ',
          key: Key('companyName$index'), textAlign: TextAlign.center)));
  rowContent.add(TableRowContent(
      name: 'Admin?',
      width: 15,
      value: Text(item.userGroup == UserGroup.admin ? 'Y' : 'N',
          textAlign: TextAlign.center, key: Key('isAdmin$index'))));
  rowContent.add(TableRowContent(
      name: ' ',
      width: 15,
      value: IconButton(
        key: Key("delete$index"),
        icon: const Icon(Icons.delete_forever),
        onPressed: () {
          bloc.add(UserDelete(item.copyWith(image: null)));
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
