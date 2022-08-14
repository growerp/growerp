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

import 'package:core/domains/common/functions/helper_functions.dart';
import 'package:core/extensions.dart';
import 'package:core/services/api_result.dart';
import 'package:core/domains/domains.dart';
import 'package:decimal/decimal.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:intl/intl.dart';

import '../../../api_repository.dart';

class FinDocDialog extends StatelessWidget {
  final FinDoc finDoc;
  const FinDocDialog({Key? key, required this.finDoc}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    FinDocBloc finDocBloc = context.read<FinDocBloc>();
    if (finDoc.sales)
      return BlocProvider<SalesCartBloc>(
          create: (context) => CartBloc(
              docType: finDoc.docType!,
              sales: true,
              finDocBloc: finDocBloc,
              repos: context.read<APIRepository>())
            ..add(CartFetch(finDoc)),
          child: FinDocPage(finDoc));
    return BlocProvider<PurchaseCartBloc>(
        create: (context) => CartBloc(
            docType: finDoc.docType!,
            sales: false,
            finDocBloc: finDocBloc,
            repos: context.read<APIRepository>())
          ..add(CartFetch(finDoc)),
        child: FinDocPage(finDoc));
  }
}

class FinDocPage extends StatefulWidget {
  final FinDoc finDoc;
  FinDocPage(this.finDoc);
  @override
  _MyFinDocState createState() => _MyFinDocState(finDoc);
}

class _MyFinDocState extends State<FinDocPage> {
  final FinDoc finDoc; // incoming finDoc
  final _formKeyHeader = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _userSearchBoxController = TextEditingController();
  late CartBloc _cartBloc;
  late APIRepository repos;
  late FinDoc finDocUpdated;
  User? _selectedUser;

  late bool isPhone;
  _MyFinDocState(this.finDoc);

  @override
  void initState() {
    super.initState();
    finDocUpdated = finDoc;
    _selectedUser = finDocUpdated.otherUser;
    _descriptionController.text = finDocUpdated.description ?? "";
    if (finDoc.sales) {
      _cartBloc = context.read<SalesCartBloc>() as CartBloc;
    } else {
      _cartBloc = context.read<PurchaseCartBloc>() as CartBloc;
    }
    repos = context.read<APIRepository>();
  }

