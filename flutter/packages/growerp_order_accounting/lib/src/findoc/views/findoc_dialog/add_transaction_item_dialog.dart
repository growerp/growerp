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

import 'package:decimal/decimal.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

import '../../../accounting/accounting.dart';
import '../../findoc.dart';

Future addTransactionItemDialog(BuildContext context, bool sales,
    CartState state, GlAccountBloc glAccountBloc) async {
  final priceController = TextEditingController();
  bool? isDebit;
  GlAccount? selectedGlAccount;
  return showDialog<FinDocItem>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      var addOtherFormKey = GlobalKey<FormState>();
      return BlocProvider.value(
          value: glAccountBloc,
          child: Dialog(
              key: const Key('addTransactionItemDialog'),
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20))),
              child: popUp(
                context: context,
                height: 400,
                title: 'Add Transaction Item',
                child: Form(
                    key: addOtherFormKey,
                    child: SingleChildScrollView(
                        key: const Key('listView2'),
                        child: Column(children: <Widget>[
                          BlocBuilder<GlAccountBloc, GlAccountState>(
                              builder: (context, state) {
                            switch (state.status) {
                              case GlAccountStatus.failure:
                                return const FatalErrorForm(
                                    message: 'server connection problem');
                              case GlAccountStatus.success:
                                return DropdownSearch<GlAccount>(
                                  selectedItem: selectedGlAccount,
                                  popupProps: PopupProps.menu(
                                    isFilterOnline: true,
                                    showSelectedItems: true,
                                    showSearchBox: true,
                                    searchFieldProps: const TextFieldProps(
                                      autofocus: true,
                                      decoration: InputDecoration(
                                          labelText: 'Gl Account'),
                                    ),
                                    menuProps: MenuProps(
                                        borderRadius:
                                            BorderRadius.circular(20.0)),
                                    title: popUp(
                                      context: context,
                                      title: 'Select GL Account',
                                      height: 50,
                                    ),
                                  ),
                                  dropdownDecoratorProps:
                                      const DropDownDecoratorProps(
                                          dropdownSearchDecoration:
                                              InputDecoration(
                                                  labelText: 'GL Account')),
                                  key: const Key('glAccount'),
                                  itemAsString: (GlAccount? u) =>
                                      " ${u?.accountCode} ${u?.accountName} ",
                                  asyncItems: (String filter) async {
                                    glAccountBloc.add(GlAccountFetch(
                                        searchString: filter, limit: 3));
                                    return Future.delayed(
                                        const Duration(milliseconds: 100), () {
                                      return Future.value(
                                          glAccountBloc.state.glAccounts);
                                    });
                                  },
                                  compareFn: (item, sItem) =>
                                      item.accountCode == sItem.accountCode,
                                  onChanged: (GlAccount? newValue) {
                                    selectedGlAccount = newValue!;
                                  },
                                );
                              default:
                                return const Center(child: LoadingIndicator());
                            }
                          }),
                          const SizedBox(height: 20),
                          CreditDebitButton(
                              isDebit: isDebit,
                              onValueChanged: (id) {
                                isDebit = id;
                              }),
                          TextFormField(
                            key: const Key('price'),
                            decoration:
                                const InputDecoration(labelText: 'Amount'),
                            controller: priceController,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value!.isEmpty) {
                                return 'Enter Amount?';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          OutlinedButton(
                            key: const Key('ok'),
                            child: const Text('Ok'),
                            onPressed: () {
                              if (addOtherFormKey.currentState!.validate()) {
                                // ignore: unnecessary_null_comparison
                                if (isDebit == null) {
                                  HelperFunctions.showMessage(
                                      context,
                                      'Debit / credit selection required',
                                      Colors.red);
                                } else {
                                  Navigator.of(context).pop(FinDocItem(
                                    glAccount: selectedGlAccount,
                                    isDebit: isDebit,
                                    price: Decimal.parse(priceController.text),
                                  ));
                                }
                              }
                            },
                          ),
                        ]))),
              )));
    },
  );
}
