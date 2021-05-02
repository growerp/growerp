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

import 'package:core/forms/@forms.dart';
import 'package:decimal/decimal.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:models/@models.dart';
import 'package:core/blocs/@blocs.dart';
import 'package:core/helper_functions.dart';

class ReservationDialog extends StatelessWidget {
  final FormArguments formArguments;
  const ReservationDialog({Key? key, required this.formArguments})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ReservationPage(
        message: formArguments.message, finDoc: formArguments.object as FinDoc);
  }
}

class ReservationPage extends StatefulWidget {
  final String? message;
  final FinDoc finDoc;
  ReservationPage({this.message = "hallo", required this.finDoc});
  @override
  _ReservationState createState() => _ReservationState();
}

class _ReservationState extends State<ReservationPage> {
  final _userSearchBoxController = TextEditingController();
  User? _selectedUser;
  bool loading = false;
  Product? _selectedProduct;
  DateTime _selectedDate = DateTime.now();
  TextEditingController _priceController = TextEditingController();
  TextEditingController _quantityController = TextEditingController();
  TextEditingController _daysController = TextEditingController();
  TextEditingController _productSearchBoxController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
//  _ReservationState() {
//    HelperFunctions.showTopMessage(scaffoldMessengerKey, widget.message!);
//  }

  @override
  void initState() {
    super.initState();
    _selectedUser = widget.finDoc.otherUser;
    if (widget.finDoc.items != null && widget.finDoc.items!.isNotEmpty) {
      _selectedProduct = Product(
          productId: widget.finDoc.items![0].productId,
          productName: widget.finDoc.items![0].description);
      _priceController.text = widget.finDoc.items![0].price.toString();
      _quantityController.text = widget.finDoc.items![0].quantity.toString();
      _selectedDate = widget.finDoc.items![0].rentalFromDate!;
      _daysController.text = widget.finDoc.items![0].rentalThruDate!
          .difference(widget.finDoc.items![0].rentalFromDate!)
          .inDays
          .toString();
    } else {
      _quantityController.text = "1";
      _daysController.text = "1";
    }
  }

  @override
  Widget build(BuildContext context) {
    var repos = context.read<Object>();

    return BlocConsumer<SalesOrderBloc, FinDocState>(
        listener: (context, state) {
      if (state is FinDocProblem) {
        loading = false;
        HelperFunctions.showMessage(
            context, '${state.errorMessage}', Colors.red);
      }
      if (state is FinDocSuccess) {
        HelperFunctions.showMessage(context, '${state.message}', Colors.green);
        Navigator.of(context).pop();
      }
    }, builder: (context, state) {
      return GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: GestureDetector(
              onTap: () {},
              child: Dialog(
                  insetPadding: EdgeInsets.all(10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Container(
                      height: 600,
                      width: 400,
                      child: _addRentalItemDialog(repos)))));
    });
  }

  Widget _addRentalItemDialog(repos) {
    String classificationId = GlobalConfiguration().get("classificationId");

    Future<List<Product>> getProduct(filter) async {
      var response = await repos.getProduct(
          filter: _productSearchBoxController.text,
          assetClassId: classificationId == 'AppHotel' ? 'Hotel Room' : null,
          productTypeId: classificationId == 'AppHotel' ? 'Rental' : null);
      return response;
    }

    Future<void> _selectDate(BuildContext context) async {
      final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(Duration(days: 356)));
      if (picked != null && picked != _selectedDate)
        setState(() {
          _selectedDate = picked;
        });
    }

    Future<List<User>> getData(userGroupId, filter) async {
      var response = await repos.getUser(
          userGroupId: userGroupId, filter: _userSearchBoxController.text);
      return response;
    }

