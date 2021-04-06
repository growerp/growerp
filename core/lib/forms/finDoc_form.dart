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

import 'package:core/templates/@templates.dart';
import 'package:decimal/decimal.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:models/@models.dart';
import 'package:core/blocs/@blocs.dart';
import 'package:core/helper_functions.dart';
import '@forms.dart';
import '../acctMenuItem_data.dart';

class FinDocForm extends StatelessWidget {
  final FormArguments? formArguments;
  const FinDocForm({Key? key, this.formArguments}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    FinDoc finDoc = formArguments!.object as FinDoc;
    MapItem finDocItem = MapItem(
        form: FinDocPage(formArguments!.message, finDoc),
        label:
            "${finDoc.salesString()} Sales ${finDoc.docType} #${finDoc.id()}",
        icon: Icon(Icons.home));
    if (finDoc.docType == 'invoice' || finDoc.docType == 'payment') {
      if (finDoc.sales!) {
        acctSalesMap[finDoc.docType == 'invoice' ? 0 : 1] = finDocItem;
        BlocProvider.of<SalesCartBloc>(context)..add(LoadCart(finDoc));
        return MainTemplate(
          menu: acctMenuItems,
          mapItems: acctSalesMap,
          menuIndex: MENU_ACCTSALES,
          tabIndex: finDoc.docType == 'invoice' ? 0 : 1,
        );
      } else {
        acctPurchaseMap[finDoc.docType == 'invoice' ? 0 : 1] = finDocItem;
        BlocProvider.of<PurchCartBloc>(context)..add(LoadCart(finDoc));
        return MainTemplate(
          menu: acctMenuItems,
          mapItems: acctPurchaseMap,
          menuIndex: MENU_ACCTPURCHASE,
          tabIndex: finDoc.docType == 'invoice' ? 0 : 1,
        );
      }
/*    } // orders
    else if (finDoc.docType == 'order') {
      if (finDoc.sales!) {
        salesMap[0] = finDocItem;
        BlocProvider.of<SalesCartBloc>(context)..add(LoadCart(finDoc));
        return MainTemplate(
          menu: menuItems,
          mapItems: salesMap,
          menuIndex: MENU_SALES,
          tabIndex: 0,
        );
      } else {
        purchaseMap[0] = finDocItem;
        BlocProvider.of<PurchCartBloc>(context)..add(LoadCart(finDoc));
        return MainTemplate(
          menu: menuItems,
          mapItems: purchaseMap,
          menuIndex: MENU_PURCHASE,
          tabIndex: 0,
        );
      }
    } else if (finDoc.docType == 'transaction') {
      ledgerMap[1] = finDocItem;
      BlocProvider.of<SalesCartBloc>(context)..add(LoadCart(finDoc));
      return MainTemplate(
        menu: menuItems,
        mapItems: ledgerMap,
        menuIndex: MENU_ACCTLEDGER,
        tabIndex: 1,
      );
*/
    } else
      return Container(
          child:
              Center(child: Text("Unrecognized docType: ${finDoc.docType} ")));
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
  final FinDoc finDocIn; // incoming finDoc
  final _formKeyHeader = GlobalKey<FormState>();
  final _formKeyItems = GlobalKey<FormState>();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _itemDescriptionController = TextEditingController();
  final _quantityController = TextEditingController();
  final _userSearchBoxController = TextEditingController();
  final _productSearchBoxController = TextEditingController();
  late CartBloc _cartBloc;
  FinDoc? finDoc;
  List<ItemType> itemTypes = [];
  Product? _selectedProduct;
  User? _selectedUser;
  ItemType? _selectedItemType;
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  _MyFinDocState(this.message, this.finDocIn) {
    HelperFunctions.showTopMessage(scaffoldMessengerKey, message);
  }

  @override
  Widget build(BuildContext context) {
    if (finDoc == null) finDoc = finDocIn.copyWith();
    bool isPhone = ResponsiveWrapper.of(context).isSmallerThan(TABLET);
    if (finDoc!.sales!) {
      _cartBloc = BlocProvider.of<SalesCartBloc>(context) as CartBloc;
    } else {
      _cartBloc = BlocProvider.of<PurchCartBloc>(context) as CartBloc;
    }
    var repos = context.read<Object>();
    if (finDoc!.sales!)
      return BlocBuilder<AuthBloc, AuthState>(builder: (context, state) {
        if (state is AuthAuthenticated)
          itemTypes = state.authenticate!.itemTypes!.sales!;
        return BlocListener<SalesOrderBloc, FinDocState>(
            listener: (context, state) {
              if (state is FinDocProblem)
                HelperFunctions.showMessage(
                    context, '${state.errorMessage}', Colors.red);
              if (state is FinDocSuccess)
                HelperFunctions.showMessage(
                    context, '${state.message}', Colors.green);
            },
            child: BlocConsumer<SalesCartBloc, CartState>(
                listener: (context, state) {
              if (state is CartProblem) {
                HelperFunctions.showMessage(
                    context, '${state.errorMessage}', Colors.red);
              }
              if (state is CartLoaded) {
                HelperFunctions.showMessage(
                    context, '${state.message}', Colors.green);
              }
            }, builder: (context, state) {
              if (state is CartLoading)
                return Center(child: CircularProgressIndicator());
              if (state is CartLoaded) {
                finDoc = state.finDoc;
              }
              return Column(children: [
                SizedBox(height: 20),
                _headerEntry(repos),
                _itemEntry(repos, isPhone),
                _actionButtons(),
                Center(
                    child: Text("Grant total : " +
                        (finDoc!.grandTotal == null
                            ? "0.00"
                            : finDoc!.grandTotal.toString()))),
                _finDocItemList(),
              ]);
            }));
      });
    return BlocBuilder<AuthBloc, AuthState>(builder: (context, state) {
      if (state is AuthAuthenticated)
        itemTypes = state.authenticate!.itemTypes!.purchase!;
      return BlocListener<PurchaseOrderBloc, FinDocState>(
          listener: (context, state) {
            if (state is FinDocProblem)
              HelperFunctions.showMessage(
                  context, '${state.errorMessage}', Colors.red);
            if (state is FinDocSuccess)
              HelperFunctions.showMessage(
                  context, '${state.message}', Colors.green);
          },
          child: BlocConsumer<PurchCartBloc, CartState>(
              listener: (context, state) {
            if (state is CartProblem) {
              HelperFunctions.showMessage(
                  context, '${state.errorMessage}', Colors.red);
            }
            if (state is CartLoaded) {
              setState(() {
                HelperFunctions.showMessage(
                    context, '${state.message}', Colors.green);
              });
            }
          }, builder: (context, state) {
            if (state is CartLoading)
              return Center(child: CircularProgressIndicator());
            if (state is CartLoaded) {
              finDoc = state.finDoc;
            }
            return Column(children: [
              SizedBox(height: 20),
              _headerEntry(repos),
              _itemEntry(repos, isPhone),
              _actionButtons(),
              Center(
                  child:
                      Text("Grant total : ${finDoc!.grandTotal?.toString()}")),
              _finDocItemList(),
            ]);
          }));
    });
  }

  Widget _headerEntry(repos) {
    int columns = ResponsiveWrapper.of(context).isSmallerThan(TABLET) ? 1 : 2;
    double width = columns.toDouble() * 350;
    _selectedUser = finDoc!.otherUser;
    _descriptionController.text = finDoc!.description ?? "";

    Future<List<User>> getData(userGroupId, filter) async {
      var response = await repos.getUser(
          userGroupId: userGroupId, filter: _userSearchBoxController.text);
      return response;
    }

    return Center(
      child: Container(
          height: 150 / columns.toDouble(),
          child: Form(
              key: _formKeyHeader,
              child: Padding(
                  padding: EdgeInsets.all(5),
                  child: GridView.count(
                      crossAxisCount: columns,
                      crossAxisSpacing: 5,
                      mainAxisSpacing: 5,
                      childAspectRatio: (6),
                      children: <Widget>[
                        DropdownSearch<User>(
                          label: finDoc!.sales! ? 'Customer' : 'Supplier',
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
                              ? "Select ${finDoc!.sales! ? 'Customer' : 'Supplier'}!"
                              : null,
                        ),
                        TextFormField(
                          key: Key('description'),
                          decoration:
                              InputDecoration(labelText: 'FinDoc Description'),
                          controller: _descriptionController,
                        ),
                      ])))),
    );
  }

  Widget _itemEntry(repos, isPhone) {
    int columns = ResponsiveWrapper.of(context).isSmallerThan(TABLET) ? 1 : 2;
    double width = columns.toDouble() * 400;

    Future<List<Product>> getProduct(filter) async {
      var response =
          await repos.getProduct(filter: _userSearchBoxController.text);
      return response;
    }

    return Center(
        child: Column(children: [
      Container(
          height: (isPhone ? 200 : 480) / columns.toDouble(),
          width: width,
          child: Form(
              key: _formKeyItems,
              child: Padding(
                  padding: EdgeInsets.all(5),
                  child: GridView.count(
                      crossAxisCount: columns,
                      crossAxisSpacing: 5,
                      mainAxisSpacing: 5,
                      childAspectRatio: (5.5),
                      children: <Widget>[
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
                            setState(() {
                              _selectedItemType = newValue;
                            });
                          },
                          isExpanded: true,
                        ),
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
                            setState(() {
                              _selectedProduct = newValue;
                              _priceController.text =
                                  newValue!.price.toString();
                              _itemDescriptionController.text =
                                  "${newValue.productName}[${newValue.productId}]";
                              _selectedItemType = itemTypes.firstWhere(
                                  (x) => x.itemTypeId == 'ItemProduct');
                            });
                          },
                        ),
                        TextFormField(
                          key: Key('itemDescription'),
                          decoration:
                              InputDecoration(labelText: 'Item Description'),
                          controller: _itemDescriptionController,
                          validator: (value) {
                            if (value!.isEmpty) return 'Item description?';
                            return null;
                          },
                        ),
                        if (!isPhone) SizedBox(),
                        TextFormField(
                          decoration:
                              InputDecoration(labelText: 'Price/Amount'),
                          controller: _priceController,
                          validator: (value) {
                            if (value!.isEmpty) return 'Enter Price or Amount?';
                            return null;
                          },
                        ),
                        TextFormField(
                          key: Key('quantity'),
                          decoration: InputDecoration(labelText: 'Quantity'),
                          controller: _quantityController,
                        ),
                      ])))),
    ]));
  }

  Widget _actionButtons() {
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
                if (finDoc!.items!.length > 0) {
                  _cartBloc.add(ClearCart(finDoc!));
                }
              }),
          ElevatedButton(
              child: Text(finDoc!.idIsNull()
                  ? 'Create '
                  : 'Update ' + '${finDoc!.docType}'),
              onPressed: () {
                if (finDoc!.items!.length > 0) {
                  print("==create findoc: $finDoc");
                  _cartBloc.add(CreateFinDocFromCart(finDoc!));
                }
              }),
          ElevatedButton(
              key: Key('addItem'),
              child: Text('Add Item'),
              onPressed: () {
                if (_formKeyHeader.currentState!.validate() &&
                    _formKeyItems.currentState!.validate()) {
                  print("===findoc TO cart: $finDoc");
                  _cartBloc.add(AddToCart(
                      finDoc: finDoc!.copyWith(
                          otherUser: _selectedUser,
                          description: _descriptionController.text),
                      newItem: FinDocItem(
                          itemTypeId: _selectedItemType!.itemTypeId,
                          productId: _selectedProduct?.productId,
                          description: _itemDescriptionController.text,
                          price: Decimal.parse(_priceController.text),
                          quantity: Decimal.parse(
                              _quantityController.text.isEmpty
                                  ? "1"
                                  : _quantityController.text))));
                  setState(() {
                    _selectedItemType = null;
                    _selectedProduct = null;
                    _priceController.clear();
                    _quantityController.clear();
                    _itemDescriptionController.clear();
                    //                 _selectedItemType = null;
                  });
                }
              }),
        ]);
  }

  Widget _finDocItemList() {
    List<FinDocItem>? items = finDoc?.items;

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
                    Navigator.pushNamed(context, '/finDoc',
                        arguments: FormArguments(
                            message: 'item deleted',
                            menuIndex: 0,
                            object: finDoc));
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