  @override
  Widget build(BuildContext context) {
    isPhone = ResponsiveWrapper.of(context).isSmallerThan(TABLET);

    dynamic blocConsumerListener =
        (BuildContext context, CartState state) async {
      switch (state.status) {
        case CartStatus.complete:
          HelperFunctions.showMessage(
              context,
              '${finDoc.idIsNull() ? "Add" : "Update"} successfull',
              Colors.green);
          await Future.delayed(Duration(milliseconds: 500));
          Navigator.of(context).pop();
          break;
        case CartStatus.failure:
          HelperFunctions.showMessage(context, '${state.message}', Colors.red);
          break;
        default:
          return const Center(child: CircularProgressIndicator());
      }
    };

    dynamic blocConsumerBuilder = (BuildContext context, CartState state) {
      switch (state.status) {
        case CartStatus.inProcess:
          finDocUpdated = state.finDoc;
          return Column(children: [
            Center(
                child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                        color: Theme.of(context).primaryColorDark,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        )),
                    child: Center(
                        child: Text(
                            '${finDoc.docType} #${finDoc.id() ?? ' new'}',
                            key: Key('header'),
                            style: TextStyle(
                                fontSize: 20,
                                color: Colors.white,
                                fontWeight: FontWeight.bold))))),
            SizedBox(height: isPhone ? 10 : 20),
            headerEntry(repos),
            SizedBox(
                height: isPhone ? 110 : 40, child: updateButtons(repos, state)),
            finDocItemList(state),
            SizedBox(height: 10),
            Center(
                child: Text(
                    "Items# ${finDocUpdated.items.length}   Grand total : " +
                        (finDocUpdated.grandTotal == null
                            ? "0.00"
                            : finDocUpdated.grandTotal.toString()),
                    key: Key('grandTotal'))),
            Padding(
                padding: EdgeInsets.all(10),
                child: SizedBox(height: 40, child: generalButtons())),
          ]);
        default:
          return LoadingIndicator();
      }
    };
    return GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Scaffold(
            backgroundColor: Colors.transparent,
            body: GestureDetector(
                onTap: () {},
                child: Dialog(
                    key: Key(
                        "FinDocDialog${finDoc.sales == true ? 'Sales' : 'Purchase'}"
                        "${finDoc.docType}"),
                    insetPadding: EdgeInsets.all(10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: SingleChildScrollView(
                        key: Key('listView1'),
                        child: Stack(clipBehavior: Clip.none, children: [
                          Container(
                              width: isPhone ? 400 : 800,
                              height: isPhone
                                  ? 600
                                  : 600, // not increase height otherwise tests will fail
                              child: Builder(builder: (BuildContext context) {
                                if (finDoc.sales)
                                  return BlocConsumer<SalesCartBloc, CartState>(
                                      listener: blocConsumerListener,
                                      builder: blocConsumerBuilder);
                                // purchase from here
                                return BlocConsumer<PurchaseCartBloc,
                                        CartState>(
                                    listener: blocConsumerListener,
                                    builder: blocConsumerBuilder);
                              })),
                          Positioned(
                              top: 10, right: 10, child: DialogCloseButton())
                        ]))))));
  }

  Widget headerEntry(repos) {
    List<Widget> widgets = [
      Expanded(
          child: Padding(
              padding: EdgeInsets.all(10),
              child: DropdownSearch<User>(
                selectedItem: _selectedUser,
                popupProps: PopupProps.menu(
                  showSearchBox: true,
                  searchFieldProps: TextFieldProps(
                    autofocus: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20)),
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
                          child: Text(
                              "Select ${finDocUpdated.sales ? 'Customer' : 'Supplier'}",
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
                key: Key(finDocUpdated.sales == true ? 'customer' : 'supplier'),
                itemAsString: (User? u) =>
                    "${u!.companyName},\n${u.firstName ?? ''} ${u.lastName ?? ''}",
                asyncItems: (String? filter) async {
                  final finDocBloc = context.read<FinDocBloc>();
                  finDocBloc.add(FinDocGetUsers(
                      userGroups: finDocUpdated.sales == true
                          ? [UserGroup.Customer]
                          : [UserGroup.Supplier],
                      filter: _userSearchBoxController.text));
                  int times = 0;
                  while (finDocBloc.state.users.isEmpty && times++ < 10)
                    await Future.delayed(Duration(milliseconds: 500));
                  return finDocBloc.state.users;
                },
                onChanged: (User? newValue) {
                  setState(() {
                    _selectedUser = newValue;
                  });
                },
                validator: (value) => value == null
                    ? "Select ${finDocUpdated.sales ? 'Customer' : 'Supplier'}!"
                    : null,
              ))),
      Expanded(
          child: Padding(
              padding: EdgeInsets.all(10),
              child: TextFormField(
                key: Key('description'),
                decoration: InputDecoration(
                    contentPadding: new EdgeInsets.symmetric(
                        vertical: 35.0, horizontal: 10.0),
                    labelText: '${finDoc.docType} Description'),
                controller: _descriptionController,
              ))),
    ];

    return Center(
      child: Container(
          height: isPhone ? 200 : 110,
          child: Form(
              key: _formKeyHeader,
              child: Column(
                  children: isPhone
                      ? widgets
                      : [
                          Row(children: [widgets[0], widgets[1]])
                        ]))),
    );
  }

  Widget updateButtons(repos, state) {
    List<Widget> buttons = [
      ElevatedButton(
          child: Text("Update header"),
          onPressed: () {
            _cartBloc.add(CartHeader(finDocUpdated.copyWith(
                otherUser: _selectedUser,
                description: _descriptionController.text)));
          }),
      ElevatedButton(
          key: Key('addItem'),
          child: Text('Add other Item'),
          onPressed: () async {
            final dynamic finDocItem = await addAnotherItemDialog(
                context, repos, finDocUpdated.sales, state);
            if (finDocItem != null)
              _cartBloc.add(CartAdd(
                  finDoc: finDocUpdated.copyWith(
                      otherUser: _selectedUser,
                      description: _descriptionController.text),
                  newItem: finDocItem));
          }),
      Visibility(
          visible: finDoc.docType == FinDocType.order,
          child: ElevatedButton(
              key: Key('itemRental'),
              child: Text('Asset Rental'),
              onPressed: () async {
                final dynamic finDocItem =
                    await addRentalItemDialog(context, repos);
                if (finDocItem != null)
                  _cartBloc.add(CartAdd(
                      finDoc: finDocUpdated.copyWith(
                          otherUser: _selectedUser,
                          description: _descriptionController.text),
                      newItem: finDocItem));
              })),
      ElevatedButton(
          key: Key('addProduct'),
          child: Text('Add Product'),
          onPressed: () async {
            final dynamic finDocItem =
                await addProductItemDialog(context, repos);
            if (finDocItem != null)
              _cartBloc.add(CartAdd(
                  finDoc: finDocUpdated.copyWith(
                      otherUser: _selectedUser,
                      description: _descriptionController.text),
                  newItem: finDocItem));
          }),
    ];

    if (isPhone) {
      List<Widget> rows = [];
      for (var i = 0; i < buttons.length; i++)
        rows.add(Row(children: [
          Expanded(
              child: Padding(
                  padding: EdgeInsets.fromLTRB(10, 0, 5, 5),
                  child: buttons[i])),
          Expanded(
              child: Padding(
                  padding: EdgeInsets.fromLTRB(5, 0, 10, 5),
                  child: buttons[++i]))
        ]));
      return Column(children: rows);
    }
    return Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround, children: buttons);
  }

  Widget generalButtons() {
    return Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          Visibility(
              visible: !finDoc.idIsNull(),
              child: ElevatedButton(
                  key: Key('cancelFinDoc'),
                  child: Text('Cancel ' + '${finDocUpdated.docType}'),
                  onPressed: () {
                    _cartBloc.add(CartCancelFinDoc(finDocUpdated));
                  })),
          ElevatedButton(
              key: Key('clear'),
              child: Text('Clear Cart'),
              onPressed: () {
                if (finDocUpdated.items.length > 0) {
                  _cartBloc.add(CartClear());
                }
              }),
          ElevatedButton(
              key: Key('update'),
              child: Text((finDoc.idIsNull() ? 'Create ' : 'Update ') +
                  '${finDocUpdated.docType}'),
              onPressed: () {
                finDocUpdated = finDocUpdated.copyWith(
                    otherUser: _selectedUser,
                    description: _descriptionController.text);
                if (finDocUpdated.items.length > 0 &&
                    finDocUpdated.otherUser != null) {
                  _cartBloc.add(CartCreateFinDoc(finDocUpdated));
                } else {
                  HelperFunctions.showMessage(
                      context,
                      'A ${finDocUpdated.sales ? "Customer" : "Supplier"} '
                      'and at least one ${finDocUpdated.docType} item is required!',
                      Colors.red);
                }
              }),
        ]);
  }

  Widget finDocItemList(CartState state) {
    List<FinDocItem> items = finDocUpdated.items;

    return Expanded(
        child: ListView.builder(
            itemCount: items.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return ListTile(
                  leading: !isPhone
                      ? CircleAvatar(
                          backgroundColor: Colors.transparent,
                        )
                      : null,
                  title: Column(children: [
                    Row(children: <Widget>[
                      if (!isPhone)
                        Expanded(
                            child:
                                Text("Item Type", textAlign: TextAlign.center)),
                      Expanded(
                          child: Text("Descr.", textAlign: TextAlign.center)),
                      Expanded(
                          child: Text("    Qty", textAlign: TextAlign.center)),
                      Expanded(
                          child: Text("Price", textAlign: TextAlign.center)),
                      if (!isPhone)
                        Expanded(
                            child:
                                Text("SubTotal", textAlign: TextAlign.center)),
                      Expanded(child: Text(" ", textAlign: TextAlign.center)),
                    ]),
                    Divider(color: Colors.black),
                  ]),
                );
              }
              if (index == 1 && items.isEmpty)
                return Center(
                    heightFactor: 20,
                    child: Text("no items found!",
                        key: Key('empty'), textAlign: TextAlign.center));
              final item = items[index - 1];
              var itemType = state.itemTypes
                  .firstWhere((e) => e.itemTypeId == item.itemTypeId);
              return ListTile(
                  key: Key('productItem'),
                  leading: !isPhone
                      ? CircleAvatar(
                          backgroundColor: Colors.green,
                          child: Text(item.itemSeqId.toString()),
                        )
                      : null,
                  title: Row(children: <Widget>[
                    if (!isPhone)
                      Expanded(
                          child: Text("${itemType.itemTypeName}",
                              textAlign: TextAlign.left,
                              key: Key('itemType${index - 1}'))),
                    Expanded(
                        child: Text("${item.description}",
                            key: Key('itemDescription${index - 1}'),
                            textAlign: TextAlign.left)),
                    Expanded(
                        child: Text("${item.quantity}",
                            textAlign: TextAlign.center,
                            key: Key('itemQuantity${index - 1}'))),
                    Expanded(
                        child: Text("${item.price}",
                            key: Key('itemPrice${index - 1}'))),
                    if (!isPhone)
                      Expanded(
                        child: Text(
                            "${(item.price! * item.quantity!).toString()}",
                            textAlign: TextAlign.center),
                        key: Key('subTotal${index - 1}'),
                      ),
                  ]),
                  trailing: IconButton(
                    icon: Icon(Icons.delete_forever),
                    key: Key("delete${index - 1}"),
                    onPressed: () {
                      _cartBloc.add(CartDeleteItem(index - 1));
                    },
                  ));
            }));
  }
}

