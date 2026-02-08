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
  final _formKey = GlobalKey<FormState>();
  late OrderAccountingLocalizations _localizations;

  @override
  void initState() {
    super.initState();
    _selectedCompanyUser = CompanyUser.tryParse(
      widget.finDoc.otherCompany ?? widget.finDoc.otherUser,
    );
    context.read<DataFetchBloc<CompaniesUsers>>().add(
      GetDataEvent(
        () => context.read<RestClient>().getCompanyUser(
          limit: 100,
          role: widget.finDoc.sales ? Role.customer : Role.supplier,
        ),
      ),
    );
    _productBloc = context.read<DataFetchBloc<Products>>()
      ..add(
        GetDataEvent(
          () => context.read<RestClient>().getProduct(
            limit: 100,
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
    _localizations = OrderAccountingLocalizations.of(context)!;
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
      // Get locale from LocaleBloc to ensure it's always correct
      final localeState = context.read<LocaleBloc>().state;
      final themeState = context.read<ThemeBloc>().state;

      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: firstFreeDate(),
        firstDate: CustomizableDateTime.current,
        lastDate: CustomizableDateTime.current.add(const Duration(days: 356)),
        selectableDayPredicate: whichDayOk,
        locale: localeState.locale,
        builder: (BuildContext context, Widget? child) {
          final isDark = themeState.themeMode == ThemeMode.dark;
          final surfaceColor = isDark
              ? Theme.of(context).colorScheme.surfaceContainerHighest
              : Theme.of(context).colorScheme.surface;

          return Theme(
            data: isDark
                ? ThemeData.dark(useMaterial3: true).copyWith(
                    primaryColor: Colors.green,
                    colorScheme: ColorScheme.dark(
                      primary: Colors.green,
                      secondary: Colors.green,
                      surface: surfaceColor,
                    ),
                    scaffoldBackgroundColor: surfaceColor,
                  )
                : ThemeData.light(useMaterial3: true).copyWith(
                    primaryColor: Colors.green,
                    colorScheme: ColorScheme.light(
                      primary: Colors.green,
                      secondary: Colors.green,
                      surface: surfaceColor,
                    ),
                  ),
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
                  ? _localizations.newRental
                  : _localizations.newOrder)
            : (classificationId == 'AppHotel'
                      ? _localizations.reservationId
                      : _localizations.orderId) +
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
                      final companyUsers =
                          (state.data as CompaniesUsers).companiesUsers;
                      return Autocomplete<CompanyUser>(
                        key: const Key('customer'),
                        initialValue: TextEditingValue(
                          text: _selectedCompanyUser != null
                              ? " ${_selectedCompanyUser!.name ?? ''}"
                              : '',
                        ),
                        displayStringForOption: (CompanyUser u) =>
                            " ${u.name ?? ''}",
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          final query = textEditingValue.text
                              .toLowerCase()
                              .trim();
                          if (query.isEmpty) return companyUsers;
                          return companyUsers.where((cu) {
                            final display = " ${cu.name ?? ''}".toLowerCase();
                            return display.contains(query);
                          }).toList();
                        },
                        fieldViewBuilder:
                            (
                              context,
                              textController,
                              focusNode,
                              onFieldSubmitted,
                            ) {
                              return TextFormField(
                                key: const Key('customerField'),
                                controller: textController,
                                focusNode: focusNode,
                                decoration: InputDecoration(
                                  labelText: _localizations.customer,
                                ),
                                onFieldSubmitted: (_) => onFieldSubmitted(),
                                validator: (value) =>
                                    (value == null || value.isEmpty)
                                    ? 'field required'
                                    : null,
                              );
                            },
                        optionsViewBuilder: (context, onSelected, options) {
                          return Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              elevation: 4,
                              borderRadius: BorderRadius.circular(12),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxHeight: 250,
                                  maxWidth: 400,
                                ),
                                child: ListView.builder(
                                  padding: EdgeInsets.zero,
                                  shrinkWrap: true,
                                  itemCount: options.length,
                                  itemBuilder: (context, idx) {
                                    final cu = options.elementAt(idx);
                                    return ListTile(
                                      dense: true,
                                      title: Text(" ${cu.name ?? ''}"),
                                      onTap: () => onSelected(cu),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                        onSelected: (CompanyUser newValue) {
                          setState(() {
                            _selectedCompanyUser = newValue;
                          });
                        },
                      );
                    default:
                      return const Center(child: LoadingIndicator());
                  }
                },
              ),
              const SizedBox(height: 20),
              Autocomplete<Product>(
                key: const Key('product'),
                initialValue: TextEditingValue(
                  text: _selectedProduct != null
                      ? " ${_selectedProduct!.productName}[${_selectedProduct!.pseudoId}]"
                      : '',
                ),
                displayStringForOption: (Product u) =>
                    " ${u.productName}[${u.pseudoId}]",
                optionsBuilder: (TextEditingValue textEditingValue) {
                  final products =
                      (_productBloc.state.data as Products).products;
                  final query = textEditingValue.text.toLowerCase().trim();
                  if (query.isEmpty) return products;
                  return products.where((p) {
                    final display = " ${p.productName}[${p.pseudoId}]"
                        .toLowerCase();
                    return display.contains(query);
                  }).toList();
                },
                fieldViewBuilder:
                    (context, textController, focusNode, onFieldSubmitted) {
                      return TextFormField(
                        key: const Key('productField'),
                        controller: textController,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          labelText: _localizations.product,
                        ),
                        onFieldSubmitted: (_) => onFieldSubmitted(),
                        validator: (value) => (value == null || value.isEmpty)
                            ? "Select a product?"
                            : null,
                      );
                    },
                optionsViewBuilder: (context, onSelected, options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(12),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxHeight: 250,
                          maxWidth: 400,
                        ),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: options.length,
                          itemBuilder: (context, idx) {
                            final p = options.elementAt(idx);
                            return ListTile(
                              dense: true,
                              title: Text(" ${p.productName}[${p.pseudoId}]"),
                              onTap: () => onSelected(p),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
                onSelected: (Product newValue) async {
                  _priceController.text = newValue.price.toString();
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
              ),
              TextFormField(
                key: const Key('price'),
                decoration: InputDecoration(
                  labelText: _localizations.priceAmount,
                ),
                controller: _priceController,
                validator: (value) {
                  if (value!.isEmpty) return _localizations.enterPriceAmount;
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
                          value == null ? _localizations.selectStartDate : null,
                      builder: (field) => InkWell(
                        onTap: () async {
                          await selectDate(context);
                          field.didChange(_selectedDate);
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: _localizations.startDate,
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
                        labelText: _localizations.numberOfDays,
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
                    child: Text(_localizations.cancel),
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
                            ? _localizations.create
                            : _localizations.update,
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