    return Center(
        child: Container(
            width: 300,
            child: Form(
                key: _formKey,
                child: ListView(
                  children: <Widget>[
                    SizedBox(height: 30),
                    Center(
                        child: Text(
                            widget.finDoc.orderId == null
                                ? (classificationId == 'AppHotel'
                                    ? "New Reservation"
                                    : "New order")
                                : (classificationId == 'AppHotel'
                                        ? "Reservation #"
                                        : "Order #") +
                                    widget.finDoc.orderId!,
                            style: TextStyle(
                                fontSize: 15,
                                color: Colors.black,
                                fontWeight: FontWeight.bold))),
                    SizedBox(height: 20),
                    Row(children: [
                      Expanded(
                          child: DropdownSearch<User>(
                        label: 'Customer',
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
                        itemAsString: (User? u) =>
                            "${u!.firstName} ${u.lastName}, ${u.companyName}",
                        onFind: (String filter) => getData("GROWERP_M_CUSTOMER",
                            _userSearchBoxController.text),
                        onChanged: (User? newValue) {
                          setState(() {
                            _selectedUser = newValue;
                          });
                        },
                        validator: (value) =>
                            value == null ? 'field required' : null,
                      )),
                      SizedBox(width: 10),
                      SizedBox(
                          width: 100,
                          child: ElevatedButton(
                            child: Text('Create New\n Customer'),
                            onPressed: () async {
                              var result = await showDialog(
                                  barrierDismissible: true,
                                  context: context,
                                  builder: (BuildContext context) {
                                    return UserDialog(
                                        formArguments: FormArguments(
                                            object: User(
                                                userGroupId:
                                                    "GROWERP_M_CUSTOMER")));
                                  });
                              setState(() {
                                if (result is User) _selectedUser = result;
                              });
                            },
                          )),
                    ]),
                    SizedBox(height: 20),
                    DropdownSearch<Product>(
                      label: classificationId == 'AppHotel'
                          ? 'Room Type'
                          : 'Product',
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
                      },
                      validator: (value) =>
                          value == null ? 'field required' : null,
                    ),
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
                    Row(children: [
                      Expanded(
                          child: Center(
                              child: Text("Begindate:" +
                                  "${_selectedDate.toLocal()}".split(' ')[0]))),
                      SizedBox(
                          width: 100,
                          child: ElevatedButton(
                            onPressed: () => _selectDate(context),
                            child: Text(' Update\nBegindate'),
                          )),
                    ]),
                    SizedBox(height: 20),
                    Row(children: [
                      Expanded(
                          child: TextFormField(
                        decoration:
                            InputDecoration(labelText: 'Number of days'),
                        controller: _daysController,
                      )),
                      SizedBox(width: 10),
                      Expanded(
                          child: TextFormField(
                        decoration:
                            InputDecoration(labelText: 'Number of rooms'),
                        controller: _quantityController,
                      )),
                    ]),
                    SizedBox(height: 20),
                    Row(children: [
                      Expanded(
                          child: ElevatedButton(
                        child: Text('Cancel'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      )),
                      SizedBox(width: 20),
                      Expanded(
                          child: ElevatedButton(
                        child: Text(widget.finDoc.orderId == null
                            ? 'Create'
                            : 'Update'),
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            BlocProvider.of<SalesOrderBloc>(context).add(
                                CreateFinDoc(FinDoc(
                                    orderId: widget.finDoc.orderId,
                                    sales: true,
                                    docType: 'order',
                                    otherUser: _selectedUser,
                                    statusId: 'FinDocCreated',
                                    items: [
                                  FinDocItem(
                                    itemTypeId: 'ItemRental',
                                    productId: _selectedProduct!.productId,
                                    price: Decimal.parse(_priceController.text),
                                    description: _selectedProduct!.productName,
                                    rentalFromDate: _selectedDate,
                                    rentalThruDate: _selectedDate.add(Duration(
                                        days: int.parse(_daysController.text))),
                                    quantity: _quantityController.text.isEmpty
                                        ? Decimal.parse('1')
                                        : Decimal.parse(
                                            _quantityController.text),
                                  )
                                ])));
                          }
                        },
                      )),
                    ]),
                  ],
                ))));
  }
}
