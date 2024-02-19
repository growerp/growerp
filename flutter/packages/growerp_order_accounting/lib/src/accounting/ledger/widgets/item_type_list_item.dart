// ignore_for_file: unnecessary_string_interpolations

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
import 'package:growerp_models/growerp_models.dart';
import 'package:responsive_framework/responsive_framework.dart';

class ItemTypeListItem extends StatelessWidget {
  const ItemTypeListItem(
      {super.key, required this.itemType, required this.index});

  final ItemType itemType;
  final int index;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.green,
        child: Text(itemType.itemTypeName.substring(3, 5)),
      ),
      title: Row(
        children: <Widget>[
          Expanded(
              child: Text("${itemType.itemTypeName}", key: Key('name$index'))),
          if (ResponsiveBreakpoints.of(context).largerThan(MOBILE))
            Expanded(
                child: Text("${itemType.accountCode}",
                    key: Key('accountCode$index'),
                    textAlign: TextAlign.center)),
          Expanded(
              child: Text("${itemType.accountName}",
                  key: Key('accountName$index'))),
          Expanded(
              child: Text(itemType.direction!,
                  key: Key('direction$index'), textAlign: TextAlign.center)),
        ],
      ),
    );
  }
}
