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
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:models/@models.dart';
import 'package:core/blocs/@blocs.dart';
import 'package:core/helper_functions.dart';

class FinDocDialog extends StatelessWidget {
  final FormArguments formArguments;
  const FinDocDialog({Key? key, required this.formArguments}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FinDocPage(formArguments.message, formArguments.object as FinDoc);
  }
}

class FinDocPage extends StatefulWidget {
  final String? message;
  final FinDoc finDoc;
  FinDocPage(this.message, this.finDoc);
  @override
  _MyFinDocState createState() => _MyFinDocState(message, finDoc);
}

class _MyFinDocState extends State<FinDocPage> {
  final String? message;
  final FinDoc finDoc; // incoming finDoc
  final _formKeyHeader = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _userSearchBoxController = TextEditingController();
  late CartBloc _cartBloc;
  late FinDoc finDocUpdated;
  List<ItemType> itemTypes = [];
  User? _selectedUser;
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  late bool isPhone;
  _MyFinDocState(this.message, this.finDoc) {
    HelperFunctions.showTopMessage(scaffoldMessengerKey, message);
  }

  @override
  void initState() {
    super.initState();
    finDocUpdated = finDoc.copyWith();
  }

  @override
  Widget build(BuildContext context) {
    isPhone = ResponsiveWrapper.of(context).isSmallerThan(TABLET);
    int columns = isPhone ? 1 : 2;
    if (finDocUpdated.sales!) {
      _cartBloc = BlocProvider.of<SalesCartBloc>(context) as CartBloc;
    } else {
      _cartBloc = BlocProvider.of<PurchCartBloc>(context) as CartBloc;
    }
    var repos = context.read<Object>();

    dynamic blocListener = (context, state) {
      if (state is FinDocProblem)
        HelperFunctions.showMessage(
            context, '${state.errorMessage}', Colors.red);
      if (state is FinDocSuccess)
        HelperFunctions.showMessage(context, '${state.message}', Colors.green);
      Navigator.of(context).pop();
    };

    dynamic blocConsumerListener = (context, state) {
      if (state is CartProblem) {
        HelperFunctions.showMessage(
            context, '${state.errorMessage}', Colors.red);
      }
      if (state is CartLoaded) {
        HelperFunctions.showMessage(context, '${state.message}', Colors.green);
      }
    };

    dynamic blocConsumerBuilder = (context, state) {
      if (state is CartLoading)
        return Center(child: CircularProgressIndicator());
      if (state is CartLoaded) {
        finDocUpdated = state.finDoc!;
        print("====loaded findoc: $finDocUpdated");
      }
      return Column(children: [
        SizedBox(height: 20),
        _headerEntry(repos),
        SizedBox(height: 40, child: _updateButtons(itemTypes, repos)),
        _finDocItemList(),
        SizedBox(height: 10),
        Center(
            child: Text("Grant total : " +
                (finDocUpdated.grandTotal == null
                    ? "0.00"
                    : finDocUpdated.grandTotal.toString()))),
        SizedBox(height: 40, child: _generalButtons()),
      ]);
    };

    return GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Builder(
                builder: (context) => GestureDetector(
                    onTap: () {},
                    child: Dialog(
                        insetPadding: EdgeInsets.all(10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Container(
                            width: columns.toDouble() * 400,
                            height: 1 / columns.toDouble() * 1200,
                            child: BlocBuilder<AuthBloc, AuthState>(
                                builder: (context, state) {
                              if (state is AuthAuthenticated)
                                itemTypes =
                                    state.authenticate!.itemTypes!.sales!;
                              if (finDocUpdated.sales!)
                                return BlocListener<SalesOrderBloc,
                                        FinDocState>(
                                    listener: blocListener,
                                    child:
                                        BlocConsumer<SalesCartBloc, CartState>(
                                            listener: blocConsumerListener,
                                            builder: blocConsumerBuilder));
                              // purchase from here
                              return BlocListener<PurchaseOrderBloc,
                                      FinDocState>(
                                  listener: blocListener,
                                  child: BlocConsumer<PurchCartBloc, CartState>(
                                      listener: blocConsumerListener,
                                      builder: blocConsumerBuilder));
                            })))))));
  }

  Widget _headerEntry(repos) {
    int columns = isPhone ? 1 : 2;
    Future<List<User>> getData(userGroupId, filter) async {
      var response = await repos.getUser(
          userGroupId: userGroupId, filter: _userSearchBoxController.text);
      return response;
    }

    return Center(
      child: Container(
          height: 180 / columns.toDouble(),
          child: Form(
              key: _formKeyHeader,
              child: Padding(
                  padding: EdgeInsets.all(10),
                  child: GridView.count(
                      crossAxisCount: columns,
                      crossAxisSpacing: 5,
                      mainAxisSpacing: 5,
                      childAspectRatio: (6),
                      children: <Widget>[
                        DropdownSearch<User>(
                          label: finDocUpdated.sales! ? 'Customer' : 'Supplier',
                          dialogMaxWidth: 300,
                          autoFocusSearchBox: true,
                          selectedItem: _selectedUser,
                          dropdownSearchDecoration: InputDecoration(
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25.0)),
                          ),
                          searchBoxDecoration: InputDecoration(
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25.0)),
                          ),
                          showSearchBox: true,
                          searchBoxController: _userSearchBoxController,
                          isFilteredOnline: true,
                          key: Key('dropUser'),
                          itemAsString: (User? u) => "${u!.companyName}",
                          onFind: (String filter) => getData(
                              "GROWERP_M_CUSTOMER",
                              _userSearchBoxController.text),
                          onChanged: (User? newValue) {
                            setState(() {
                              _selectedUser = newValue;
                            });
                          },
                          validator: (value) => value == null
                              ? "Select ${finDocUpdated.sales! ? 'Customer' : 'Supplier'}!"
                              : null,
                        ),
                        TextFormField(
                          key: Key('description'),
                          decoration: InputDecoration(
                              contentPadding: new EdgeInsets.symmetric(
                                  vertical: 30.0, horizontal: 10.0),
                              labelText: '${finDoc.docType} Description'),
                          controller: _descriptionController,
                        ),
                      ])))),
    );
  }

  Widget _updateButtons(itemTypes, repos) {
    return Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          ElevatedButton(
              child: Text("Update header"),
              onPressed: () {
                print("====update header user: $_selectedUser");
                print("==update header findoc: "
                    "${finDocUpdated.copyWith(otherUser: _selectedUser, description: _descriptionController.text)}");
                _cartBloc.add(ModifyHeaderCart(
                    finDoc: finDocUpdated.copyWith(
                        otherUser: _selectedUser,
                        description: _descriptionController.text)));
              }),
          ElevatedButton(
              key: Key('addItem'),
              child: Text('Add other Item'),
              onPressed: () async {
                final dynamic finDocItem =
                    await _addAnotherItemDialog(context, itemTypes);
                print("========added finDocItem: $finDocItem");
                if (finDocItem != null)
                  _cartBloc.add(AddToCart(
                      finDoc: finDocUpdated.copyWith(
                          otherUser: _selectedUser,
                          description: _descriptionController.text),
                      newItem: finDocItem));
              }),
          ElevatedButton(
              key: Key('addProduct'),
              child: Text('Add Product'),
              onPressed: () async {
                final dynamic finDocItem =
                    await _addProductItemDialog(context, repos);
                print("========added finDocItem: $finDocItem");
                print("========added finDoc: $finDoc");
                if (finDocItem != null)
                  _cartBloc.add(AddToCart(
                      finDoc: finDocUpdated.copyWith(
                          otherUser: _selectedUser,
                          description: _descriptionController.text),
                      newItem: finDocItem));
              }),
        ]);
  }

  Widget _generalButtons() {
    return Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          ElevatedButton(
              key: Key('cancel'),
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              }),
          ElevatedButton(
              key: Key('clear'),
              child: Text('Clear'),
              onPressed: () {
                if (finDocUpdated.items!.length > 0) {
                  _cartBloc.add(ClearCart(finDocUpdated));
                }
                Navigator.of(context).pop();
              }),
          ElevatedButton(
              child: Text((finDocUpdated.idIsNull() ? 'Create ' : 'Update ') +
                  '${finDocUpdated.docType}'),
              onPressed: () {
                if (finDocUpdated.items!.length > 0) {
                  print("==create findoc: $finDocUpdated");
                  _cartBloc.add(CreateFinDocFromCart(finDocUpdated));
                }
              }),
        ]);
  }

  Widget _finDocItemList() {
    List<FinDocItem>? items = finDocUpdated.items;

    return Expanded(
        child: CustomScrollView(
      slivers: <Widget>[
        SliverToBoxAdapter(
            child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.transparent,
          ),
          title: Column(children: [
            Row(children: <Widget>[
              Expanded(child: Text("Item Type", textAlign: TextAlign.center)),
              Expanded(
                  child: Text("Description[id]", textAlign: TextAlign.center)),
              Expanded(child: Text("Quantity", textAlign: TextAlign.center)),
              Expanded(child: Text("Price", textAlign: TextAlign.center)),
              Expanded(child: Text("SubTotal", textAlign: TextAlign.center)),
            ]),
            Divider(color: Colors.black),
          ]),
        )),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              return InkWell(
                  onLongPress: () async {
                    _cartBloc.add(DeleteItemFromCart(index));
                  },
                  child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.green,
                        child: Text(items![index].itemSeqId.toString()),
                      ),
                      title: Row(children: <Widget>[
                        Expanded(
                            child: Text(
                                itemTypes
                                    .firstWhere(
                                        (x) =>
                                            x.itemTypeId ==
                                            items[index].itemTypeId,
                                        orElse: () => ItemType(
                                            itemTypeId: '',
                                            description: 'null or invalid'))
                                    .description!,
                                textAlign: TextAlign.center)),
                        Expanded(
                            child: Text("${items[index].description}",
                                textAlign: TextAlign.center)),
                        Expanded(
                            child: Text("${items[index].quantity}",
                                textAlign: TextAlign.center)),
                        Expanded(
                            child: Text("${items[index].price}",
                                textAlign: TextAlign.center)),
                        Expanded(
                            child: Text(
                                "${(items[index].price! * items[index].quantity!).toString()}",
                                textAlign: TextAlign.center)),
                      ]),
                      trailing: IconButton(
                        icon: Icon(Icons.delete_forever),
                        onPressed: () {
                          _cartBloc.add(DeleteItemFromCart(index));
                        },
                      )));
            },
            childCount: items == null ? 0 : items.length,
          ),
        ),
      ],
    ));
  }
}