Future addAnotherItemDialog(
    BuildContext context, dynamic repos, bool sales, CartState state) async {
  final _priceController = TextEditingController();
  final _itemDescriptionController = TextEditingController();
  final _quantityController = TextEditingController();
  ItemType? _selectedItemType;
  return showDialog<FinDocItem>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      var _formKey = GlobalKey<FormState>();
      return AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20))),
        title: Text('Add another Item', textAlign: TextAlign.center),
        content: Container(
            height: 350,
            child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                    key: Key('listView2'),
                    child: Column(children: <Widget>[
                      DropdownButtonFormField<ItemType>(
                        key: Key('itemType'),
                        decoration: InputDecoration(labelText: 'Item Type'),
                        hint: Text('ItemType'),
                        value: _selectedItemType,
                        validator: (value) =>
                            value == null ? 'field required' : null,
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
                      TextFormField(
                          key: Key('itemDescription'),
                          decoration:
                              InputDecoration(labelText: 'Item Description'),
                          controller: _itemDescriptionController,
                          validator: (value) {
                            if (value!.isEmpty) return 'Item description?';
                            return null;
                          }),
                      SizedBox(height: 20),
                      TextFormField(
                        key: Key('price'),
                        decoration: InputDecoration(labelText: 'Price/Amount'),
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value!.isEmpty) return 'Enter Price or Amount?';
                          return null;
                        },
                      ),
                      SizedBox(height: 20),
                      TextFormField(
                        key: Key('quantity'),
                        decoration: InputDecoration(labelText: 'Quantity'),
                        controller: _quantityController,
                        keyboardType: TextInputType.number,
                      ),
                    ])))),
        actions: <Widget>[
          ElevatedButton(
            key: Key('cancel'),
            child: Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          ElevatedButton(
            key: Key('ok'),
            child: Text('Ok'),
            onPressed: () {
              if (_formKey.currentState!.validate())
                Navigator.of(context).pop(FinDocItem(
                  itemTypeId: _selectedItemType!.itemTypeId,
                  price: Decimal.parse(_priceController.text),
                  description: _itemDescriptionController.text,
                  quantity: _quantityController.text.isEmpty
                      ? Decimal.parse('1')
                      : Decimal.parse(_quantityController.text),
                ));
            },
          ),
        ],
      );
    },
  );
}

