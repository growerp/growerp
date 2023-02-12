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

import 'package:growerp_core/growerp_core.dart';
import 'package:decimal/decimal.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../blocs/blocs.dart';

class PaymentDialog extends StatefulWidget {
  final FinDoc finDoc;
  final PaymentMethod? paymentMethod;
  const PaymentDialog(this.finDoc, {super.key, this.paymentMethod});
  @override
  PaymentDialogState createState() => PaymentDialogState();
}

class PaymentDialogState extends State<PaymentDialog> {
  final GlobalKey<FormState> paymentDialogFormKey = GlobalKey<FormState>();
  late FinDoc finDoc; // incoming finDoc
  late APIRepository repos;
  late FinDoc finDocUpdated;
  User? _selectedUser;
  ItemType? _selectedItemType;

  late bool isPhone;
  late PaymentInstrument _paymentInstrument;
  final _userSearchBoxController = TextEditingController();
  final _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    finDoc = widget.finDoc;
    repos = context.read<APIRepository>();
    finDocUpdated = finDoc;
    _selectedUser = finDocUpdated.otherUser;
    _amountController.text =
        finDoc.grandTotal == null ? '' : finDoc.grandTotal.toString();
    _selectedItemType = finDocUpdated.items.isNotEmpty &&
            finDocUpdated.items[0].itemTypeId != null
        ? ItemType(
            itemTypeId: finDocUpdated.items[0].itemTypeId!, itemTypeName: '')
        : null;
    _paymentInstrument = finDocUpdated.paymentInstrument == null
        ? PaymentInstrument.cash
        : finDocUpdated.paymentInstrument!;
  }

  @override
  Widget build(BuildContext context) {
    isPhone = ResponsiveWrapper.of(context).isSmallerThan(TABLET);
    return GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Scaffold(
            backgroundColor: Colors.transparent,
            body: GestureDetector(
                onTap: () {},
                child: Dialog(
                    key: Key(
                        "PaymentDialog${finDoc.sales ? 'Sales' : 'Purchase'}"),
                    insetPadding: const EdgeInsets.all(10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: BlocConsumer<FinDocBloc, FinDocState>(
                      listener: (context, state) {
                        if (state.status == FinDocStatus.success) {
                          Navigator.of(context).pop();
                        }
                        if (state.status == FinDocStatus.failure) {
                          HelperFunctions.showMessage(
                              context, '${state.message}', Colors.red);
                        }
                      },
                      builder: (context, state) {
                        return popUp(
                            context: context,
                            height: 750,
                            width: 400,
                            title:
                                "${finDoc.sales ? 'Sales/incoming' : 'Purchase/outgoing'} "
                                "Payment #${finDoc.paymentId ?? 'new'}",
                            child: SingleChildScrollView(
                                key: const Key('listView2'),
                                physics: const ClampingScrollPhysics(),
                                child:
                                    paymentForm(state, paymentDialogFormKey)));
                      },
                    )))));
  }

  Widget paymentForm(
      FinDocState state, GlobalKey<FormState> paymentDialogFormKey) {
    if (_selectedItemType != null) {
      _selectedItemType = state.itemTypes
          .firstWhere((el) => _selectedItemType!.itemTypeId == el.itemTypeId);
    }
    FinDocBloc finDocBloc = context.read<FinDocBloc>();
    AuthBloc authBloc = context.read<AuthBloc>();
    Color getColor(Set<MaterialState> states) {
      const Set<MaterialState> interactiveStates = <MaterialState>{
        MaterialState.pressed,
        MaterialState.hovered,
        MaterialState.focused,
      };
      if (states.any(interactiveStates.contains)) {
        return Colors.blue;
      }
      return Colors.red;
    }

    return Padding(
        padding: const EdgeInsets.all(10),
        child: Form(
            key: paymentDialogFormKey,
            child: Column(children: <Widget>[
              DropdownSearch<User>(
                selectedItem: _selectedUser,
                popupProps: PopupProps.menu(
                  showSearchBox: true,
                  searchFieldProps: TextFieldProps(
                    autofocus: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25.0)),
                    ),
                    controller: _userSearchBoxController,
                  ),
                  menuProps:
                      MenuProps(borderRadius: BorderRadius.circular(20.0)),
                  title: popUp(
                    context: context,
                    title:
                        "Select ${finDocUpdated.sales ? 'customer' : 'supplier'}",
                    height: 50,
                  ),
                ),
                dropdownSearchDecoration: InputDecoration(
                  labelText: finDocUpdated.sales ? 'Customer' : 'Supplier',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25.0)),
                ),
                key: Key(finDocUpdated.sales ? 'customer' : 'supplier'),
                itemAsString: (User? u) =>
                    "${u!.company!.name},\n${u.firstName ?? ''} ${u.lastName ?? ''}",
                asyncItems: (String? filter) async {
                  ApiResult<List<User>> result = await repos.getUser(
                      role: finDocUpdated.sales == true
                          ? Role.customer
                          : Role.supplier,
                      filter: _userSearchBoxController.text);
                  return result.when(
                      success: (data) => data,
                      failure: (_) => [User(lastName: 'get data error!')]);
                },
                onChanged: (User? newValue) {
                  setState(() {
                    _selectedUser = newValue;
                  });
                },
                validator: (value) => value == null
                    ? "Select ${finDocUpdated.sales ? 'Customer' : 'Supplier'}!"
                    : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                  key: const Key('amount'),
                  decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(
                          vertical: 35.0, horizontal: 10.0),
                      labelText: 'Amount'),
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      value!.isEmpty ? "Enter Price or Amount?" : null),
              const SizedBox(height: 20),
              InputDecorator(
                decoration: InputDecoration(
                  labelText: 'PaymentMethods',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                ),
                child: Column(
                  children: [
                    Visibility(
                        visible: (finDoc.sales == true &&
                                _selectedUser?.company!.paymentMethod
                                        ?.ccDescription !=
                                    null) ||
                            (finDoc.sales == false &&
                                authBloc.state.authenticate?.company
                                        ?.paymentMethod?.ccDescription !=
                                    null),
                        child: Row(children: [
                          Checkbox(
                              key: const Key('creditCard'),
                              checkColor: Colors.white,
                              fillColor:
                                  MaterialStateProperty.resolveWith(getColor),
                              value: _paymentInstrument ==
                                  PaymentInstrument.creditcard,
                              onChanged: (bool? value) {
                                setState(() {
                                  if (value == true) {
                                    _paymentInstrument =
                                        PaymentInstrument.creditcard;
                                  }
                                });
                              }),
                          Expanded(
                              child: Text(
                                  "Credit Card ${finDoc.sales == false ? "${authBloc.state.authenticate?.company?.paymentMethod?.ccDescription}" : "${_selectedUser?.company!.paymentMethod?.ccDescription}"}")),
                        ])),
                    Row(children: [
                      Checkbox(
                          key: const Key('cash'),
                          checkColor: Colors.white,
                          fillColor:
                              MaterialStateProperty.resolveWith(getColor),
                          value: _paymentInstrument == PaymentInstrument.cash,
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                _paymentInstrument = PaymentInstrument.cash;
                              }
                            });
                          }),
                      const Expanded(
                          child: Text(
                        "Cash",
                      )),
                    ]),
                    Row(children: [
                      Checkbox(
                          key: const Key('check'),
                          checkColor: Colors.white,
                          fillColor:
                              MaterialStateProperty.resolveWith(getColor),
                          value: _paymentInstrument == PaymentInstrument.check,
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                _paymentInstrument = PaymentInstrument.check;
                              }
                            });
                          }),
                      const Expanded(
                          child: Text(
                        "Check",
                      )),
                    ]),
                    Row(children: [
                      Checkbox(
                          key: const Key('bank'),
                          checkColor: Colors.white,
                          fillColor:
                              MaterialStateProperty.resolveWith(getColor),
                          value: _paymentInstrument == PaymentInstrument.bank,
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                _paymentInstrument = PaymentInstrument.bank;
                              }
                            });
                          }),
                      Expanded(
                          child: Text(
                        "Bank ${finDoc.otherUser?.company!.paymentMethod?.creditCardNumber ?? ''}",
                      )),
                    ]),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<ItemType>(
                key: const Key('itemType'),
                decoration: const InputDecoration(labelText: 'Item Type'),
                hint: const Text('ItemType'),
                value: _selectedItemType,
                validator: (value) =>
                    value == null ? 'Enter a item type for posting?' : null,
                items: state.itemTypes.map((item) {
                  return DropdownMenuItem<ItemType>(
                      value: item, child: Text(item.itemTypeName));
                }).toList(),
                onChanged: (ItemType? newValue) {
                  _selectedItemType = newValue;
                },
                isExpanded: true,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  ElevatedButton(
                      key: const Key('cancelFinDoc'),
                      child: const Text('Cancel Payment'),
                      onPressed: () {
                        finDocBloc.add(FinDocUpdate(finDocUpdated.copyWith(
                          status: FinDocStatusVal.cancelled,
                        )));
                      }),
                  const SizedBox(width: 20),
                  Expanded(
                    child: ElevatedButton(
                        key: const Key('update'),
                        child: Text(
                            '${finDoc.idIsNull() ? 'Create ' : 'Update '}${finDocUpdated.docType}'),
                        onPressed: () {
                          if (paymentDialogFormKey.currentState!.validate()) {
                            finDocBloc.add(FinDocUpdate(finDocUpdated.copyWith(
                              otherUser: _selectedUser,
                              grandTotal: Decimal.parse(_amountController.text),
                              paymentInstrument: _paymentInstrument,
                              items: [
                                FinDocItem(
                                    itemTypeId: _selectedItemType?.itemTypeId)
                              ],
                            )));
                          }
                        }),
                  ),
                ],
              ),
            ])));
  }
}