_addAnotherItemDialog(BuildContext context, List<ItemType> itemTypes) async {
  final _priceController = TextEditingController();
  final _itemDescriptionController = TextEditingController();
  final _quantityController = TextEditingController();
  //FinDocItem finDocItem = FinDocItem();
  ItemType? _selectedItemType;
  return showDialog<FinDocItem>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(32.0))),
        title: Text('Add another Item', textAlign: TextAlign.center),
        content: Container(
            height: 300,
            child: Column(children: <Widget>[
              DropdownButtonFormField<ItemType>(
                  hint: Text('Item type'),
                  value: _selectedItemType,
                  items: itemTypes.map((item) {
                    return DropdownMenuItem<ItemType>(
                        child: Text(item.description!), value: item);
                  }).toList(),
                  validator: (value) {
                    if (value == null) return 'Select Item Type?';
                    return null;
                  },
                  onChanged: (ItemType? newValue) {
                    _itemDescriptionController.text = newValue!.description!;
                    _selectedItemType = newValue;
                  }),
              SizedBox(height: 20),
              TextFormField(
                  key: Key('itemDescription'),
                  decoration: InputDecoration(labelText: 'Item Description'),
                  controller: _itemDescriptionController,
                  validator: (value) {
                    if (value!.isEmpty) return 'Item description?';
                    return null;
                  }),
              SizedBox(height: 20),
              TextFormField(
                decoration: InputDecoration(labelText: 'Price/Amount'),
                controller: _priceController,
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
              ),
            ])),
        actions: <Widget>[
          ElevatedButton(
            child: Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          ElevatedButton(
            child: Text('Ok'),
            onPressed: () {
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

_addProductItemDialog(BuildContext context, repos) async {
  final _priceController = TextEditingController();
  final _itemDescriptionController = TextEditingController();
  final _quantityController = TextEditingController();
  final _productSearchBoxController = TextEditingController();
  Product? _selectedProduct;

  Future<List<Product>> getProduct(filter) async {
    var response =
        await repos.getProduct(filter: _productSearchBoxController.text);
    return response;
  }

  return showDialog<FinDocItem>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(32.0))),
        title: Text('Add a Product', textAlign: TextAlign.center),
        content: Container(
            height: 300,
            child: Column(children: <Widget>[
              DropdownSearch<Product>(
                label: 'Product',
                dialogMaxWidth: 300,
                autoFocusSearchBox: true,
                selectedItem: _selectedProduct,
                dropdownSearchDecoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25.0)),
                ),
                searchBoxDecoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25.0)),
                ),
                showSearchBox: true,
                searchBoxController: _productSearchBoxController,
                isFilteredOnline: true,
                key: Key('dropProduct'),
                itemAsString: (Product? u) => "${u!.productName}",
                onFind: (String filter) =>
                    getProduct(_productSearchBoxController.text),
                onChanged: (Product? newValue) {
                  _selectedProduct = newValue;
                  _priceController.text = newValue!.price.toString();
                  _itemDescriptionController.text =
                      "${newValue.productName}[${newValue.productId}]";
                },
              ),
              SizedBox(height: 20),
              TextFormField(
                  key: Key('itemDescription'),
                  decoration: InputDecoration(labelText: 'Item Description'),
                  controller: _itemDescriptionController,
                  validator: (value) {
                    if (value!.isEmpty) return 'Item description?';
                    return null;
                  }),
              SizedBox(height: 20),
              TextFormField(
                decoration: InputDecoration(labelText: 'Price/Amount'),
                controller: _priceController,
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
              ),
            ])),
        actions: <Widget>[
          ElevatedButton(
            child: Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          ElevatedButton(
            child: Text('Ok'),
            onPressed: () {
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
}
