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
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

import '../blocs/asset_bloc.dart';
import 'package:growerp_inventory/l10n/generated/inventory_localizations.dart';

/// Returns column definitions for asset list based on device type
List<StyledColumn> getAssetListColumns(
  BuildContext context, {
  String? applicationId,
}) {
  final localizations = InventoryLocalizations.of(context)!;
  bool isPhone = isAPhone(context);
  // Hotel and rental both show the rentable-asset layout (unit nr/name/type/
  // price) instead of the generic stock-inventory columns.
  final isRentalLayout =
      applicationId == 'AppHotel' || applicationId == 'AppRental';
  final noun = applicationId == 'AppRental'
      ? localizations.assetNounEquipment
      : localizations.assetNounRoom;

  if (isPhone) {
    return [
      const StyledColumn(header: '', flex: 1), // Avatar
      StyledColumn(header: localizations.tableHdrInfo, flex: 4),
      StyledColumn(header: localizations.status, flex: 1),
      const StyledColumn(header: '', flex: 1), // Actions
    ];
  }

  if (isRentalLayout) {
    return [
      StyledColumn(header: localizations.tableHdrNounNr(noun), flex: 1),
      StyledColumn(header: localizations.tableHdrNounName(noun), flex: 2),
      StyledColumn(header: localizations.tableHdrNounType(noun), flex: 2),
      StyledColumn(header: localizations.tableHdrListPrice, flex: 1),
      StyledColumn(header: localizations.tableHdrPrice, flex: 1),
      StyledColumn(header: localizations.tableHdrActive, flex: 1),
      const StyledColumn(header: '', flex: 1), // Actions
    ];
  }

  return [
    StyledColumn(header: localizations.idLabel, flex: 1),
    StyledColumn(header: localizations.product, flex: 3),
    StyledColumn(header: localizations.tableHdrQty, flex: 1),
    StyledColumn(header: localizations.tableHdrCost, flex: 1),
    StyledColumn(header: localizations.location, flex: 1),
    StyledColumn(header: localizations.tableHdrActive, flex: 1),
    const StyledColumn(header: '', flex: 1), // Actions
  ];
}

/// Returns row data for asset list
List<Widget> getAssetListRow({
  required BuildContext context,
  required Asset asset,
  required int index,
  required Bloc bloc,
  String? applicationId,
}) {
  bool isPhone = isAPhone(context);
  final isHotel = applicationId == 'AppHotel' || applicationId == 'AppRental';
  String currencyId = context
      .read<AuthBloc>()
      .state
      .authenticate!
      .company!
      .currency!
      .currencyId!;

  List<Widget> cells = [];

  if (isPhone) {
    // Avatar
    cells.add(
      CircleAvatar(
        minRadius: 20,
        backgroundColor: Theme.of(context).colorScheme.secondary,
        child: Text(
          asset.pseudoId.lastChar(3),
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
          Text(asset.pseudoId, key: Key('id$index')),
          Text(
            isHotel
                ? (asset.assetName ?? '').truncate(20)
                : (asset.product?.productName ?? '').truncate(20),
            key: Key('name$index'),
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          if (!isHotel)
            Text(
              'Qty: ${asset.quantityOnHand}',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              key: Key('qoh$index'),
            ),
        ],
      ),
    );

    // Status
    cells.add(
      StatusChip(
        label: asset.statusId == 'Deactivated' ? 'N' : 'Y',
        type: asset.statusId == 'Deactivated'
            ? StatusType.danger
            : StatusType.success,
        size: StatusChipSize.small,
        key: Key('status$index'),
      ),
    );
  } else {
    if (isHotel) {
      // Room Nr
      cells.add(
        SizedBox(
          key: Key('item$index'),
          child: Text(asset.pseudoId, key: Key('id$index')),
        ),
      );

      // Room Name
      cells.add(Text(asset.assetName ?? ''));

      // Room Type
      cells.add(Text(asset.product?.productName ?? '', key: Key('name$index')));

      // List Price
      cells.add(
        Text(
          asset.product?.listPrice.currency(currencyId: currencyId) ?? '',
          textAlign: TextAlign.right,
        ),
      );

      // Price
      cells.add(
        Text(
          asset.product?.price.currency(currencyId: currencyId) ?? '',
          textAlign: TextAlign.right,
        ),
      );
    } else {
      // ID
      cells.add(
        SizedBox(
          key: Key('item$index'),
          child: Text(asset.pseudoId, key: Key('id$index')),
        ),
      );

      // Product
      cells.add(Text(asset.product?.productName ?? '', key: Key('name$index')));

      // Quantity
      cells.add(
        Text(
          asset.quantityOnHand.toString(),
          key: Key('qoh$index'),
          textAlign: TextAlign.right,
        ),
      );

      // Cost
      cells.add(Text(asset.acquireCost.currency(currencyId: currencyId)));

      // Location
      cells.add(Text(asset.location?.locationId ?? ''));
    }

    // Active status
    cells.add(
      StatusChip(
        label: asset.statusId == 'Deactivated' ? 'No' : 'Yes',
        type: asset.statusId == 'Deactivated'
            ? StatusType.danger
            : StatusType.success,
        size: StatusChipSize.small,
        key: Key('status$index'),
      ),
    );
  }

  // Action button (deactivate/activate)
  cells.add(
    IconButton(
      key: Key('delete$index'),
      icon: Icon(
        asset.statusId == 'Available' || asset.statusId == 'In Use'
            ? Icons.delete_forever
            : Icons.event_available,
      ),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      onPressed: () {
        if (asset.statusId == 'Available' || asset.statusId == 'In Use') {
          bloc.add(AssetUpdate(asset.copyWith(statusId: 'Deactivated')));
        } else {
          bloc.add(AssetUpdate(asset.copyWith(statusId: 'Available')));
        }
      },
    ),
  );

  return cells;
}
