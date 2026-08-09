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

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

import '../blocs/location_bloc.dart';
import 'package:growerp_inventory/l10n/generated/inventory_localizations.dart';

/// Returns column definitions for location list based on device type
List<StyledColumn> getLocationListColumns(BuildContext context) {
  final localizations = InventoryLocalizations.of(context)!;
  bool isPhone = isAPhone(context);

  if (isPhone) {
    return [
      const StyledColumn(header: '', flex: 1), // Avatar
      StyledColumn(header: localizations.tableHdrInfo, flex: 4),
      const StyledColumn(header: '', flex: 1), // Actions
    ];
  }

  return [
    StyledColumn(header: localizations.idLabel, flex: 1),
    StyledColumn(header: localizations.tableHdrName, flex: 3),
    StyledColumn(header: localizations.tableHdrQty, flex: 1),
    StyledColumn(header: localizations.tableHdrAssets, flex: 1),
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
    cells.add(
      SizedBox(
        key: Key('item$index'),
        child: Text(location.pseudoId ?? '', key: Key('id$index')),
      ),
    );

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
