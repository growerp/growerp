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

import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_order_accounting/src/findoc/findoc.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../accounting/accounting.dart';

class ItemTypeListItem extends StatelessWidget {
  const ItemTypeListItem(
      {super.key, required this.itemType, required this.index});

  final ItemType itemType;
  final int index;

  @override
  Widget build(BuildContext context) {
    GlAccountBloc glAccountBloc = context.read<GlAccountBloc>();
    FinDocBloc finDocBloc = context.read<FinDocBloc>();

    var accountSelect =
        BlocBuilder<GlAccountBloc, GlAccountState>(builder: (context, state) {
      switch (state.status) {
        case GlAccountStatus.failure:
          return const FatalErrorForm(message: 'server connection problem');
        case GlAccountStatus.success:
          return DropdownSearch<GlAccount>(
            selectedItem: GlAccount(
                accountCode: itemType.accountCode,
                accountName: itemType.accountName),
            popupProps: PopupProps.menu(
              isFilterOnline: true,
              showSelectedItems: true,
              showSearchBox: true,
              searchFieldProps: const TextFieldProps(
                autofocus: true,
                decoration: InputDecoration(labelText: 'Gl Account'),
              ),
              menuProps: MenuProps(borderRadius: BorderRadius.circular(20.0)),
              title: popUp(
                context: context,
                title: 'Select GL Account',
                height: 50,
              ),
            ),
            dropdownDecoratorProps: const DropDownDecoratorProps(
                dropdownSearchDecoration: InputDecoration()),
            key: Key('glAccount$index'),
            itemAsString: (GlAccount? u) =>
                " ${u?.accountCode ?? ''} ${u?.accountName ?? ''} ",
            asyncItems: (String filter) async {
              glAccountBloc.add(GlAccountFetch(searchString: filter, limit: 3));
              return Future.delayed(const Duration(milliseconds: 100), () {
                return Future.value(glAccountBloc.state.glAccounts);
              });
            },
            compareFn: (item, sItem) => item.accountCode == sItem.accountCode,
            onChanged: (GlAccount? newValue) {
              finDocBloc.add(FinDocUpdateItemType(
                  itemType: itemType.copyWith(
                      accountCode: newValue!.accountCode!,
                      accountName: newValue.accountName!),
                  update: true));
            },
          );
        default:
          return const Center(child: CircularProgressIndicator());
      }
    });
    var direction = itemType.direction == 'I' ? 'InComing' : 'OutGoing';
    return ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green,
          child: Text(itemType.itemTypeName.isNotEmpty
              ? itemType.itemTypeName.substring(0, 3)
              : ''),
        ),
        title: Row(children: <Widget>[
          Expanded(
              child: Text("${itemType.itemTypeName} $direction",
                  key: Key('name$index'))),
          if (ResponsiveBreakpoints.of(context).largerThan(MOBILE))
            Expanded(child: accountSelect),
        ]),
        subtitle: ResponsiveBreakpoints.of(context).equals(MOBILE)
            ? accountSelect
            : null,
        trailing: IconButton(
            key: Key('delete$index'),
            icon: const Icon(Icons.delete_forever),
            onPressed: () {
              finDocBloc
                  .add(FinDocUpdateItemType(itemType: itemType, delete: true));
            }));
  }
}
