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

import '../../accounting/accounting.dart';
import '../findoc.dart';
import 'package:growerp_order_accounting/l10n/generated/order_accounting_localizations.dart';

/// Returns column definitions for item type list based on device type
List<StyledColumn> getItemTypeListColumns(BuildContext context) {
  final localizations = OrderAccountingLocalizations.of(context)!;
  bool isPhone = isAPhone(context);

  if (isPhone) {
    return [
      const StyledColumn(header: '', flex: 1), // Avatar
      StyledColumn(header: localizations.tableHdrItemTypeDirection, flex: 3),
      StyledColumn(header: localizations.tableHdrAccount, flex: 3),
      const StyledColumn(header: '', flex: 1), // Actions
    ];
  }

  return [
    const StyledColumn(header: '', flex: 1), // Avatar
    StyledColumn(header: localizations.tableHdrItemType, flex: 2),
    StyledColumn(header: localizations.tableHdrDirection, flex: 1),
    StyledColumn(header: localizations.accountCode, flex: 2),
    StyledColumn(header: localizations.accountName, flex: 3),
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
          return Text(OrderAccountingLocalizations.of(context)!.error);
        case GlAccountStatus.success:
          return Autocomplete<GlAccount>(
            key: Key(
              'glAccount_${itemType.itemTypeName}_${itemType.direction}',
            ),
            initialValue: TextEditingValue(
              text: itemType.accountCode.isNotEmpty
                  ? "${itemType.accountCode} ${itemType.accountName}"
                  : '',
            ),
            displayStringForOption: (GlAccount u) =>
                "${u.accountCode ?? ''} ${u.accountName ?? ''}",
            optionsBuilder: (TextEditingValue textEditingValue) {
              final query = textEditingValue.text.toLowerCase().trim();
              if (query.isEmpty) return state.glAccounts;
              return state.glAccounts.where((gl) {
                final display =
                    "${gl.accountCode ?? ''} ${gl.accountName ?? ''}"
                        .toLowerCase();
                return display.contains(query);
              }).toList();
            },
            fieldViewBuilder:
                (context, textController, focusNode, onFieldSubmitted) {
                  return TextFormField(
                    key: Key(
                      'glAccountField_${itemType.itemTypeName}_${itemType.direction}',
                    ),
                    controller: textController,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8),
                    ),
                    onFieldSubmitted: (_) => onFieldSubmitted(),
                  );
                },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(12),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxHeight: 250,
                      maxWidth: 400,
                    ),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (context, idx) {
                        final gl = options.elementAt(idx);
                        return ListTile(
                          dense: true,
                          title: Text(
                            "${gl.accountCode ?? ''} ${gl.accountName ?? ''}",
                          ),
                          onTap: () => onSelected(gl),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
            onSelected: (GlAccount newValue) {
              finDocBloc.add(
                FinDocUpdateItemType(
                  itemType: itemType.copyWith(
                    accountCode: newValue.accountCode!,
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
    cells.add(accountSelect);
  } else {
    // Item type name
    cells.add(Text(itemType.itemTypeName, key: Key('name$index')));

    // Direction
    cells.add(Text(direction, key: Key('direction$index')));

    // Account code
    cells.add(Text(itemType.accountCode, key: Key('accountCode$index')));

    // Account dropdown
    cells.add(accountSelect);
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
