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
import 'package:url_launcher/url_launcher.dart';

import '../user.dart';

TableData getUserListTableData(Bloc bloc, String classificationId,
    BuildContext context, User item, int index,
    {dynamic extra}) {
  bool isPhone = isAPhone(context);
  List<TableRowContent> rowContent = [];
  if (isPhone) {
    rowContent.add(TableRowContent(
      name: 'ShortId',
      width: isPhone ? 10 : 5,
      value: CircleAvatar(
        child: item.image != null
            ? Image.memory(item.image!)
            : Text(
                item.pseudoId == null ? '' : item.pseudoId!.lastChar(3),
                key: const Key('userItem'),
              ),
      ),
    ));
    rowContent.add(TableRowContent(
        name: const Text('ID\nName\nEmail/Url', textAlign: TextAlign.start),
        width: 40,
        value: Column(
          key: Key('item$index'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.pseudoId ?? '', key: Key('id$index')),
            Text(
                ("${item.firstName ?? ''} ${item.lastName ?? ''}").truncate(18),
                key: Key('name$index')),
            if (item.email == null && item.url != null)
              GestureDetector(
                onTap: () async => await launchUrl(Uri.parse(item.url!)),
                child: const Text('-- tap for url --',
                    style: TextStyle(decoration: TextDecoration.underline)),
              ),
            if (item.email != null && item.url == null)
              GestureDetector(
                onTap: () async =>
                    await launchUrl(Uri.parse('mailto:${item.email}')),
                child: Text('-- tap to email --',
                    style:
                        const TextStyle(decoration: TextDecoration.underline),
                    key: Key('email$index')),
              ),
          ],
        )));
  } else {
    rowContent.add(TableRowContent(
        name: const Text('ID', textAlign: TextAlign.start),
        width: 8,
        value: Text(
          item.pseudoId ?? '',
          key: Key('id$index'),
        )));
    rowContent.add(TableRowContent(
        name: const Text('Name', textAlign: TextAlign.start),
        width: 15,
        value: Text(
          "${item.firstName ?? ''} ${item.lastName ?? ''} ",
          key: Key('name$index'),
        )));
    rowContent.add(TableRowContent(
        name: 'Email',
        width: 18,
        value: item.email != null
            ? GestureDetector(
                onTap: () async =>
                    await launchUrl(Uri.parse('mailto:${item.email}')),
                child: Text(item.email!,
                    style:
                        const TextStyle(decoration: TextDecoration.underline),
                    textAlign: TextAlign.left,
                    key: Key('email$index')))
            : Text(
                item.email ?? ' ',
                textAlign: TextAlign.left,
                key: Key('email$index'),
              )));
    rowContent.add(TableRowContent(
        name: 'Url',
        width: 18,
        value: item.url != null
            ? GestureDetector(
                onTap: () async => await launchUrl(Uri.parse(item.url!)),
                child: Text(item.url!,
                    style:
                        const TextStyle(decoration: TextDecoration.underline),
                    textAlign: TextAlign.left,
                    key: Key('url$index')))
            : Text(
                '',
                key: Key('url$index'),
              )));
  }
  // specific roles
  if (extra as Role != Role.unknown) {
    // only specific roles: show company
    rowContent.add(TableRowContent(
        name: 'Company',
        width: isPhone ? 30 : 20,
        value: Text(item.company?.name ?? ' ',
            key: Key('companyName$index'), textAlign: TextAlign.left)));
  } else {
    // all items so show role
    rowContent.add(TableRowContent(
        name: 'Role',
        width: 30,
        value: Text(item.role != null ? item.role!.name : Role.unknown.name,
            key: Key('role$index'), textAlign: TextAlign.left)));
  }
  // all devices
  rowContent.add(TableRowContent(
      name: ' ',
      width: 10,
      value: IconButton(
        key: Key("delete$index"),
        icon: const Icon(Icons.delete_forever),
        onPressed: () {
          bloc.add(UserDelete(item.copyWith(image: null)));
        },
      )));

  return TableData(rowHeight: isPhone ? 65 : 20, rowContent: rowContent);
}
