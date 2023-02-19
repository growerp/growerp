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
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:intl/intl.dart';
import 'package:growerp_core/growerp_core.dart';

import '../../api_repository.dart';
import '../blocs/blocs.dart';

class FinDocDialog extends StatelessWidget {
  final FinDoc finDoc;
  const FinDocDialog({required this.finDoc, super.key});

  @override
  Widget build(BuildContext context) {
    FinDocBloc finDocBloc = context.read<FinDocBloc>();
    if (finDoc.sales) {
      return BlocProvider<SalesCartBloc>(
          create: (context) => CartBloc(
              docType: finDoc.docType!,
              sales: true,
              finDocBloc: finDocBloc,
              repos: context.read<FinDocAPIRepository>())
            ..add(CartFetch(finDoc)),
          child: FinDocPage(finDoc));
    }
    return BlocProvider<PurchaseCartBloc>(
        create: (context) => CartBloc(
            docType: finDoc.docType!,
            sales: false,
            finDocBloc: finDocBloc,
            repos: context.read<FinDocAPIRepository>())
          ..add(CartFetch(finDoc)),
        child: FinDocPage(finDoc));
  }
}

class FinDocPage extends StatefulWidget {
  final FinDoc finDoc;
  const FinDocPage(this.finDoc, {super.key});
  @override
  MyFinDocState createState() => MyFinDocState();
}

class MyFinDocState extends State<FinDocPage> {
  final _formKeyHeader = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _userSearchBoxController = TextEditingController();
  late CartBloc _cartBloc;
  late FinDocAPIRepository repos;
  late FinDoc finDocUpdated;
  late FinDoc finDoc; // incoming finDoc
  User? _selectedUser;
  late bool isPhone;

  @override
  void initState() {
    super.initState();
    finDoc = widget.finDoc;
    finDocUpdated = finDoc;
    _selectedUser = finDocUpdated.otherUser;
    _descriptionController.text = finDocUpdated.description ?? "";
    if (finDoc.sales) {
      _cartBloc = context.read<SalesCartBloc>() as CartBloc;
    } else {
      _cartBloc = context.read<PurchaseCartBloc>() as CartBloc;
    }
    repos = context.read<FinDocAPIRepository>();
  }

