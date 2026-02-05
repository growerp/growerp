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

import '../blocs/asset_bloc.dart';

/// Returns column definitions for asset list based on device type
List<StyledColumn> getAssetListColumns(
  BuildContext context, {
  String? classificationId,
}) {
  bool isPhone = isAPhone(context);
  final isHotel = classificationId == 'AppHotel';

  if (isPhone) {
    return [
      const StyledColumn(header: '', flex: 1), // Avatar
      const StyledColumn(header: 'Info', flex: 4),
      const StyledColumn(header: 'Status', flex: 1),
      const StyledColumn(header: '', flex: 1), // Actions
    ];
  }

  if (isHotel) {
    return [
      const StyledColumn(header: 'Room Nr', flex: 1),
      const StyledColumn(header: 'Room Name', flex: 2),
      const StyledColumn(header: 'Room Type', flex: 2),
      const StyledColumn(header: 'List Price', flex: 1),
      const StyledColumn(header: 'Price', flex: 1),
      const StyledColumn(header: 'Active', flex: 1),
      const StyledColumn(header: '', flex: 1), // Actions
    ];
  }

  return [
    const StyledColumn(header: 'ID', flex: 1),
    const StyledColumn(header: 'Product', flex: 3),
    const StyledColumn(header: 'Qty', flex: 1),
    const StyledColumn(header: 'Cost', flex: 1),
    const StyledColumn(header: 'Location', flex: 1),
    const StyledColumn(header: 'Active', flex: 1),
    const StyledColumn(header: '', flex: 1), // Actions
  ];
}

/// Returns row data for asset list
List<Widget> getAssetListRow({
  required BuildContext context,
  required Asset asset,
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
      cells.add(Text(asset.pseudoId, key: Key('id$index')));

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
      cells.add(Text(asset.pseudoId, key: Key('id$index')));

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
