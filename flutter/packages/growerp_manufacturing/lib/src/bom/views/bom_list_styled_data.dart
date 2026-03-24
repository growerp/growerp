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
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

List<StyledColumn> getBomHeaderColumns(BuildContext context) {
  bool isPhone = isAPhone(context);
  if (isPhone) {
    return [
      const StyledColumn(header: '', flex: 1),
      const StyledColumn(header: 'Assembly Product', flex: 5),
    ];
  }
  return [
    const StyledColumn(header: 'Product ID', flex: 2),
    const StyledColumn(header: 'Product Name', flex: 5),
    const StyledColumn(header: '', flex: 1),
  ];
}

List<Widget> getBomHeaderRow({
  required BuildContext context,
  required Bom bom,
  required int index,
}) {
  bool isPhone = isAPhone(context);
  List<Widget> cells = [];

  if (isPhone) {
    cells.add(
      CircleAvatar(
        minRadius: 20,
        backgroundColor: Theme.of(context).colorScheme.secondary,
        child: Text(
          bom.productPseudoId.lastChar(3),
          style: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
        ),
      ),
    );
    cells.add(
      Column(
        key: Key('item$index'),
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(bom.productPseudoId, key: Key('productPseudoId$index')),
          Text(
            bom.productName ?? '',
            key: Key('productName$index'),
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  } else {
    cells.add(
      Text(bom.productPseudoId, key: Key('item$index')),
    );
    cells.add(
      Text(bom.productName ?? '', key: Key('productName$index')),
    );
    cells.add(const Icon(Icons.chevron_right));
  }

  return cells;
}

