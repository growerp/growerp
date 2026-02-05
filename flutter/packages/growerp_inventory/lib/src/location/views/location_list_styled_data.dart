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

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

import '../blocs/location_bloc.dart';

/// Returns column definitions for location list based on device type
List<StyledColumn> getLocationListColumns(BuildContext context) {
  bool isPhone = isAPhone(context);

  if (isPhone) {
    return [
      const StyledColumn(header: '', flex: 1), // Avatar
      const StyledColumn(header: 'Info', flex: 4),
      const StyledColumn(header: '', flex: 1), // Actions
    ];
  }

  return [
    const StyledColumn(header: 'ID', flex: 1),
    const StyledColumn(header: 'Name', flex: 3),
    const StyledColumn(header: 'Qty', flex: 1),
    const StyledColumn(header: '# Assets', flex: 1),
    const StyledColumn(header: '', flex: 1), // Actions
  ];
}

/// Returns row data for location list
List<Widget> getLocationListRow({
  required BuildContext context,
  required Location location,
  required int index,
  required Bloc bloc,
}) {
  bool isPhone = isAPhone(context);
  List<Widget> cells = [];

  // Calculate total quantity on hand
  Decimal qohTotal = Decimal.zero;
  for (Asset asset in location.assets) {
    qohTotal += asset.quantityOnHand ?? Decimal.zero;
  }

  if (isPhone) {
    // Avatar
    cells.add(
      CircleAvatar(
        minRadius: 20,
        backgroundColor: Theme.of(context).colorScheme.secondary,
        child: Text(
          location.pseudoId == null ? '' : location.pseudoId!.lastChar(3),
          style: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
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
          Text(location.pseudoId ?? '', key: Key('id$index')),
          Text(
            (location.locationName ?? '').truncate(20),
            key: Key('name$index'),
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Row(
            children: [
              Text(
                'Qty: ${qohTotal.toString()}',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                key: Key('qoh$index'),
              ),
              const SizedBox(width: 8),
              Text(
                '${location.assets.length} assets',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  } else {
    // ID
    cells.add(Text(location.pseudoId ?? '', key: Key('id$index')));

    // Name
    cells.add(Text(location.locationName ?? '', key: Key('name$index')));

    // Quantity
    cells.add(
      Text(
        qohTotal.toString(),
        key: Key('qoh$index'),
        textAlign: TextAlign.right,
      ),
    );

    // Asset count
    cells.add(
      Text(
        location.assets.length.toString(),
        key: Key('assetsCount$index'),
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
      onPressed: () async {
        bool? result = await confirmDialog(
          context,
          "delete ${location.pseudoId ?? ''}?",
          "cannot be undone!",
        );
        if (result == true) {
          bloc.add(LocationDelete(location));
        }
      },
    ),
  );

  return cells;
}
