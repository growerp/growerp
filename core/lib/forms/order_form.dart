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
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:models/models.dart';
import '../blocs/@blocs.dart';
import '../helper_functions.dart';
import '../routing_constants.dart';
import '../widgets/@widgets.dart';

class OrderForm extends StatelessWidget {
  final FormArguments formArguments;
  OrderForm(this.formArguments);

  @override
  Widget build(BuildContext context) {
    var a = (formArguments) => (MyOrderPage(formArguments.message));
    return BlocProvider(
        create: (context) => CartBloc(
            BlocProvider.of<AuthBloc>(context),
            BlocProvider.of<OrderBloc>(context),
            BlocProvider.of<CatalogBloc>(context),
            BlocProvider.of<CrmBloc>(context))
          ..add(LoadCart(formArguments.object)),
        child: ShowNavigationRail(a(formArguments), 5));
  }
}

class MyOrderPage extends StatefulWidget {
  final String message;
  MyOrderPage(this.message);
  @override
  _MyOrderState createState() => _MyOrderState(message);
}

class _MyOrderState extends State<MyOrderPage> {
  final String message;
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  bool loading = false;
  Order updatedOrder;
  Authenticate authenticate;
  List<Product> products;
  List<User> customers;
  Product _selectedProduct;
  User _selectedCustomer;
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  _MyOrderState(this.message) {
    HelperFunctions.showTopMessage(scaffoldMessengerKey, message);
  }
  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
        key: scaffoldMessengerKey,
        child: Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading:
                  ResponsiveWrapper.of(context).isSmallerThan(TABLET),
              title: companyLogo(context, authenticate, 'Order detail'),
              actions: <Widget>[
                IconButton(
                    icon: Icon(Icons.home),
                    onPressed: () => Navigator.pushNamed(context, HomeRoute))
              ],
            ),
            drawer: myDrawer(context, authenticate),
            body: BlocListener<AuthBloc, AuthState>(
                listener: (context, state) {
                  if (state is AuthProblem)
                    HelperFunctions.showMessage(
                        context, '${state.errorMessage}', Colors.red);
                },
                child: BlocConsumer<CartBloc, CartState>(
                    listener: (context, state) {
                  if (state is CartProblem) {
                    loading = false;
                    HelperFunctions.showMessage(
                        context, '${state.errorMessage}', Colors.green);
                  } else if (state is CartLoading) {
                    loading = true;
                    HelperFunctions.showMessage(
                        context, '${state.message}', Colors.green);
                    return Center(child: CircularProgressIndicator());
                  } else if (state is CartLoaded) {
                    loading = true;
                    HelperFunctions.showMessage(
                        context, '${state.message}', Colors.green);
                    setState(() {
                      _selectedProduct = null;
                      _priceController.clear();
                      _quantityController.clear();
                    });
                  }
                }, builder: (context, state) {
                  if (state is CartLoading)
                    return Center(child: CircularProgressIndicator());
                  if (state is CartLoaded) {
                    authenticate = state.authenticate;
                    customers = state.customers;
                    products = state.products;
                    updatedOrder = state.order;
                  }
                  return _orderItemList();
                }))));
  }

  Widget _orderItemList() {
    List<OrderItem> items = updatedOrder?.orderItems;
    _selectedCustomer ??= updatedOrder?.customerPartyId != null &&
            customers.length > 0
        ? customers.firstWhere((x) => updatedOrder.customerPartyId == x.partyId)
        : null;
    loading = false;
    return Center(
        child: Column(children: [
      Container(
          height: 400,
          width: 400,
          child: Form(
              key: _formKey,
              child: ListView(children: <Widget>[
                SizedBox(height: 30),
                Row(
                  children: [
                    Container(
                        width: 300,
                        child: DropdownButtonFormField<User>(
                          key: Key('dropDownCust'),
                          hint: Text('Customer'),
                          value: _selectedCustomer,
                          validator: (value) =>
                              value == null ? 'field required' : null,
                          items: customers?.map((customer) {
                            return DropdownMenuItem<User>(
                                child: Text(
                                    "${customer.lastName} ${customer.firstName}"),
                                value: customer);
                          })?.toList(),
                          onChanged: (User newValue) {
                            setState(() {
                              _selectedCustomer = newValue;
                            });
                          },
                          isExpanded: true,
                        )),
                    SizedBox(width: 10),
                    RaisedButton(
                      child: Text('Add New'),
                      onPressed: () async {
                        final User customer = await _addCustomerDialog(context);
                        if (customer != null) {
                          BlocProvider.of<CrmBloc>(context)
                              .add(UpdateCrmUser(customer));
                        }
                      },
                    )
                  ],
                ),
                SizedBox(height: 10),
                DropdownButtonFormField<Product>(
                  key: Key('dropDownProd'),
                  hint: Text('Product'),
                  value: _selectedProduct,
                  validator: (value) => value == null ? 'field required' : null,
                  items: products?.map((product) {
                    return DropdownMenuItem<Product>(
                        child: Text("${product?.productName}"), value: product);
                  })?.toList(),
                  onChanged: (Product newValue) {
                    setState(() {
                      _priceController..text = newValue.price.toString();
                      _selectedProduct = newValue;
                    });
                  },
                  isExpanded: true,
                ),
                SizedBox(height: 10),
                TextFormField(
                  key: Key('price'),
                  decoration: InputDecoration(labelText: 'Price'),
                  controller: _priceController,
                  validator: (value) {
                    if (value.isEmpty) return 'Price?';
                    return null;
                  },
                ),
                SizedBox(height: 10),
                TextFormField(
                  key: Key('quantity'),
                  decoration: InputDecoration(labelText: 'Quantity'),
                  controller: _quantityController,
                  validator: (value) {
                    if (value.isEmpty) return 'Quantity?';
                    return null;
                  },
                ),
                SizedBox(height: 10),
                RaisedButton(
                    key: Key('add'),
                    child: Text('Add'),
                    onPressed: () {
                      if (_formKey.currentState.validate() && !loading) {
                        BlocProvider.of<CartBloc>(context).add(UpdateCart(Order(
                            customerPartyId: _selectedCustomer.partyId,
                            orderItems: [
                              OrderItem(
                                  productId: _selectedProduct?.productId,
                                  price: Decimal.parse(_priceController.text),
                                  quantity:
                                      Decimal.parse(_quantityController.text))
                            ])));
                      }
                    }),
                SizedBox(height: 10),
                RaisedButton(
                    key: Key('Confirm Order'),
                    child: Text('confirm'),
                    onPressed: () {
                      if (updatedOrder.orderItems.length > 0 && !loading) {
                        BlocProvider.of<CartBloc>(context).add(ConfirmCart());
                      }
                    }),
//                Text("Grant total : ${order.grandTotal?.toString()}"),
              ]))),
      Expanded(
          child: CustomScrollView(
        slivers: <Widget>[
          SliverToBoxAdapter(
            // you could add any widget
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.transparent,
              ),
              title: Row(
                children: <Widget>[
                  Expanded(child: Text("Product", textAlign: TextAlign.center)),
                  Expanded(
                      child: Text("Quantity", textAlign: TextAlign.center)),
                  Expanded(child: Text("Price", textAlign: TextAlign.center)),
                  Expanded(
                      child: Text("SubTotal", textAlign: TextAlign.center)),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return InkWell(
                    onLongPress: () async {
                      BlocProvider.of<CartBloc>(context)
                          .add(DeleteItemCart(index));
                      Navigator.pushNamed(context, OrderRoute,
                          arguments:
                              FormArguments('item deleted', updatedOrder));
                    },
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.green,
                        child: Text(items[index]?.orderItemSeqId.toString()),
                      ),
                      title: Row(
                        children: <Widget>[
                          Expanded(
                              child: Text(
                                  "${items[index].description}[${items[index].productId}]",
                                  textAlign: TextAlign.center)),
                          Expanded(
                              child: Text("${items[index].quantity}",
                                  textAlign: TextAlign.center)),
                          Expanded(
                              child: Text("${items[index].price}",
                                  textAlign: TextAlign.center)),
                          Expanded(
                              child: Text(
                                  "${(items[index].price * items[index].quantity).toString()}",
                                  textAlign: TextAlign.center)),
                        ],
                      ),
                    ));
              },
              childCount: items == null ? 0 : items?.length,
            ),
          ),
        ],
      )),
    ]));
  }
}

