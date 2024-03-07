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

import '../../accounting/accounting.dart';
import '../findoc.dart';

class PaymentTypeListItem extends StatelessWidget {
  const PaymentTypeListItem(
      {super.key, required this.paymentType, required this.index});

  final PaymentType paymentType;
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
                accountCode: paymentType.accountCode,
                accountName: paymentType.accountName),
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
              finDocBloc.add(FinDocUpdatePaymentType(
                  paymentType: paymentType.copyWith(
                      accountCode: newValue!.accountCode!,
                      accountName: newValue.accountName!),
                  update: true));
            },
          );
        default:
          return const Center(child: CircularProgressIndicator());
      }
    });

    return ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green,
          child: Text(paymentType.paymentTypeName.substring(3, 5)),
        ),
        title: Row(
          children: <Widget>[
            Expanded(
                child: Text(
                    "${paymentType.paymentTypeName} -- "
                    "${paymentType.isPayable ? 'Outgoing' : 'Incoming'} -- "
                    "${paymentType.isApplied ? 'Y' : 'N'}",
                    key: Key('name$index'))),
            if (!isPhone(context)) Expanded(child: accountSelect),
          ],
        ),
        subtitle: isPhone(context) ? accountSelect : null,
        trailing: IconButton(
            key: Key('delete$index'),
            icon: const Icon(Icons.delete_forever),
            onPressed: () {
              finDocBloc.add(FinDocUpdatePaymentType(
                  paymentType: paymentType, delete: true));
            }));
  }
}