  @override
  Widget build(BuildContext context) {
    isPhone = ResponsiveWrapper.of(context).isSmallerThan(TABLET);

    blocConsumerListener(BuildContext context, CartState state,
        [bool mounted = true]) async {
      switch (state.status) {
        case CartStatus.complete:
          HelperFunctions.showMessage(
              context,
              '${finDoc.idIsNull() ? "Add" : "Update"} successfull',
              Colors.green);
          await Future.delayed(const Duration(milliseconds: 500));
          if (!mounted) return const Text('not mounted!');
          Navigator.of(context).pop();
          break;
        case CartStatus.failure:
          HelperFunctions.showMessage(context, '${state.message}', Colors.red);
          break;
        default:
          return const Center(child: CircularProgressIndicator());
      }
    }

    blocConsumerBuilder(BuildContext context, CartState state) {
      switch (state.status) {
        case CartStatus.inProcess:
          finDocUpdated = state.finDoc;
          return Column(children: [
            Center(
                child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                        color: Theme.of(context).primaryColorDark,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        )),
                    child: Center(
                        child: Text(
                            '${finDoc.docType} #${finDoc.id() ?? ' new'}',
                            key: const Key('header'),
                            style: const TextStyle(
                                fontSize: 20,
                                color: Colors.white,
                                fontWeight: FontWeight.bold))))),
            SizedBox(height: isPhone ? 10 : 20),
            headerEntry(repos),
            SizedBox(
                height: isPhone ? 110 : 40, child: updateButtons(repos, state)),
            finDocItemList(state),
            const SizedBox(height: 10),
            Center(
                child: Text(
                    "Items# ${finDocUpdated.items.length}   Grand total : ${finDocUpdated.grandTotal == null ? "0.00" : finDocUpdated.grandTotal.toString()}",
                    key: const Key('grandTotal'))),
            Padding(
                padding: const EdgeInsets.all(10),
                child: SizedBox(height: 40, child: generalButtons())),
          ]);
        default:
          return const LoadingIndicator();
      }
    }

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
                    insetPadding: const EdgeInsets.all(10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: SingleChildScrollView(
                        key: const Key('listView1'),
                        child: Stack(clipBehavior: Clip.none, children: [
                          SizedBox(
                              width: isPhone ? 400 : 800,
                              height: isPhone
                                  ? 600
                                  : 600, // not increase height otherwise tests will fail
                              child: Builder(builder: (BuildContext context) {
                                if (finDoc.sales) {
                                  return BlocConsumer<SalesCartBloc, CartState>(
                                      listener: blocConsumerListener,
                                      builder: blocConsumerBuilder);
                                }
                                // purchase from here
                                return BlocConsumer<PurchaseCartBloc,
                                        CartState>(
                                    listener: blocConsumerListener,
                                    builder: blocConsumerBuilder);
                              })),
                          const Positioned(
                              top: 10, right: 10, child: DialogCloseButton())
                        ]))))));
  }

  Widget headerEntry(repos) {
    List<Widget> widgets = [
      Expanded(
          child: Padding(
              padding: const EdgeInsets.all(10),
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
                  title: popUp(
                    context: context,
                    title:
                        "Select ${finDocUpdated.sales ? 'Customer' : 'Supplier'}",
                    height: 50,
                  ),
                ),
                dropdownSearchDecoration: InputDecoration(
                  labelText: finDocUpdated.sales ? 'Customer' : 'Supplier',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25.0)),
                ),
                key: Key(finDocUpdated.sales == true ? 'customer' : 'supplier'),
                itemAsString: (User? u) =>
                    "${u!.company!.name},\n${u.firstName ?? ''} ${u.lastName ?? ''}",
                asyncItems: (String? filter) async {
                  final finDocBloc = context.read<FinDocBloc>();
                  finDocBloc.add(FinDocGetUsers(
                      role: finDocUpdated.sales == true
                          ? Role.customer
                          : Role.supplier,
                      filter: _userSearchBoxController.text));
                  int times = 0;
                  while (finDocBloc.state.users.isEmpty && times++ < 10) {
                    await Future.delayed(const Duration(milliseconds: 500));
                  }
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
              padding: const EdgeInsets.all(10),
              child: TextFormField(
                key: const Key('description'),
                decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 35.0, horizontal: 10.0),
                    labelText: '${finDoc.docType} Description'),
                controller: _descriptionController,
              ))),
    ];

    return Center(
      child: SizedBox(
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
          child: const Text("Update header"),
          onPressed: () {
            _cartBloc.add(CartHeader(finDocUpdated.copyWith(
                otherUser: _selectedUser,
                description: _descriptionController.text)));
          }),
      ElevatedButton(
          key: const Key('addItem'),
          child: const Text('Add other Item'),
          onPressed: () async {
            final dynamic finDocItem = await addAnotherItemDialog(
                context, repos, finDocUpdated.sales, state);
            if (finDocItem != null) {
              _cartBloc.add(CartAdd(
                  finDoc: finDocUpdated.copyWith(
                      otherUser: _selectedUser,
                      description: _descriptionController.text),
                  newItem: finDocItem));
            }
          }),
      Visibility(
          visible: finDoc.docType == FinDocType.order,
          child: ElevatedButton(
              key: const Key('itemRental'),
              child: const Text('Asset Rental'),
              onPressed: () async {
                final dynamic finDocItem =
                    await addRentalItemDialog(context, repos);
                if (finDocItem != null) {
                  _cartBloc.add(CartAdd(
                      finDoc: finDocUpdated.copyWith(
                          otherUser: _selectedUser,
                          description: _descriptionController.text),
                      newItem: finDocItem));
                }
              })),
      ElevatedButton(
          key: const Key('addProduct'),
          child: const Text('Add Product'),
          onPressed: () async {
            final dynamic finDocItem =
                await addProductItemDialog(context, repos);
            if (finDocItem != null) {
              _cartBloc.add(CartAdd(
                  finDoc: finDocUpdated.copyWith(
                      otherUser: _selectedUser,
                      description: _descriptionController.text),
                  newItem: finDocItem));
            }
          }),
    ];

    if (isPhone) {
      List<Widget> rows = [];
      for (var i = 0; i < buttons.length; i++) {
        rows.add(Row(children: [
          Expanded(
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 5, 5),
                  child: buttons[i])),
          Expanded(
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(5, 0, 10, 5),
                  child: buttons[++i]))
        ]));
      }
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
                  key: const Key('cancelFinDoc'),
                  child: Text('Cancel ${finDocUpdated.docType}'),
                  onPressed: () {
                    _cartBloc.add(CartCancelFinDoc(finDocUpdated));
                  })),
          ElevatedButton(
              key: const Key('clear'),
              child: const Text('Clear Cart'),
              onPressed: () {
                if (finDocUpdated.items.isNotEmpty) {
                  _cartBloc.add(CartClear());
                }
              }),
          ElevatedButton(
              key: const Key('update'),
              child: Text(
                  '${finDoc.idIsNull() ? 'Create ' : 'Update '}${finDocUpdated.docType}'),
              onPressed: () {
                finDocUpdated = finDocUpdated.copyWith(
                    otherUser: _selectedUser,
                    description: _descriptionController.text);
                if (finDocUpdated.items.isNotEmpty &&
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
                      ? const CircleAvatar(
                          backgroundColor: Colors.transparent,
                        )
                      : null,
                  title: Column(children: [
                    Row(children: <Widget>[
                      if (!isPhone)
                        const Expanded(
                            child:
                                Text("Item Type", textAlign: TextAlign.center)),
                      const Expanded(
                          child: Text("Descr.", textAlign: TextAlign.center)),
                      const Expanded(
                          child: Text("    Qty", textAlign: TextAlign.center)),
                      const Expanded(
                          child: Text("Price", textAlign: TextAlign.center)),
                      if (!isPhone)
                        const Expanded(
                            child:
                                Text("SubTotal", textAlign: TextAlign.center)),
                      const Expanded(
                          child: Text(" ", textAlign: TextAlign.center)),
                    ]),
                    const Divider(color: Colors.black),
                  ]),
                );
              }
              if (index == 1 && items.isEmpty) {
                return const Center(
                    heightFactor: 20,
                    child: Text("no items found!",
                        key: Key('empty'), textAlign: TextAlign.center));
              }
              final item = items[index - 1];
              var itemType = state.itemTypes
                  .firstWhere((e) => e.itemTypeId == item.itemTypeId);
              return ListTile(
                  key: const Key('productItem'),
                  leading: !isPhone
                      ? CircleAvatar(
                          backgroundColor: Colors.green,
                          child: Text(item.itemSeqId.toString()),
                        )
                      : null,
                  title: Row(children: <Widget>[
                    if (!isPhone)
                      Expanded(
                          child: Text(itemType.itemTypeName,
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
                        key: Key('subTotal${index - 1}'),
                        child: Text((item.price! * item.quantity!).toString(),
                            textAlign: TextAlign.center),
                      ),
                  ]),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_forever),
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
  final priceController = TextEditingController();
  final itemDescriptionController = TextEditingController();
  final quantityController = TextEditingController();
  ItemType? selectedItemType;
  return showDialog<FinDocItem>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      var addOtherFormKey = GlobalKey<FormState>();
      return Dialog(
          key: const Key('addOtherItemDialog'),
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20))),
          child: popUp(
            context: context,
            height: 520,
            title: 'Add another Item',
            child: SizedBox(
                child: Form(
                    key: addOtherFormKey,
                    child: SingleChildScrollView(
                        key: const Key('listView2'),
                        child: Column(children: <Widget>[
                          DropdownButtonFormField<ItemType>(
                            key: const Key('itemType'),
                            decoration:
                                const InputDecoration(labelText: 'Item Type'),
                            hint: const Text('ItemType'),
                            value: selectedItemType,
                            validator: (value) =>
                                value == null ? 'field required' : null,
                            items: state.itemTypes.map((item) {
                              return DropdownMenuItem<ItemType>(
                                  value: item, child: Text(item.itemTypeName));
                            }).toList(),
                            onChanged: (ItemType? newValue) {
                              selectedItemType = newValue;
                            },
                            isExpanded: true,
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                              key: const Key('itemDescription'),
                              decoration: const InputDecoration(
                                  labelText: 'Item Description'),
                              controller: itemDescriptionController,
                              validator: (value) {
                                if (value!.isEmpty) return 'Item description?';
                                return null;
                              }),
                          const SizedBox(height: 20),
                          TextFormField(
                            key: const Key('price'),
                            decoration: const InputDecoration(
                                labelText: 'Price/Amount'),
                            controller: priceController,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value!.isEmpty) {
                                return 'Enter Price or Amount?';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            key: const Key('quantity'),
                            decoration:
                                const InputDecoration(labelText: 'Quantity'),
                            controller: quantityController,
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            key: const Key('ok'),
                            child: const Text('Ok'),
                            onPressed: () {
                              if (addOtherFormKey.currentState!.validate()) {
                                Navigator.of(context).pop(FinDocItem(
                                  itemTypeId: selectedItemType!.itemTypeId,
                                  price: Decimal.parse(priceController.text),
                                  description: itemDescriptionController.text,
                                  quantity: quantityController.text.isEmpty
                                      ? Decimal.parse('1')
                                      : Decimal.parse(quantityController.text),
                                ));
                              }
                            },
                          ),
                        ])))),
          ));
    },
  );
}

