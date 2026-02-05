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

import '../blocs/product_bloc.dart';

/// Returns column definitions for product list based on device type
List<StyledColumn> getProductListColumns(
  BuildContext context, {
  String? classificationId,
}) {
  bool isPhone = isAPhone(context);
  final isHotel = classificationId == 'AppHotel';

  if (isPhone) {
    return [
      const StyledColumn(header: '', flex: 1), // Image
      const StyledColumn(header: 'Info', flex: 4),
      const StyledColumn(header: 'Price', flex: 2),
      const StyledColumn(header: '', flex: 1), // Actions
    ];
  }

  return [
    const StyledColumn(header: 'ID', flex: 1),
    const StyledColumn(header: 'Name', flex: 3),
    const StyledColumn(header: 'Price', flex: 1),
    const StyledColumn(header: 'List Price', flex: 1),
    if (!isHotel) const StyledColumn(header: 'Category', flex: 2),
    StyledColumn(header: isHotel ? 'Units' : 'Assets', flex: 1),
    const StyledColumn(header: '', flex: 1), // Actions
  ];
}

/// Returns row data for product list
List<Widget> getProductListRow({
  required BuildContext context,
  required Product product,
  required int index,
  required Bloc bloc,
  String? classificationId,
}) {
  bool isPhone = isAPhone(context);
  final isHotel = classificationId == 'AppHotel';
  String currencyId = context
      .read<AuthBloc>()
      .state
      .authenticate!
      .company!
      .currency!
      .currencyId!;

  List<Widget> cells = [];

  if (isPhone) {
    // Image/Avatar
    cells.add(
      CircleAvatar(
        key: const Key('productItem'),
        child: product.image != null
            ? Image.memory(product.image!, height: 100)
            : Text(
                product.productName != null && product.productName!.isNotEmpty
                    ? product.productName![0]
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
          Text(product.pseudoId, key: Key('id$index')),
          Text(
            (product.productName ?? '').truncate(20),
            key: Key('name$index'),
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          if (!isHotel && product.categories.isNotEmpty)
            Text(
              product.categories.length > 1
                  ? '${product.categories.length} categories'
                  : product.categories[0].categoryName,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );

    // Price
    cells.add(
      Text(
        product.price.currency(
          currencyId: product.currency?.currencyId ?? currencyId,
        ),
        key: Key('price$index'),
        textAlign: TextAlign.right,
      ),
    );
  } else {
    // ID
    cells.add(Text(product.pseudoId, key: Key('id$index')));

    // Name
    cells.add(Text(product.productName ?? '', key: Key('name$index')));

    // Price
    cells.add(
      Text(
        product.price.currency(
          currencyId: product.currency?.currencyId ?? currencyId,
        ),
        key: Key('price$index'),
        textAlign: TextAlign.right,
      ),
    );

    // List Price
    cells.add(
      Text(
        product.listPrice.currency(
          currencyId: product.currency?.currencyId ?? currencyId,
        ),
        key: Key('listPrice$index'),
        textAlign: TextAlign.right,
      ),
    );

    // Category (not for hotel)
    if (!isHotel) {
      cells.add(
        Text(
          product.categories.isEmpty
              ? '0'
              : product.categories.length > 1
              ? '${product.categories.length}'
              : product.categories[0].categoryName,
          key: Key('categoryName$index'),
          textAlign: TextAlign.center,
        ),
      );
    }

    // Asset count
    cells.add(
      Text(
        product.assetCount?.toString() ?? '0',
        key: Key('assetCount$index'),
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
        bloc.add(ProductDelete(product.copyWith(image: null)));
      },
    ),
  );

  return cells;
}
