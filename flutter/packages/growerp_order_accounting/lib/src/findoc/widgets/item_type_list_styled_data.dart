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

import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

import '../../accounting/accounting.dart';
import '../findoc.dart';

/// Returns column definitions for item type list based on device type
List<StyledColumn> getItemTypeListColumns(BuildContext context) {
  bool isPhone = isAPhone(context);

  if (isPhone) {
    return [
      const StyledColumn(header: '', flex: 1), // Avatar
      const StyledColumn(header: 'Item Type / Direction', flex: 3),
      const StyledColumn(header: 'Account', flex: 3),
      const StyledColumn(header: '', flex: 1), // Actions
    ];
  }

  return [
    const StyledColumn(header: '', flex: 1), // Avatar
    const StyledColumn(header: 'Item Type', flex: 2),
    const StyledColumn(header: 'Direction', flex: 1),
    const StyledColumn(header: 'Account Code', flex: 2),
    const StyledColumn(header: 'Account Name', flex: 3),
    const StyledColumn(header: '', flex: 1), // Actions
  ];
}

/// Returns row data for item type list
List<Widget> getItemTypeListRow({
  required BuildContext context,
  required ItemType itemType,
  required int index,
  required FinDocBloc finDocBloc,
  required GlAccountBloc glAccountBloc,
}) {
  bool isPhone = isAPhone(context);
  List<Widget> cells = [];

  // Avatar
  cells.add(
    CircleAvatar(
      radius: 16,
      child: Text(
        itemType.itemTypeName.isNotEmpty
            ? itemType.itemTypeName.substring(0, 2).toUpperCase()
            : '?',
        style: const TextStyle(fontSize: 12),
      ),
    ),
  );

  var direction = itemType.direction == 'I' ? 'Incoming' : 'Outgoing';

  // Account dropdown widget
  Widget accountSelect = BlocBuilder<GlAccountBloc, GlAccountState>(
    builder: (context, state) {
      switch (state.status) {
        case GlAccountStatus.failure:
          return const Text('Error');
        case GlAccountStatus.success:
          return DropdownSearch<GlAccount>(
            selectedItem: GlAccount(
              accountCode: itemType.accountCode,
              accountName: itemType.accountName,
            ),
            popupProps: PopupProps.menu(
              isFilterOnline: true,
              showSelectedItems: true,
              showSearchBox: true,
              searchFieldProps: const TextFieldProps(
                autofocus: true,
                decoration: InputDecoration(labelText: 'GL Account'),
              ),
              menuProps: MenuProps(borderRadius: BorderRadius.circular(20.0)),
              title: popUp(
                context: context,
                title: 'Select GL Account',
                height: 50,
              ),
            ),
            dropdownDecoratorProps: const DropDownDecoratorProps(
              dropdownSearchDecoration: InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
            key: Key('glAccount$index'),
            itemAsString: (GlAccount? u) =>
                "${u?.accountCode ?? ''} ${u?.accountName ?? ''}",
            asyncItems: (String filter) async {
              glAccountBloc.add(GlAccountFetch(searchString: filter, limit: 3));
              return Future.delayed(const Duration(milliseconds: 100), () {
                return Future.value(glAccountBloc.state.glAccounts);
              });
            },
            compareFn: (item, sItem) => item.accountCode == sItem.accountCode,
            onChanged: (GlAccount? newValue) {
              finDocBloc.add(
                FinDocUpdateItemType(
                  itemType: itemType.copyWith(
                    accountCode: newValue!.accountCode!,
                    accountName: newValue.accountName!,
                  ),
                  update: true,
                ),
              );
            },
          );
        default:
          return const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
      }
    },
  );

  if (isPhone) {
    // Combined item type & direction
    cells.add(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            itemType.itemTypeName,
            key: Key('name$index'),
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            direction,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );

    // Account dropdown
    cells.add(Expanded(child: accountSelect));
  } else {
    // Item type name
    cells.add(Text(itemType.itemTypeName, key: Key('name$index')));

    // Direction
    cells.add(Text(direction, key: Key('direction$index')));

    // Account code
    cells.add(Text(itemType.accountCode, key: Key('accountCode$index')));

    // Account dropdown
    cells.add(Expanded(child: accountSelect));
  }

  // Delete action
  cells.add(
    IconButton(
      key: Key('delete$index'),
      icon: const Icon(Icons.delete_forever),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      onPressed: () {
        finDocBloc.add(FinDocUpdateItemType(itemType: itemType, delete: true));
      },
    ),
  );

  return cells;
}
