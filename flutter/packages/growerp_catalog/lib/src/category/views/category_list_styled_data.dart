/*
 * This software is in the public domain under CC0 1.0 Universal plus a
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

import '../blocs/category_bloc.dart';

/// Returns column definitions for category list based on device type
List<StyledColumn> getCategoryListColumns(BuildContext context) {
  bool isPhone = isAPhone(context);

  if (isPhone) {
    return [
      const StyledColumn(header: '', flex: 1), // Image
      const StyledColumn(header: 'Info', flex: 4),
      const StyledColumn(header: '', flex: 1), // Actions
    ];
  }

  return [
    const StyledColumn(header: 'ID', flex: 1),
    const StyledColumn(header: 'Name', flex: 4),
    const StyledColumn(header: '# Products', flex: 1),
    const StyledColumn(header: '', flex: 1), // Actions
  ];
}

/// Returns row data for category list
List<Widget> getCategoryListRow({
  required BuildContext context,
  required Category category,
  required int index,
  required Bloc bloc,
}) {
  bool isPhone = isAPhone(context);
  List<Widget> cells = [];

  if (isPhone) {
    // Image/Avatar
    cells.add(
      CircleAvatar(
        key: const Key('categoryItem'),
        child: category.image != null
            ? Image.memory(category.image!, height: 100)
            : Text(
                category.categoryName.isNotEmpty
                    ? category.categoryName[0].toUpperCase()
                    : '?',
                style: const TextStyle(fontSize: 20),
              ),
      ),
    );

    // Combined info cell
    cells.add(
      Column(
        key: Key('item$index'),
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(category.pseudoId, key: Key('id$index')),
          Text(
            category.categoryName.truncate(25),
            key: Key('name$index'),
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            '${category.nbrOfProducts} products',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            key: Key('products$index'),
          ),
        ],
      ),
    );
  } else {
    // ID
    cells.add(Text(category.pseudoId, key: Key('id$index')));

    // Name
    cells.add(Text(category.categoryName, key: Key('name$index')));

    // Product count
    cells.add(
      Text(
        '${category.nbrOfProducts}',
        key: Key('products$index'),
        textAlign: TextAlign.center,
      ),
    );
  }

  // Delete action
  cells.add(
    IconButton(
      key: Key('delete$index'),
      icon: const Icon(Icons.delete_forever),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      onPressed: () {
        bloc.add(CategoryDelete(category.copyWith(image: null)));
      },
    ),
  );

  return cells;
}
