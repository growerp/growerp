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

import 'package:core/widgets/loading_indicator.dart';
import 'package:decimal/decimal.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:global_configuration/global_configuration.dart';
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
  late SalesCartBloc _cartBloc;
  late FinDoc finDocUpdated;
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
    _selectedUser = finDocUpdated.otherUser;
    _descriptionController.text = finDocUpdated.description ?? "";
  }

  @override
  Widget build(BuildContext context) {
    isPhone = ResponsiveWrapper.of(context).isSmallerThan(TABLET);
    //  int columns = isPhone ? 1 : 2;
    if (finDocUpdated.sales) {
      _cartBloc = BlocProvider.of<SalesCartBloc>(context) as CartBloc;
    } else {
      _cartBloc = BlocProvider.of<PurchCartBloc>(context) as CartBloc;
    }
    var repos = context.read<Object>();

    dynamic blocListener = (context, state) {
      if (state is FinDocProblem)
        HelperFunctions.showMessage(
            context, '${state.errorMessage}', Colors.red);
      if (state is FinDocSuccess) {
        HelperFunctions.showMessage(context, '${state.message}', Colors.green);
        Navigator.of(context).pop();
      }
    };

    dynamic blocConsumerListener = (context, state) {
      if (state is CartProblem)
        HelperFunctions.showMessage(
            context, '${state.errorMessage}', Colors.red);
      if (state is CartLoaded)
        HelperFunctions.showMessage(context, '${state.message}', Colors.green);
    };

    dynamic blocConsumerBuilder = (context, state) {
      if (state is CartLoading)
        return Center(child: CircularProgressIndicator());
      if (state is CartLoaded) finDocUpdated = state.finDoc!;
      return Column(children: [
        SizedBox(height: isPhone ? 10 : 20),
        Center(
            child: Text('${finDoc.docType} #${finDoc.id()}',
                style: TextStyle(
                    fontSize: isPhone ? 10 : 20,
                    color: Colors.black,
                    fontWeight: FontWeight.bold))),
        SizedBox(height: isPhone ? 10 : 20),
        _headerEntry(repos),
        SizedBox(height: isPhone ? 110 : 40, child: _updateButtons(repos)),
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
                        key: Key(
                            "FinDocDialog${finDoc.sales ? 'Sales' : 'Purchase'}"
                            "${finDoc.docType}"),
                        insetPadding: EdgeInsets.all(10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Container(
                            width: isPhone ? 400 : 800,
                            height: isPhone ? 700 : 900,
                            child: BlocBuilder<AuthBloc, AuthState>(
                                builder: (context, state) {
                              if (finDocUpdated.sales)
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
    Future<List<User>> getData(userGroupId, filter) async {
      var response = await repos.getUser(
          userGroupId: userGroupId, filter: _userSearchBoxController.text);
      return response;
    }

    List<Widget> widgets = [
      Expanded(
          child: Padding(
              padding: EdgeInsets.all(10),
              child: DropdownSearch<User>(
                label: finDocUpdated.sales ? 'Customer' : 'Supplier',
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
                key: Key('customer'),
                itemAsString: (User? u) =>
                    "${u!.companyName},\n${u.firstName} ${u.lastName}",
                onFind: (String filter) => getData(
                    "GROWERP_M_CUSTOMER", _userSearchBoxController.text),
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
                        vertical: 30.0, horizontal: 10.0),
                    labelText: '${finDoc.docType} Description'),
                controller: _descriptionController,
              ))),
    ];

    return Center(
      child: Container(
          height: isPhone ? 200 : 100,
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

  Widget _updateButtons(repos) {
    List<Widget> buttons = [
      ElevatedButton(
          child: Text("Update header"),
          onPressed: () {
            _cartBloc.add(ModifyHeaderCart(
                finDoc: finDocUpdated.copyWith(
                    otherUser: _selectedUser,
                    description: _descriptionController.text)));
          }),
      ElevatedButton(
          key: Key('addItem'),
          child: Text('Add other Item'),
          onPressed: () async {
            final dynamic finDocItem = await _addAnotherItemDialog(
                context, repos, finDocUpdated.sales);
            if (finDocItem != null)
              _cartBloc.add(AddToCart(
                  finDoc: finDocUpdated.copyWith(
                      otherUser: _selectedUser,
                      description: _descriptionController.text),
                  newItem: finDocItem));
          }),
      ElevatedButton(
          key: Key('itemRental'),
          child: Text('Asset Rental'),
          onPressed: () async {
            final dynamic finDocItem =
                await _addRentalItemDialog(context, repos);
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
            if (finDocItem != null)
              _cartBloc.add(AddToCart(
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
              key: Key('update'),
              child: Text((finDocUpdated.idIsNull() ? 'Create ' : 'Update ') +
                  '${finDocUpdated.docType}'),
              onPressed: () {
                finDocUpdated = finDocUpdated.copyWith(
                    otherUser: _selectedUser,
                    description: _descriptionController.text);
                if (finDocUpdated.items!.length > 0 &&
                    finDocUpdated.otherUser != null) {
                  _cartBloc.add(CreateFinDocFromCart(finDocUpdated));
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

  Widget _finDocItemList() {
    List<FinDocItem> items = finDocUpdated.items ?? [];
    return Expanded(
        child: CustomScrollView(
      slivers: <Widget>[
        SliverToBoxAdapter(
            child: ListTile(
          leading: !isPhone
              ? CircleAvatar(
                  backgroundColor: Colors.transparent,
                )
              : null,
          title: Column(children: [
            Row(children: <Widget>[
              if (!isPhone)
                Expanded(child: Text("Item Type", textAlign: TextAlign.center)),
              Expanded(child: Text("Descr.", textAlign: TextAlign.center)),
              Expanded(child: Text("    Qty", textAlign: TextAlign.center)),
              Expanded(child: Text("Price", textAlign: TextAlign.center)),
              if (!isPhone)
                Expanded(child: Text("SubTotal", textAlign: TextAlign.center)),
              Expanded(child: Text(" ", textAlign: TextAlign.center)),
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
                      leading: !isPhone
                          ? CircleAvatar(
                              backgroundColor: Colors.green,
                              child: Text(items[index].itemSeqId.toString()),
                            )
                          : null,
                      title: Row(children: <Widget>[
                        if (!isPhone)
                          Expanded(
                              child: Text("${items[index].itemTypeName}",
                                  textAlign: TextAlign.left,
                                  key: Key('itemType$index'))),
                        Expanded(
                            child: Text("${items[index].description}",
                                key: Key('itemDescription$index'),
                                textAlign: TextAlign.left)),
                        Expanded(
                            child: Text("${items[index].quantity}",
                                textAlign: TextAlign.center,
                                key: Key('itemQuantity$index'))),
                        Expanded(
                            child: Text("${items[index].price}",
                                key: Key('itemPrice$index'))),
                        if (!isPhone)
                          Expanded(
                            child: Text(
                                "${(items[index].price! * items[index].quantity!).toString()}",
                                textAlign: TextAlign.center),
                            key: Key('subTotal$index'),
                          ),
                      ]),
                      trailing: IconButton(
                        icon: Icon(Icons.delete_forever),
                        onPressed: () {
                          _cartBloc.add(DeleteItemFromCart(index));
                        },
                      )));
            },
            childCount: items.length,
          ),
        ),
      ],
    ));
  }
}

Future _addAnotherItemDialog(
    BuildContext context, dynamic repos, bool sales) async {
  final _priceController = TextEditingController();
  final _itemDescriptionController = TextEditingController();
  final _quantityController = TextEditingController();
  ItemType? _selectedItemType;
  List<ItemType> itemTypes = [];
  var result = await repos.getItemTypes(sales: sales);
  if (result is List<ItemType>) itemTypes = result;
  if (itemTypes.isEmpty) LoadingIndicator();
  return showDialog<FinDocItem>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      var _formKey = GlobalKey<FormState>();
      return AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(32.0))),
        title: Text('Add another Item', textAlign: TextAlign.center),
        content: Container(
            height: 350,
            child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                    key: Key('listView'),
                    child: Column(children: <Widget>[
                      DropdownButtonFormField<ItemType>(
                        key: Key('itemType'),
                        hint: Text('ItemType'),
                        value: _selectedItemType,
                        validator: (value) =>
                            value == null ? 'field required' : null,
                        items: itemTypes.map((item) {
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

Future _addProductItemDialog(BuildContext context, repos) async {
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
      var _formKey = GlobalKey<FormState>();
      return AlertDialog(
        key: Key('addProductItemDialog'),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(32.0))),
        title: Text('Add a Product', textAlign: TextAlign.center),
        content: Container(
            height: 350,
            child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                    key: Key('listView'),
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
                        key: Key('product'),
                        itemAsString: (Product? u) => "${u!.productName}",
                        onFind: (String filter) =>
                            getProduct(_productSearchBoxController.text),
                        onChanged: (Product? newValue) {
                          _selectedProduct = newValue;
                          if (newValue != null) {
                            _priceController.text = newValue.price.toString();
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
                          decoration:
                              InputDecoration(labelText: 'Item Description'),
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
                        keyboardType: TextInputType.number,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.allow(RegExp('[0-9.,]+'))
                        ],
                        decoration: InputDecoration(labelText: 'Quantity'),
                        controller: _quantityController,
                        validator: (value) =>
                            value == null ? "Enter a quantity?" : null,
                      ),
                    ])))),
        actions: <Widget>[
          ElevatedButton(
            key: Key('cancel'),
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
}

_addRentalItemDialog(BuildContext context, repos) async {
  final _priceController = TextEditingController();
  final _itemDescriptionController = TextEditingController();
  final _quantityController = TextEditingController();
  final _productSearchBoxController = TextEditingController();
  Product? _selectedProduct;
  String classificationId = GlobalConfiguration().get("classificationId");

  Future<List<Product>> getProduct(filter) async {
    var response = await repos.getProduct(
        filter: _productSearchBoxController.text,
        assetClassId: classificationId == 'AppHotel' ? 'Hotel Room' : null,
        productTypeId: classificationId == 'AppHotel' ? 'Rental' : null);
    return response;
  }

  return showDialog<FinDocItem>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      var _formKey = GlobalKey<FormState>();
      return AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(32.0))),
        title: Text('Add a Reservation', textAlign: TextAlign.center),
        content: Container(
            height: 450,
            child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                    key: Key('listView'),
                    child: Column(children: <Widget>[
                      DropdownSearch<Product>(
                        key: Key('product'),
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
                        itemAsString: (Product? u) => "${u!.productName}",
                        onFind: (String filter) =>
                            getProduct(_productSearchBoxController.text),
                        onChanged: (Product? newValue) {
                          _selectedProduct = newValue;
                          _priceController.text = newValue!.price.toString();
                          _itemDescriptionController.text =
                              "${newValue.productName}";
                        },
                      ),
                      SizedBox(height: 20),
                      TextFormField(
                        key: Key('itemDescription'),
                        decoration:
                            InputDecoration(labelText: 'Item Description'),
                        controller: _itemDescriptionController,
                        validator: (value) =>
                            value!.isEmpty ? 'Item description?' : null,
                      ),
                      SizedBox(height: 20),
                      TextFormField(
                        key: Key('price'),
                        decoration: InputDecoration(labelText: 'Price/Amount'),
                        controller: _priceController,
                        validator: (value) =>
                            value!.isEmpty ? 'Enter Price?' : null,
                      ),
                      SizedBox(height: 20),
                      InputDatePickerFormField(
                        key: Key('date'),
                        fieldLabelText: 'Start date',
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(DateTime.now().year + 1),
                      ),
                      SizedBox(height: 20),
                      TextFormField(
                        key: Key('quantity'),
                        decoration: InputDecoration(labelText: 'Quantity'),
                        controller: _quantityController,
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
                  itemTypeId: 'ItemRental',
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
