// ignore_for_file: unnecessary_string_interpolations

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
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_order_accounting/src/findoc/findoc.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../accounting/accounting.dart';

class ItemTypeListItem extends StatelessWidget {
  const ItemTypeListItem({
    super.key,
    required this.itemType,
    required this.index,
  });

  final ItemType itemType;
  final int index;

  @override
  Widget build(BuildContext context) {
    FinDocBloc finDocBloc = context.read<FinDocBloc>();

    var accountSelect = BlocBuilder<GlAccountBloc, GlAccountState>(
      builder: (context, state) {
        switch (state.status) {
          case GlAccountStatus.failure:
            return const FatalErrorForm(message: 'server connection problem');
          case GlAccountStatus.success:
            return Autocomplete<GlAccount>(
              key: Key(
                'glAccount_${itemType.itemTypeName}_${itemType.direction}',
              ),
              initialValue: TextEditingValue(
                text: itemType.accountCode.isNotEmpty
                    ? " ${itemType.accountCode} ${itemType.accountName} "
                    : '',
              ),
              displayStringForOption: (GlAccount u) =>
                  " ${u.accountCode ?? ''} ${u.accountName ?? ''} ",
              optionsBuilder: (TextEditingValue textEditingValue) {
                final query = textEditingValue.text.toLowerCase().trim();
                if (query.isEmpty) return state.glAccounts;
                return state.glAccounts.where((gl) {
                  final display =
                      " ${gl.accountCode ?? ''} ${gl.accountName ?? ''} "
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
                      decoration: const InputDecoration(),
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
                              " ${gl.accountCode ?? ''} ${gl.accountName ?? ''} ",
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
            return const Center(child: LoadingIndicator());
        }
      },
    );
    var direction = itemType.direction == 'I' ? 'InComing' : 'OutGoing';
    return ListTile(
      leading: CircleAvatar(
        child: Text(
          itemType.itemTypeName.isNotEmpty
              ? itemType.itemTypeName.substring(0, 3)
              : '',
        ),
      ),
      title: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              "${itemType.itemTypeName} $direction",
              key: Key('name$index'),
            ),
          ),
          if (ResponsiveBreakpoints.of(context).largerThan(MOBILE))
            Expanded(child: accountSelect),
        ],
      ),
      subtitle: ResponsiveBreakpoints.of(context).equals(MOBILE)
          ? accountSelect
          : null,
      trailing: IconButton(
        key: Key('delete$index'),
        icon: const Icon(Icons.delete_forever),
        onPressed: () {
          finDocBloc.add(
            FinDocUpdateItemType(itemType: itemType, delete: true),
          );
        },
      ),
    );
  }
}