Future addProductItemDialog(BuildContext context, repos) async {
  final _priceController = TextEditingController();
  final _itemDescriptionController = TextEditingController();
  final _quantityController = TextEditingController();
  final _productSearchBoxController = TextEditingController();
  Product? _selectedProduct;

  return showDialog<FinDocItem>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        var _formKey = GlobalKey<FormState>();
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              key: Key('addProductItemDialog'),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20))),
              title: Text('Add a Product', textAlign: TextAlign.center),
              content: Container(
                  height: 350,
                  child: Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                          key: Key('listView3'),
                          child: Column(children: <Widget>[
                            DropdownSearch<Product>(
                              selectedItem: _selectedProduct,
                              popupProps: PopupProps.menu(
                                showSearchBox: true,
                                searchFieldProps: TextFieldProps(
                                  autofocus: true,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(20)),
                                  ),
                                  controller: _productSearchBoxController,
                                ),
                                menuProps: MenuProps(
                                    borderRadius: BorderRadius.circular(20)),
                                title: Container(
                                    height: 50,
                                    decoration: BoxDecoration(
                                        color:
                                            Theme.of(context).primaryColorDark,
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(20),
                                          topRight: Radius.circular(20),
                                        )),
                                    child: Center(
                                        child: Text('Select product',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            )))),
                              ),
                              dropdownSearchDecoration: InputDecoration(
                                labelText: 'Product',
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20)),
                              ),
                              key: Key('product'),
                              itemAsString: (Product? u) =>
                                  "${u!.pseudoId}\n${u.productName}",
                              asyncItems: (String? filter) async {
                                ApiResult<List<Product>> result =
                                    await repos.getProduct(
                                        filter:
                                            _productSearchBoxController.text,
                                        limit: 3);
                                return result.when(
                                    success: (data) => data,
                                    failure: (_) => [
                                          Product(
                                              productName: 'get data error!')
                                        ]);
                              },
                              onChanged: (Product? newValue) {
                                setState(() {
                                  _selectedProduct = newValue;
                                });
                                if (newValue != null) {
                                  _priceController.text =
                                      newValue.price.toString();
                                  _itemDescriptionController.text =
                                      "${newValue.productName}";
                                }
                              },
                              validator: (value) =>
                                  value == null ? "Select a product?" : null,
                            ),
                            SizedBox(height: 20),
                            TextFormField(
                                key: Key('itemDescription'),
                                decoration: InputDecoration(
                                    labelText: 'Item Description'),
                                controller: _itemDescriptionController,
                                validator: (value) {
                                  if (value!.isEmpty)
                                    return 'Item description?';
                                  return null;
                                }),
                            SizedBox(height: 20),
                            TextFormField(
                              key: Key('itemPrice'),
                              decoration:
                                  InputDecoration(labelText: 'Price/Amount'),
                              controller: _priceController,
                              validator: (value) {
                                if (value!.isEmpty)
                                  return 'Enter Price or Amount?';
                                return null;
                              },
                            ),
                            SizedBox(height: 20),
                            TextFormField(
                              key: Key('itemQuantity'),
                              keyboardType: TextInputType.number,
                              inputFormatters: <TextInputFormatter>[
                                FilteringTextInputFormatter.allow(
                                    RegExp('[0-9.,]+'))
                              ],
                              decoration:
                                  InputDecoration(labelText: 'Quantity'),
                              controller: _quantityController,
                              validator: (value) =>
                                  value == null ? "Enter a quantity?" : null,
                            ),
                          ])))),
              actions: <Widget>[
                ElevatedButton(
                  key: Key('cancelRental'),
                  child: Text('cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  key: Key('ok'),
                  child: Text('ok'),
                  onPressed: () {
                    if (_formKey.currentState!.validate())
                      Navigator.of(context).pop(FinDocItem(
                        itemTypeId: 'ItemProduct',
                        productId: _selectedProduct!.productId,
                        price: Decimal.parse(_priceController.text),
                        description: _itemDescriptionController.text,
                        quantity: _quantityController.text.isEmpty
                            ? Decimal.parse('1')
                            : Decimal.parse(_quantityController.text),
                      ));
                  },
                ),
              ],
            );
          },
        );
      });
}