_addCustomerDialog(BuildContext context) async {
  final _formKeyDialog = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  User updatedUser;

  return showDialog<User>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(32.0))),
        title: Text('Enter a new Customer', textAlign: TextAlign.center),
        content: Container(
            height: 300,
            width: 200,
            child: Form(
                key: _formKeyDialog,
                child: ListView(children: <Widget>[
                  SizedBox(height: 10),
                  TextFormField(
                    key: Key('firstName'),
                    decoration: InputDecoration(labelText: 'First Name'),
                    controller: _firstNameController,
                    validator: (value) {
                      if (value.isEmpty) return 'enter a first name?';
                      return null;
                    },
                  ),
                  SizedBox(height: 20),
                  TextFormField(
                    key: Key('lastName'),
                    decoration: InputDecoration(labelText: 'Last Name'),
                    controller: _lastNameController,
                    validator: (value) {
                      if (value.isEmpty) return 'enter a last name?';
                      return null;
                    },
                  ),
                  SizedBox(height: 20),
                  TextFormField(
                    key: Key('email'),
                    decoration: InputDecoration(labelText: 'Email address'),
                    controller: _emailController,
                    validator: (String value) {
                      if (value.isEmpty) return 'enter an Email address?';
                      if (!RegExp(
                              r"[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?")
                          .hasMatch(value)) {
                        return 'This is not a valid email';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20),
                  RaisedButton(
                      disabledColor: Colors.grey,
                      key: Key('update'),
                      child: Text('Create'),
                      onPressed: () {
                        if (_formKeyDialog.currentState.validate()) {
                          //} && !loading) {
                          updatedUser = User(
                            userGroupId: 'GROWERP_M_CUSTOMER',
                            firstName: _firstNameController.text,
                            lastName: _lastNameController.text,
                            email: _emailController.text,
                            name: _emailController.text,
                          );
                          Navigator.of(context).pop(updatedUser);
                        }
                      })
                ]))),
      );
    },
  );
}
