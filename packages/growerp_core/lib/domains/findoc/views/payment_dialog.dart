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

import '../../domains.dart';
import 'package:decimal/decimal.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../../../api_repository.dart';
import '../../../services/api_result.dart';
import '../../common/functions/helper_functions.dart';

class PaymentDialog extends StatefulWidget {
  final FinDoc finDoc;
  final PaymentMethod? paymentMethod;
  PaymentDialog(this.finDoc, {this.paymentMethod});
  @override
  _PaymentState createState() => _PaymentState(finDoc);
}

class _PaymentState extends State<PaymentDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FinDoc finDoc; // incoming finDoc
  late APIRepository repos;
  late FinDoc finDocUpdated;
  User? _selectedUser;
  ItemType? _selectedItemType;

  late bool isPhone;
  late PaymentInstrument _paymentInstrument;
  final _userSearchBoxController = TextEditingController();
  final _amountController = TextEditingController();
  _PaymentState(this.finDoc);

  @override
  void initState() {
    super.initState();
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
                    insetPadding: EdgeInsets.all(10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: BlocConsumer<FinDocBloc, FinDocState>(
                      listener: (context, state) {
                        if (state.status == FinDocStatus.success)
                          Navigator.of(context).pop();
                        if (state.status == FinDocStatus.failure)
                          HelperFunctions.showMessage(
                              context, '${state.message}', Colors.red);
                      },
                      builder: (context, state) {
                        return SingleChildScrollView(
                            key: Key('listView2'),
                            physics: ClampingScrollPhysics(),
                            child: Stack(clipBehavior: Clip.none, children: [
                              Container(
                                  width: 400,
                                  height: 750,
                                  child: paymentForm(state, _formKey)),
                              Positioned(
                                  top: 10,
                                  right: 10,
                                  child: DialogCloseButton())
                            ]));
                      },
                    )))));
  }

  Widget paymentForm(FinDocState state, GlobalKey<FormState> _formKey) {
    if (_selectedItemType != null) {
      _selectedItemType = state.itemTypes
          .firstWhere((el) => _selectedItemType!.itemTypeId == el.itemTypeId);
    }
    FinDocBloc finDocBloc = context.read<FinDocBloc>();
    AuthBloc authBloc = context.read<AuthBloc>();
//    finDocBloc.add(FinDocGetItemTypes(sales: finDocUpdated.sales));
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
        padding: EdgeInsets.all(10),
        child: Form(
            key: _formKey,
            child: Column(children: <Widget>[
              SizedBox(height: 20),
              Center(
                  child: Text(
                      "${finDoc.sales ? 'Sales/incoming' : 'Purchase/outgoing'} "
                      "Payment #${finDoc.paymentId ?? 'new'}",
                      style: TextStyle(
                          fontSize: 10,
                          color: Colors.black,
                          fontWeight: FontWeight.bold),
                      key: Key('header'))),
              SizedBox(height: 30),
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
                  title: Container(
                      height: 50,
                      decoration: BoxDecoration(
                          color: Theme.of(context).primaryColorDark,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          )),
                      child: Center(
                          child: Text('Select customer',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              )))),
                ),
                dropdownSearchDecoration: InputDecoration(
                  labelText: finDocUpdated.sales ? 'Customer' : 'Supplier',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25.0)),
                ),
                key: Key(finDocUpdated.sales ? 'customer' : 'supplier'),
                itemAsString: (User? u) =>
                    "${u!.companyName},\n${u.firstName ?? ''} ${u.lastName ?? ''}",
                asyncItems: (String? filter) async {
                  ApiResult<List<User>> result = await repos.getUser(
                      userGroups: [UserGroup.Customer, UserGroup.Supplier],
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
              SizedBox(height: 20),
              TextFormField(
                  key: Key('amount'),
                  decoration: InputDecoration(
                      contentPadding: new EdgeInsets.symmetric(
                          vertical: 35.0, horizontal: 10.0),
                      labelText: 'Amount'),
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      value!.isEmpty ? "Enter Price or Amount?" : null),
              SizedBox(height: 20),
              Container(
                child: InputDecorator(
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
                                  _selectedUser?.companyPaymentMethod
                                          ?.ccDescription !=
                                      null) ||
                              (finDoc.sales == false &&
                                  authBloc.state.authenticate?.company
                                          ?.paymentMethod?.ccDescription !=
                                      null),
                          child: Row(children: [
                            Checkbox(
                                key: Key('creditCard'),
                                checkColor: Colors.white,
                                fillColor:
                                    MaterialStateProperty.resolveWith(getColor),
                                value: _paymentInstrument ==
                                    PaymentInstrument.creditcard,
                                onChanged: (bool? value) {
                                  setState(() {
                                    if (value == true)
                                      _paymentInstrument =
                                          PaymentInstrument.creditcard;
                                  });
                                }),
                            Expanded(
                                child: Text("Credit Card " +
                                    (finDoc.sales == false
                                        ? "${authBloc.state.authenticate?.company?.paymentMethod?.ccDescription}"
                                        : "${_selectedUser?.companyPaymentMethod?.ccDescription}"))),
                          ])),
                      Row(children: [
                        Checkbox(
                            key: Key('cash'),
                            checkColor: Colors.white,
                            fillColor:
                                MaterialStateProperty.resolveWith(getColor),
                            value: _paymentInstrument == PaymentInstrument.cash,
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true)
                                  _paymentInstrument = PaymentInstrument.cash;
                              });
                            }),
                        Expanded(
                            child: Text(
                          "Cash",
                        )),
                      ]),
                      Row(children: [
                        Checkbox(
                            key: Key('check'),
                            checkColor: Colors.white,
                            fillColor:
                                MaterialStateProperty.resolveWith(getColor),
                            value:
                                _paymentInstrument == PaymentInstrument.check,
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true)
                                  _paymentInstrument = PaymentInstrument.check;
                              });
                            }),
                        Expanded(
                            child: Text(
                          "Check",
                        )),
                      ]),
                      Row(children: [
                        Checkbox(
                            key: Key('bank'),
                            checkColor: Colors.white,
                            fillColor:
                                MaterialStateProperty.resolveWith(getColor),
                            value: _paymentInstrument == PaymentInstrument.bank,
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true)
                                  _paymentInstrument = PaymentInstrument.bank;
                              });
                            }),
                        Expanded(
                            child: Text(
                          "Bank ${finDoc.otherUser?.companyPaymentMethod?.creditCardNumber ?? ''}",
                        )),
                      ]),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              DropdownButtonFormField<ItemType>(
                key: Key('itemType'),
                decoration: InputDecoration(labelText: 'Item Type'),
                hint: Text('ItemType'),
                value: _selectedItemType,
                validator: (value) =>
                    value == null ? 'Enter a item type for posting?' : null,
                items: state.itemTypes.map((item) {
                  return DropdownMenuItem<ItemType>(
                      child: Text(item.itemTypeName), value: item);
                }).toList(),
                onChanged: (ItemType? newValue) {
                  _selectedItemType = newValue;
                },
                isExpanded: true,
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  ElevatedButton(
                      key: Key('cancelFinDoc'),
                      child: Text('Cancel Payment'),
                      onPressed: () {
                        finDocBloc.add(FinDocUpdate(finDocUpdated.copyWith(
                          status: FinDocStatusVal.Cancelled,
                        )));
                      }),
                  SizedBox(width: 20),
                  Expanded(
                    child: ElevatedButton(
                        key: Key('update'),
                        child: Text(
                            (finDoc.idIsNull() ? 'Create ' : 'Update ') +
                                '${finDocUpdated.docType}'),
                        onPressed: () {
                          if (_formKey.currentState!.validate())
                            finDocBloc.add(FinDocUpdate(finDocUpdated.copyWith(
                              otherUser: _selectedUser,
                              grandTotal: Decimal.parse(_amountController.text),
                              paymentInstrument: _paymentInstrument,
                              items: [
                                FinDocItem(
                                    itemTypeId: _selectedItemType?.itemTypeId)
                              ],
                            )));
                        }),
                  ),
                ],
              ),
            ])));
  }
}