/// [addRentalItemDialog] add a rental order item [FinDocItem]
Future addRentalItemDialog(BuildContext context, repos) async {
  final _priceController = TextEditingController();
  final _itemDescriptionController = TextEditingController();
  final _quantityController = TextEditingController();
  final _productSearchBoxController = TextEditingController();
  Product? _selectedProduct;
  DateTime _startDate = CustomizableDateTime.current;
  List<String> rentalDays = [];
  String classificationId = GlobalConfiguration().get("classificationId");

  return showDialog<FinDocItem>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        bool whichDayOk(DateTime day) {
          var formatter = new DateFormat('yyyy-MM-dd');
          String date = formatter.format(day);
          if (rentalDays.contains(date)) return false;
          return true;
        }

        var _formKey = GlobalKey<FormState>();
        return AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20))),
          title: Text('Add a Reservation', textAlign: TextAlign.center),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              _selectDate(BuildContext context) async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: CustomizableDateTime.current,
                  lastDate: DateTime(CustomizableDateTime.current.year + 1),
                  selectableDayPredicate: whichDayOk,
                );
                if (picked != null && picked != _startDate)
                  setState(() {
                    _startDate = picked;
                  });
              }

              return Container(
                  height: 450,
                  child: Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                          key: Key('listView4'),
                          child: Column(
                            children: <Widget>[
                              DropdownSearch<Product>(
                                key: Key('product'),
                                selectedItem: _selectedProduct,
                                popupProps: PopupProps.menu(
                                  showSearchBox: true,
                                  searchFieldProps: TextFieldProps(
                                    autofocus: true,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(20)),
                                    ),
                                    controller: _productSearchBoxController,
                                  ),
                                  menuProps: MenuProps(
                                      borderRadius: BorderRadius.circular(20)),
                                ),
                                itemAsString: (Product? u) =>
                                    "${u!.productName}",
                                asyncItems: (String? filter) async {
                                  ApiResult<List<Product>> result =
                                      await repos.getProduct(
                                          filter:
                                              _productSearchBoxController.text,
                                          assetClassId:
                                              classificationId == 'AppHotel'
                                                  ? 'Hotel Room'
                                                  : null,
                                          productTypeId: 'Rental',
                                          limit: 3);
                                  return result.when(
                                      success: (data) => data,
                                      failure: (_) => [
                                            Product(
                                                productName: 'get data error!')
                                          ]);
                                },
                                onChanged: (Product? newValue) async {
                                  _selectedProduct = newValue;
                                  _priceController.text =
                                      newValue!.price.toString();
                                  _itemDescriptionController.text =
                                      "${newValue.productName}";
                                  rentalDays = await getRentalOccupancy(
                                      repos: repos,
                                      productId: newValue.productId);
                                  while (!whichDayOk(_startDate))
                                    _startDate =
                                        _startDate.add(Duration(days: 1));
                                },
                                validator: (value) =>
                                    value == null ? 'Select product?' : null,
                              ),
                              SizedBox(height: 20),
                              TextFormField(
                                key: Key('itemDescription'),
                                decoration: InputDecoration(
                                    labelText: 'Item Description'),
                                controller: _itemDescriptionController,
                                validator: (value) =>
                                    value!.isEmpty ? 'Item description?' : null,
                              ),
                              SizedBox(height: 20),
                              TextFormField(
                                key: Key('price'),
                                decoration:
                                    InputDecoration(labelText: 'Price/Amount'),
                                controller: _priceController,
                                validator: (value) =>
                                    value!.isEmpty ? 'Enter Price?' : null,
                              ),
                              SizedBox(height: 20),
                              Row(
                                children: [
                                  Text(
                                    "${_startDate.toLocal()}".split(' ')[0],
                                    key: Key('date'),
                                  ),
                                  SizedBox(width: 10),
                                  ElevatedButton(
                                    key: Key('setDate'),
                                    child: Text(
                                      'Select date',
                                    ),
                                    onPressed: () => _selectDate(context),
                                  ),
                                ],
                              ),
                              SizedBox(height: 20),
                              TextFormField(
                                key: Key('quantity'),
                                decoration:
                                    InputDecoration(labelText: 'Nbr. of days'),
                                controller: _quantityController,
                              ),
                            ],
                          ))));
            },
          ),
          actions: <Widget>[
            ElevatedButton(
              key: Key('cancelRental'),
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              key: Key('okRental'),
              child: Text('Ok'),
              onPressed: () {
                if (_formKey.currentState!.validate())
                  Navigator.of(context).pop(FinDocItem(
                    itemTypeId: 'ItemRental',
                    productId: _selectedProduct!.productId,
                    price: Decimal.parse(_priceController.text),
                    description: _itemDescriptionController.text,
                    rentalFromDate: _startDate,
                    rentalThruDate: _startDate.add(Duration(
                        days: int.parse(_quantityController.text.isEmpty
                            ? '1'
                            : _quantityController.text))),
                    quantity: Decimal.parse('1'),
                  ));
              },
            ),
          ],
        );
      });
}

Future<List<String>> getRentalOccupancy({repos, String? productId}) async {
  if (productId != null) {
    ApiResult<List<String>> result =
        await repos.getRentalOccupancy(productId: productId);
    return result.when(
        success: (data) => data, failure: (_) => ['get data error!']);
  }
  return [];
}