Future addProductItemDialog(BuildContext context, repos) async {
  final priceController = TextEditingController();
  final itemDescriptionController = TextEditingController();
  final quantityController = TextEditingController();
  final productSearchBoxController = TextEditingController();
  Product? selectedProduct;

  return showDialog<FinDocItem>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        var addProductFormKey = GlobalKey<FormState>();
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
                key: const Key('addProductItemDialog'),
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(20))),
                child: popUp(
                    context: context,
                    height: 520,
                    title: 'Add a Product',
                    child: Form(
                        key: addProductFormKey,
                        child: SingleChildScrollView(
                            key: const Key('listView3'),
                            child: Column(children: <Widget>[
                              DropdownSearch<Product>(
                                selectedItem: selectedProduct,
                                popupProps: PopupProps.menu(
                                  showSearchBox: true,
                                  searchFieldProps: TextFieldProps(
                                    autofocus: true,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(20)),
                                    ),
                                    controller: productSearchBoxController,
                                  ),
                                  menuProps: MenuProps(
                                      borderRadius: BorderRadius.circular(20)),
                                  title: popUp(
                                    context: context,
                                    title: 'Select product',
                                    height: 50,
                                  ),
                                ),
                                dropdownSearchDecoration: InputDecoration(
                                  labelText: 'Product',
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20)),
                                ),
                                key: const Key('product'),
                                itemAsString: (Product? u) =>
                                    "${u!.pseudoId}\n${u.productName}",
                                asyncItems: (String? filter) async {
                                  ApiResult<List<Product>> result =
                                      await repos.lookUpProduct(
                                          searchString:
                                              productSearchBoxController.text);
                                  return result.when(
                                      success: (data) => data,
                                      failure: (_) => [
                                            Product(
                                                productName: 'get data error!')
                                          ]);
                                },
                                onChanged: (Product? newValue) {
                                  setState(() {
                                    selectedProduct = newValue;
                                  });
                                  if (newValue != null) {
                                    priceController.text =
                                        newValue.price.toString();
                                    itemDescriptionController.text =
                                        "${newValue.productName}";
                                  }
                                },
                                validator: (value) =>
                                    value == null ? "Select a product?" : null,
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                  key: const Key('itemDescription'),
                                  decoration: const InputDecoration(
                                      labelText: 'Item Description'),
                                  controller: itemDescriptionController,
                                  validator: (value) {
                                    if (value!.isEmpty) {
                                      return 'Item description?';
                                    }
                                    return null;
                                  }),
                              const SizedBox(height: 20),
                              TextFormField(
                                key: const Key('itemPrice'),
                                decoration: const InputDecoration(
                                    labelText: 'Price/Amount'),
                                controller: priceController,
                                validator: (value) {
                                  if (value!.isEmpty) {
                                    return 'Enter Price or Amount?';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                key: const Key('itemQuantity'),
                                keyboardType: TextInputType.number,
                                inputFormatters: <TextInputFormatter>[
                                  FilteringTextInputFormatter.allow(
                                      RegExp('[0-9.,]+'))
                                ],
                                decoration: const InputDecoration(
                                    labelText: 'Quantity'),
                                controller: quantityController,
                                validator: (value) =>
                                    value == null ? "Enter a quantity?" : null,
                              ),
                              const SizedBox(height: 20),
                              Row(children: [
                                Expanded(
                                  child: ElevatedButton(
                                    key: const Key('ok'),
                                    child: const Text('Add product'),
                                    onPressed: () {
                                      if (addProductFormKey.currentState!
                                          .validate()) {
                                        Navigator.of(context).pop(FinDocItem(
                                          itemTypeId: 'ItemProduct',
                                          productId: selectedProduct!.productId,
                                          price: Decimal.parse(
                                              priceController.text),
                                          description:
                                              itemDescriptionController.text,
                                          quantity:
                                              quantityController.text.isEmpty
                                                  ? Decimal.parse('1')
                                                  : Decimal.parse(
                                                      quantityController.text),
                                        ));
                                      }
                                    },
                                  ),
                                )
                              ])
                            ])))));
          },
        );
      });
}

