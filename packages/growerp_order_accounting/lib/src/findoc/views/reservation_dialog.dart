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
import 'package:global_configuration/global_configuration.dart';
import 'package:intl/intl.dart';
import 'package:growerp_core/growerp_core.dart';
import '../findoc.dart';

class ReservationDialog extends StatefulWidget {
  /// original order
  final FinDoc? original;

  /// extracted single item order
  final FinDoc finDoc;
  const ReservationDialog({super.key, required this.finDoc, this.original});
  @override
  ReservationDialogState createState() => ReservationDialogState();
}

class ReservationDialogState extends State<ReservationDialog> {
  final _userSearchBoxController = TextEditingController();
  User? _selectedUser;
  bool loading = false;
  Product? _selectedProduct;
  late DateTime _selectedDate;
  List<String> rentalDays = [];
  late String classificationId;
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _daysController = TextEditingController();
  final TextEditingController _productSearchBoxController =
      TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _selectedUser = widget.finDoc.otherUser;
    if (widget.finDoc.items.isNotEmpty) {
      _selectedProduct = Product(
          productId: widget.finDoc.items[0].productId!,
          productName: widget.finDoc.items[0].description);
      _priceController.text = widget.finDoc.items[0].price.toString();
      _quantityController.text = widget.finDoc.items[0].quantity.toString();
      _selectedDate = widget.finDoc.items[0].rentalFromDate!;
      _daysController.text = widget.finDoc.items[0].rentalThruDate!
          .difference(widget.finDoc.items[0].rentalFromDate!)
          .inDays
          .toString();
    } else {
      _quantityController.text = "1";
      _daysController.text = "1";
      _selectedDate = CustomizableDateTime.current;
    }
    classificationId = GlobalConfiguration().get("classificationId");
  }

  @override
  Widget build(BuildContext context) {
    var repos = context.read<APIRepository>();

    return GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Scaffold(
            backgroundColor: Colors.transparent,
            body: GestureDetector(
                onTap: () {},
                child: Dialog(
                    key: const Key('ReservationDialog'),
                    insetPadding: const EdgeInsets.all(10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: BlocListener<FinDocBloc, FinDocState>(
                        listener: (context, state) async {
                          switch (state.status) {
                            case FinDocStatus.success:
                              HelperFunctions.showMessage(
                                  context,
                                  '${widget.finDoc.idIsNull() ? "Add" : "Update"} successfull',
                                  Colors.green);
                              await Future.delayed(
                                  const Duration(milliseconds: 500));
                              if (!mounted) return;
                              Navigator.of(context).pop();
                              break;
                            case FinDocStatus.failure:
                              HelperFunctions.showMessage(context,
                                  'Error: ${state.message}', Colors.red);
                              break;
                            default:
                              const Text("????");
                          }
                        },
                        child: SizedBox(
                            height: 600,
                            width: 400,
                            child: _addRentalItemDialog(repos)))))));
  }

  Widget _addRentalItemDialog(repos) {
    bool whichDayOk(DateTime day) {
      var formatter = DateFormat('yyyy-MM-dd');
      String date = formatter.format(day);
      if (rentalDays.contains(date)) return false;
      return true;
    }

    Future<void> selectDate(BuildContext context) async {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: _selectedDate,
        firstDate: CustomizableDateTime.current,
        lastDate: CustomizableDateTime.current.add(const Duration(days: 356)),
        selectableDayPredicate: whichDayOk,
      );
      if (picked != null && picked != _selectedDate) {
        setState(() {
          _selectedDate = picked;
        });
      }
    }

    return Center(
        child: SizedBox(
            width: 300,
            child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                    key: const Key('listView'),
                    child: Column(children: <Widget>[
                      const SizedBox(height: 30),
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
                              style: const TextStyle(
                                  fontSize: 15,
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold))),
                      const SizedBox(height: 20),
                      Row(children: [
                        Expanded(
                            child: DropdownSearch<User>(
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
                            menuProps: MenuProps(
                                borderRadius: BorderRadius.circular(20.0)),
                            title: Container(
                                height: 50,
                                decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColorDark,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(20),
                                      topRight: Radius.circular(20),
                                    )),
                                child: const Center(
                                    child: Text('Select customer',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        )))),
                          ),
                          dropdownSearchDecoration: InputDecoration(
                            labelText: 'Customer',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25.0)),
                          ),
                          key: const Key('customer'),
                          itemAsString: (User? u) =>
                              "${u!.firstName} ${u.lastName}, ${u.company!.name}",
                          asyncItems: (String? filter) async {
                            ApiResult<List<User>> result = await repos.getUser(
                                userGroups: [UserGroup.customer],
                                filter: _userSearchBoxController.text);
                            return result.when(
                                success: (data) => data,
                                failure: (_) =>
                                    [User(lastName: 'get data error!')]);
                          },
                          onChanged: (User? newValue) {
                            setState(() {
                              _selectedUser = newValue;
                            });
                          },
                          validator: (value) =>
                              value == null ? 'field required' : null,
                        )),
                        const SizedBox(width: 10),
                        SizedBox(
                            width: 100,
                            child: ElevatedButton(
                              key: const Key('newCustomer'),
                              child: const Text('Create New\n Customer'),
                              onPressed: () async {
                                var result = await showDialog(
                                    barrierDismissible: true,
                                    context: context,
                                    builder: (BuildContext context) {
                                      return BlocProvider.value(
                                          value: context.read<CustomerBloc>()
                                              as UserBloc,
                                          child: UserDialog(
                                              user: User(
                                                  userGroup:
                                                      UserGroup.customer)));
                                    });
                                setState(() {
                                  if (result is User) _selectedUser = result;
                                });
                              },
                            )),
                      ]),
                      const SizedBox(height: 20),
                      DropdownSearch<Product>(
                        selectedItem: _selectedProduct,
                        popupProps: PopupProps.menu(
                          showSearchBox: true,
                          searchFieldProps: TextFieldProps(
                            autofocus: true,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(25.0)),
                            ),
                            controller: _productSearchBoxController,
                          ),
                          menuProps: MenuProps(
                              borderRadius: BorderRadius.circular(20.0)),
                          title: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColorDark,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(20),
                                    topRight: Radius.circular(20),
                                  )),
                              child: Center(
                                  child: Text(
                                      "Select ${classificationId == 'AppHotel' ? 'room type' : 'product'}",
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      )))),
                        ),
                        dropdownSearchDecoration: InputDecoration(
                          labelText: classificationId == 'AppHotel'
                              ? 'Room Type'
                              : 'Product',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25.0)),
                        ),
                        key: const Key('product'),
                        itemAsString: (Product? u) => "${u!.productName}",
                        asyncItems: (String? filter) async {
                          ApiResult<List<Product>> result =
                              await repos.getProduct(
                                  filter: _productSearchBoxController.text,
                                  assetClassId: classificationId == 'AppHotel'
                                      ? 'Hotel Room'
                                      : null);
                          return result.when(
                              success: (data) => data,
                              failure: (_) =>
                                  [Product(productName: 'get data error!')]);
                        },
                        onChanged: (Product? newValue) async {
                          _selectedProduct = newValue;
                          _priceController.text = newValue!.price.toString();
                          rentalDays = await getRentalOccupancy(
                              repos: repos, productId: newValue.productId);
                          while (!whichDayOk(_selectedDate)) {
                            _selectedDate =
                                _selectedDate.add(const Duration(days: 1));
                          }
                          setState(() {
                            _selectedDate = _selectedDate;
                          });
                        },
                        validator: (value) =>
                            value == null ? 'field required' : null,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        key: const Key('price'),
                        decoration:
                            const InputDecoration(labelText: 'Price/Amount'),
                        controller: _priceController,
                        validator: (value) {
                          if (value!.isEmpty) return 'Enter Price or Amount?';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      Row(children: [
                        Expanded(
                            child: Center(
                                child: Text(
                          "${_selectedDate.toLocal()}".split(' ')[0],
                          key: const Key('date'),
                        ))),
                        SizedBox(
                            width: 100,
                            child: ElevatedButton(
                              key: const Key('setDate'),
                              onPressed: () => selectDate(context),
                              child: const Text(' Update\nBegindate'),
                            )),
                      ]),
                      const SizedBox(height: 20),
                      Row(children: [
                        Expanded(
                            child: TextFormField(
                          key: const Key('quantity'),
                          decoration: const InputDecoration(
                              labelText: 'Number of days'),
                          controller: _daysController,
                        )),
                        const SizedBox(width: 10),
                        Expanded(
                            child: TextFormField(
                          key: const Key('nbrOfRooms'),
                          decoration: const InputDecoration(
                              labelText: 'Number of rooms'),
                          controller: _quantityController,
                        )),
                      ]),
                      const SizedBox(height: 20),
                      Row(children: [
                        Expanded(
                            child: ElevatedButton(
                          key: const Key('cancel'),
                          child: const Text('Cancel'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        )),
                        const SizedBox(width: 20),
                        Expanded(
                            child: ElevatedButton(
                                key: const Key('update'),
                                child: Text(widget.finDoc.orderId == null
                                    ? 'Create'
                                    : 'Update'),
                                onPressed: () {
                                  if (_formKey.currentState!.validate()) {
                                    FinDoc newFinDoc = widget.finDoc
                                        .copyWith(otherUser: _selectedUser);
                                    FinDocItem newItem = FinDocItem(
                                        productId: _selectedProduct!.productId,
                                        price: Decimal.parse(
                                            _priceController.text),
                                        description:
                                            _selectedProduct!.productName,
                                        rentalFromDate: _selectedDate,
                                        rentalThruDate: _selectedDate.add(
                                            Duration(
                                                days: int.parse(
                                                    _daysController.text))),
                                        quantity:
                                            _quantityController.text.isEmpty
                                                ? Decimal.parse('1')
                                                : Decimal.parse(
                                                    _quantityController.text));
                                    if (widget.original?.orderId == null) {
                                      newFinDoc =
                                          newFinDoc.copyWith(items: [newItem]);
                                    } else {
                                      List<FinDocItem> newItemList =
                                          List.of(widget.original!.items);
                                      int index = newItemList.indexWhere(
                                          (element) =>
                                              element.itemSeqId ==
                                              newItem.itemSeqId);
                                      newItemList[index] = newItem;
                                      newFinDoc = newFinDoc.copyWith(
                                          items: newItemList);
                                    }
                                    context
                                        .read<FinDocBloc>()
                                        .add(FinDocUpdate(newFinDoc));
                                  }
                                }))
                      ]),
                    ])))));
  }
}
