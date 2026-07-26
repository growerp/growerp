/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
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
      Column(
        key: Key('item$index'),
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(bom.productPseudoId, key: Key('productPseudoId$index')),
        ],
      ),
    );
    cells.add(
      Text(bom.productName ?? '', key: Key('productName$index')),
    );
    cells.add(const Icon(Icons.chevron_right));
  }

  return cells;
}