/// [addRentalItemDialog] add a rental order item [FinDocItem]
Future addRentalItemDialog(BuildContext context, repos) async {
  final priceController = TextEditingController();
  final itemDescriptionController = TextEditingController();
  final quantityController = TextEditingController();
  final productSearchBoxController = TextEditingController();
  Product? selectedProduct;
  DateTime startDate = CustomizableDateTime.current;
  List<String> rentalDays = [];
  String classificationId = GlobalConfiguration().get("classificationId");

  return showDialog<FinDocItem>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        bool whichDayOk(DateTime day) {
          var formatter = DateFormat('yyyy-MM-dd');
          String date = formatter.format(day);
          if (rentalDays.contains(date)) return false;
          return true;
        }

        var addRentalFormKey = GlobalKey<FormState>();
        return Dialog(
            key: const Key('addRentalItemDialog'),
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(20))),
            child: popUp(
              context: context,
              height: 520,
              title: 'Add a Reservation',
              child: StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
                  selectDate(BuildContext context) async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: startDate,
                      firstDate: CustomizableDateTime.current,
                      lastDate: DateTime(CustomizableDateTime.current.year + 1),
                      selectableDayPredicate: whichDayOk,
                    );
                    if (picked != null && picked != startDate) {
                      setState(() {
                        startDate = picked;
                      });
                    }
                  }

                  return Form(
                      key: addRentalFormKey,
                      child: SingleChildScrollView(
                          key: const Key('listView4'),
                          child: Column(
                            children: <Widget>[
                              DropdownSearch<Product>(
                                key: const Key('product'),
                                selectedItem: selectedProduct,
                                popupProps: PopupProps.menu(
                                  showSearchBox: true,
                                  searchFieldProps: TextFieldProps(
                                    autofocus: true,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(20)),
                                    ),
                                    controller: productSearchBoxController,
                                  ),
                                  menuProps: MenuProps(
                                      borderRadius: BorderRadius.circular(20)),
                                  title: popUp(
                                    context: context,
                                    title: 'Select product',
                                    height: 50,
                                  ),
                                ),
                                dropdownSearchDecoration: InputDecoration(
                                  labelText: 'Product',
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20)),
                                ),
                                itemAsString: (Product? u) =>
                                    "${u!.productName}",
                                asyncItems: (String? filter) async {
                                  ApiResult<List<Product>> result =
                                      await repos.lookUpProduct(
                                          searchString:
                                              productSearchBoxController.text,
                                          assetClassId:
                                              classificationId == 'AppHotel'
                                                  ? 'Hotel Room'
                                                  : null,
                                          productTypeId: 'Rental');
                                  return result.when(
                                      success: (data) => data,
                                      failure: (_) => [
                                            Product(
                                                productName: 'get data error!')
                                          ]);
                                },
                                onChanged: (Product? newValue) async {
                                  selectedProduct = newValue;
                                  priceController.text =
                                      newValue!.price.toString();
                                  itemDescriptionController.text =
                                      "${newValue.productName}";
                                  rentalDays = await getRentalOccupancy(
                                      repos: repos,
                                      productId: newValue.productId);
                                  while (!whichDayOk(startDate)) {
                                    startDate =
                                        startDate.add(const Duration(days: 1));
                                  }
                                },
                                validator: (value) =>
                                    value == null ? 'Select product?' : null,
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                key: const Key('itemDescription'),
                                decoration: const InputDecoration(
                                    labelText: 'Item Description'),
                                controller: itemDescriptionController,
                                validator: (value) =>
                                    value!.isEmpty ? 'Item description?' : null,
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                key: const Key('price'),
                                decoration: const InputDecoration(
                                    labelText: 'Price/Amount'),
                                controller: priceController,
                                validator: (value) =>
                                    value!.isEmpty ? 'Enter Price?' : null,
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      "${startDate.toLocal()}".split(' ')[0],
                                      key: const Key('date'),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  ElevatedButton(
                                    key: const Key('setDate'),
                                    child: const Text(
                                      'Select date',
                                    ),
                                    onPressed: () => selectDate(context),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                key: const Key('quantity'),
                                decoration: const InputDecoration(
                                    labelText: 'Nbr. of days'),
                                controller: quantityController,
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      key: const Key('okRental'),
                                      child: const Text('Add reservation'),
                                      onPressed: () {
                                        if (addRentalFormKey.currentState!
                                            .validate()) {
                                          Navigator.of(context).pop(FinDocItem(
                                            itemTypeId: 'ItemRental',
                                            productId:
                                                selectedProduct!.productId,
                                            price: Decimal.parse(
                                                priceController.text),
                                            description:
                                                itemDescriptionController.text,
                                            rentalFromDate: startDate,
                                            rentalThruDate: startDate.add(
                                                Duration(
                                                    days: int.parse(
                                                        quantityController
                                                                .text.isEmpty
                                                            ? '1'
                                                            : quantityController
                                                                .text))),
                                            quantity: Decimal.parse('1'),
                                          ));
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          )));
                },
              ),
            ));
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
