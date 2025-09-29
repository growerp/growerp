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
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_order_accounting/l10n/generated/order_accounting_localizations.dart';
import 'package:intl/intl.dart';
import '../../findoc.dart';

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
  late DataFetchBloc<CompaniesUsers> _companyUserBloc;
  CompanyUser? _selectedCompanyUser;
  bool loading = false;
  late DataFetchBloc<Products> _productBloc;
  late SalesOrderBloc _salesOrderBloc; // get/update sales order
  late FinDocBloc _finDocBloc; // get rental dates
  Product? _selectedProduct;
  late DateTime _selectedDate;
  List<DateTime> rentalDays = [];
  late String classificationId;
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _daysController = TextEditingController();
  final TextEditingController _productSearchBoxController =
      TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late OrderAccountingLocalizations _local;

  @override
  void initState() {
    super.initState();
    _selectedCompanyUser = CompanyUser.tryParse(
      widget.finDoc.otherCompany ?? widget.finDoc.otherUser,
    );
    _companyUserBloc = context.read<DataFetchBloc<CompaniesUsers>>()
      ..add(
        GetDataEvent(
          () => context.read<RestClient>().getCompanyUser(
            limit: 3,
            role: widget.finDoc.sales ? Role.customer : Role.supplier,
          ),
        ),
      );
    _productBloc = context.read<DataFetchBloc<Products>>()
      ..add(
        GetDataEvent(
          () => context.read<RestClient>().getProduct(
            limit: 3,
            isForDropDown: true,
            //          assetClassId: classificationId == 'AppHotel' ? 'Hotel Room' : '',
            classificationId: classificationId,
          ),
        ),
      );
    if (widget.finDoc.items.isNotEmpty) {
      _selectedProduct = Product(
        productId: widget.finDoc.items[0].product?.productId ?? '',
        productName: widget.finDoc.items[0].description,
      );
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
    _finDocBloc = context.read<FinDocBloc>();
    _salesOrderBloc = context.read<SalesOrderBloc>();
  }

  @override
  Widget build(BuildContext context) {
    _local = OrderAccountingLocalizations.of(context)!;
    return BlocConsumer<SalesOrderBloc, FinDocState>(
      listener: (context, salesOrderState) {
        if (salesOrderState.status == FinDocStatus.failure) {
          HelperFunctions.showMessage(
            context,
            '${salesOrderState.message}',
            Colors.red,
          );
        }
        if (salesOrderState.status == FinDocStatus.success) {
          Navigator.of(context).pop();
        }
      },
      builder: (context, salesOrderState) {
        if (salesOrderState.status == FinDocStatus.loading) {
          return const LoadingIndicator();
        } else {
          return SizedBox(
            height: 600,
            width: 400,
            child: _addRentalItemDialog(),
          );
        }
      },
    );
  }

  bool whichDayOk(DateTime day) {
    if (rentalDays.any((date) => date.dateOnly() == _selectedDate.dateOnly())) {
      return false;
    }
    return true;
  }

  DateTime firstFreeDate() {
    var nowDate = CustomizableDateTime.current;
    while (whichDayOk(nowDate) == false) {
      nowDate = nowDate.add(const Duration(days: 1));
    }
    return nowDate;
  }

  Widget _addRentalItemDialog() {
    Future<void> selectDate(BuildContext context) async {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: firstFreeDate(),
        firstDate: CustomizableDateTime.current,
        lastDate: CustomizableDateTime.current.add(const Duration(days: 356)),
        selectableDayPredicate: whichDayOk,
        locale: const Locale(
          'sv',
          'SE',
        ), // Swedish locale uses YYYY-MM-DD format
        builder: (BuildContext context, Widget? child) {
          return Theme(
            data: ThemeData(primarySwatch: Colors.green),
            child: child!,
          );
        },
      );
      if (picked != null && picked != _selectedDate) {
        setState(() {
          _selectedDate = picked;
        });
      }
    }

    return Dialog(
      key: const Key('ReservationDialog'),
      insetPadding: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: popUp(
        context: context,
        height: 550,
        width: 400,
        title: widget.finDoc.orderId == null
            ? (classificationId == 'AppHotel'
                  ? _local.newRental
                  : _local.newOrder)
            : (classificationId == 'AppHotel'
                      ? _local.reservationId
                      : _local.orderId) +
                  widget.finDoc.pseudoId!,
        child: Form(
          key: _formKey,
          child: ListView(
            key: const Key('listView'),
            children: <Widget>[
              BlocBuilder<
                DataFetchBloc<CompaniesUsers>,
                DataFetchState<CompaniesUsers>
              >(
                builder: (context, state) {
                  switch (state.status) {
                    case DataFetchStatus.loading:
                      return const LoadingIndicator();
                    case DataFetchStatus.failure:
                    case DataFetchStatus.success:
                      return DropdownSearch<CompanyUser>(
                        selectedItem: _selectedCompanyUser,
                        popupProps: PopupProps.menu(
                          isFilterOnline: true,
                          showSearchBox: true,
                          searchFieldProps: TextFieldProps(
                            autofocus: true,
                            decoration: InputDecoration(
                              labelText: _local.customerSearch,
                            ),
                            controller: _userSearchBoxController,
                          ),
                          menuProps: MenuProps(
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          title: popUp(
                            context: context,
                            title: _local.selectCustomer,
                            height: 50,
                          ),
                        ),
                        dropdownDecoratorProps: DropDownDecoratorProps(
                          dropdownSearchDecoration: InputDecoration(
                            labelText: _local.customer,
                          ),
                        ),
                        key: const Key('customer'),
                        itemAsString: (CompanyUser? u) => " ${u!.name ?? ''}",
                        asyncItems: (String filter) {
                          _companyUserBloc.add(
                            GetDataEvent(
                              () => context.read<RestClient>().getCompanyUser(
                                searchString: filter,
                                limit: 3,
                                role: widget.finDoc.sales
                                    ? Role.customer
                                    : Role.supplier,
                              ),
                            ),
                          );
                          return Future.delayed(
                            const Duration(milliseconds: 150),
                            () {
                              return Future.value(
                                (_companyUserBloc.state.data as CompaniesUsers)
                                    .companiesUsers,
                              );
                            },
                          );
                        },
                        compareFn: (item, sItem) =>
                            item.partyId == sItem.partyId,
                        onChanged: (CompanyUser? newValue) {
                          setState(() {
                            _selectedCompanyUser = newValue;
                          });
                        },
                        validator: (value) =>
                            value == null ? 'field required' : null,
                      );
                    default:
                      return const Center(child: LoadingIndicator());
                  }
                },
              ),
              const SizedBox(height: 20),
              DropdownSearch<Product>(
                selectedItem: _selectedProduct,
                popupProps: PopupProps.menu(
                  showSelectedItems: true,
                  isFilterOnline: true,
                  showSearchBox: true,
                  searchFieldProps: TextFieldProps(
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: classificationId == 'AppHotel'
                          ? _local.roomType
                          : _local.product,
                    ),
                    controller: _productSearchBoxController,
                  ),
                  menuProps: MenuProps(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  title: popUp(
                    context: context,
                    title: _local.selectProduct,
                    height: 50,
                  ),
                ),
                dropdownDecoratorProps: DropDownDecoratorProps(
                  dropdownSearchDecoration: InputDecoration(
                    labelText: _local.product,
                  ),
                ),
                key: const Key('product'),
                itemAsString: (Product? u) =>
                    " ${u!.productName}[${u.pseudoId}]",
                asyncItems: (String filter) {
                  _productBloc.add(
                    GetDataEvent(
                      () => context.read<RestClient>().getProduct(
                        searchString: filter,
                        limit: 3,
                        isForDropDown: true,
                        //                                      assetClassId:
                        //                                          classificationId == 'AppHotel'
                        //                                              ? 'Hotel Room'
                        //                                              : '',
                      ),
                    ),
                  );
                  return Future.delayed(const Duration(milliseconds: 150), () {
                    return Future.value(
                      (_productBloc.state.data as Products).products,
                    );
                  });
                },
                compareFn: (item, sItem) => item.productId == sItem.productId,
                onChanged: (Product? newValue) async {
                  _priceController.text = newValue!.price.toString();
                  _finDocBloc.add(FinDocProductRentalDates(newValue.productId));
                  await Future.delayed(
                    const Duration(milliseconds: 800),
                    () {},
                  );
                  setState(() {
                    _selectedProduct = newValue;
                    rentalDays = _finDocBloc.state.productRentalDates.isNotEmpty
                        ? _finDocBloc.state.productRentalDates[0].dates
                        : [];
                    _selectedDate = firstFreeDate();
                  });
                },
                validator: (value) =>
                    value == null ? "Select a product?" : null,
              ),
              TextFormField(
                key: const Key('price'),
                decoration: InputDecoration(labelText: _local.priceAmount),
                controller: _priceController,
                validator: (value) {
                  if (value!.isEmpty) return _local.enterPriceAmount;
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: FormField<DateTime>(
                      key: const Key('setDate'),
                      initialValue: _selectedDate,
                      validator: (value) =>
                          value == null ? _local.selectStartDate : null,
                      builder: (field) => InkWell(
                        onTap: () async {
                          await selectDate(context);
                          field.didChange(_selectedDate);
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: _local.startDate,
                            errorText: field.errorText,
                            suffixIcon: const Icon(Icons.arrow_drop_down),
                          ),
                          child: Text(
                            DateFormat('yyyy-MM-dd').format(_selectedDate),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      key: const Key('quantity'),
                      decoration: InputDecoration(
                        labelText: _local.numberOfDays,
                      ),
                      controller: _daysController,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  OutlinedButton(
                    key: const Key('cancel'),
                    child: Text(_local.cancel),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: OutlinedButton(
                      key: const Key('update'),
                      child: Text(
                        widget.finDoc.orderId == null
                            ? _local.create
                            : _local.update,
                      ),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          FinDoc newFinDoc = widget.finDoc.copyWith(
                            otherUser: _selectedCompanyUser?.getUser(),
                            otherCompany: _selectedCompanyUser?.getCompany(),
                            status: FinDocStatusVal.created,
                          );
                          FinDocItem newItem = FinDocItem(
                            product: _selectedProduct,
                            itemType: ItemType(itemTypeId: 'ItemRental'),
                            price: Decimal.parse(_priceController.text),
                            description: _selectedProduct!.productName,
                            rentalFromDate: _selectedDate.noon(),
                            rentalThruDate: _selectedDate
                                .add(
                                  Duration(
                                    days: int.parse(_daysController.text),
                                  ),
                                )
                                .noon(),
                            quantity: _quantityController.text.isEmpty
                                ? Decimal.parse('1')
                                : Decimal.parse(_quantityController.text),
                          );
                          if (widget.original?.orderId == null) {
                            newFinDoc = newFinDoc.copyWith(items: [newItem]);
                          } else {
                            List<FinDocItem> newItemList = List.of(
                              widget.original!.items,
                            );
                            int index = newItemList.indexWhere(
                              (element) =>
                                  element.itemSeqId == newItem.itemSeqId,
                            );
                            newItemList[index] = newItem;
                            newFinDoc = newFinDoc.copyWith(items: newItemList);
                          }
                          _salesOrderBloc.add(FinDocUpdate(newFinDoc));
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
