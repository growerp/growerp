// ignore_for_file: depend_on_referenced_packages

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

import 'package:universal_io/io.dart';
import 'package:decimal/decimal.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

import '../../product/product.dart';
import '../asset.dart';

class AssetDialog extends StatefulWidget {
  final Asset asset;
  const AssetDialog(this.asset, {super.key});
  @override
  AssetDialogState createState() => AssetDialogState();
}

class AssetDialogState extends State<AssetDialog> {
  final _assetDialogformKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityOnHandController =
      TextEditingController();
  final TextEditingController _acquireCostController = TextEditingController();
  final TextEditingController _productSearchBoxController =
      TextEditingController();
  final TextEditingController _locationSearchBoxController =
      TextEditingController();
  late String classificationId;
  late AssetBloc _assetBloc;
  late ProductBloc _productBloc;
  late DataFetchBloc<Locations> _locationBloc;
  Location? _selectedLocation;
  Product? _selectedProduct;
  late String _statusId;
  late String currencyId;
  late String currencySymbol;

  @override
  void initState() {
    super.initState();
    currencyId = context
        .read<AuthBloc>()
        .state
        .authenticate!
        .company!
        .currency!
        .currencyId!;
    currencySymbol = NumberFormat.simpleCurrency(
            locale: Platform.localeName, name: currencyId)
        .currencySymbol;
    _assetBloc = context.read<AssetBloc>();
    _productBloc = context.read<ProductBloc>();
    _productBloc.add(const ProductFetch());
    _statusId = widget.asset.statusId ?? 'Available';
    _nameController.text = widget.asset.assetName ?? '';
    _quantityOnHandController.text = widget.asset.quantityOnHand == null
        ? ''
        : widget.asset.quantityOnHand.toString();
    _acquireCostController.text = widget.asset.acquireCost == null
        ? ''
        : widget.asset.acquireCost.toString();
    _selectedProduct = widget.asset.product;
    _selectedLocation = widget.asset.location;
    classificationId = context.read<String>();
    _locationBloc = context.read<DataFetchBloc<Locations>>()
      ..add(
          GetDataEvent(() => context.read<RestClient>().getLocation(limit: 3)));
  }

  @override
  Widget build(BuildContext context) {
    bool isPhone = ResponsiveBreakpoints.of(context).isMobile;
    return BlocConsumer<AssetBloc, AssetState>(listener: (context, state) {
      switch (state.status) {
        case AssetStatus.success:
          Navigator.of(context).pop();
          break;
        case AssetStatus.failure:
          HelperFunctions.showMessage(
              context, 'Error: ${state.message}', Colors.red);
          break;
        default:
          const Text("????");
      }
    }, builder: (context, state) {
      switch (state.status) {
        case AssetStatus.success:
          return Scaffold(
              backgroundColor: Colors.transparent,
              body: Dialog(
                  key: const Key('AssetDialog'),
                  insetPadding: const EdgeInsets.all(10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: popUp(
                      context: context,
                      title: (classificationId == 'AppHotel'
                              ? "Room #"
                              : "Asset #") +
                          (widget.asset.assetId.isEmpty
                              ? "New"
                              : widget.asset.assetId),
                      height: 450,
                      width: 350,
                      child: _showForm(isPhone))));
        case AssetStatus.failure:
          return const FatalErrorForm(message: 'Asset load problem');
        default:
          return const Center(child: LoadingIndicator());
      }
    });
  }

  Widget _showForm(bool isPhone) {
    return Center(
        child: Form(
            key: _assetDialogformKey,
            child: ListView(key: const Key('listView'), children: <Widget>[
              TextFormField(
                key: const Key('name'),
                decoration: InputDecoration(
                    labelText: classificationId == 'AppHotel'
                        ? 'Room Name/#'
                        : 'Asset Name'),
                controller: _nameController,
                validator: (value) {
                  if (value!.isEmpty) return 'Please enter a asset name?';
                  return null;
                },
              ),
              Visibility(
                  visible: classificationId != 'AppHotel',
                  child: const SizedBox(height: 20)),
              Visibility(
                  visible: classificationId != 'AppHotel',
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          key: const Key('quantityOnHand'),
                          decoration: const InputDecoration(
                              labelText: 'Quantity on Hand'),
                          keyboardType: TextInputType.number,
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.allow(
                                RegExp('[0-9.,]+'))
                          ],
                          controller: _quantityOnHandController,
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Please enter a quantityOnHand?';
                            }
                            return null;
                          },
                        ),
                      ),
                      Expanded(
                        child: TextFormField(
                          key: const Key('acquireCost'),
                          decoration: InputDecoration(
                              labelText: 'Aquired Costs($currencySymbol)'),
                          keyboardType: TextInputType.number,
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.allow(
                                RegExp('[0-9.,]+'))
                          ],
                          controller: _acquireCostController,
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Please enter a aquired cost value?';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  )),
              BlocBuilder<ProductBloc, ProductState>(builder: (context, state) {
                switch (state.status) {
                  case ProductStatus.failure:
                    return const FatalErrorForm(
                        message: 'server connection problem');
                  case ProductStatus.success:
                    return DropdownSearch<Product>(
                      key: const Key('productDropDown'),
                      selectedItem: _selectedProduct,
                      popupProps: PopupProps.menu(
                        isFilterOnline: true,
                        showSearchBox: true,
                        searchFieldProps: TextFieldProps(
                          autofocus: true,
                          decoration: InputDecoration(
                              labelText:
                                  "${classificationId == 'AppHotel' ? 'Room Type' : 'Product id'} name"),
                          controller: _productSearchBoxController,
                        ),
                        title: popUp(
                          context: context,
                          title:
                              'Select ${classificationId == 'AppHotel' ? 'Room Type' : 'Product'}',
                          height: 50,
                        ),
                      ),
                      dropdownDecoratorProps: DropDownDecoratorProps(
                        dropdownSearchDecoration: InputDecoration(
                          labelText: classificationId == 'AppHotel'
                              ? 'Room Type[id]'
                              : 'Product[id]',
                        ),
                      ),
                      itemAsString: (Product? u) =>
                          " ${u!.productName}[${u.pseudoId}]", // invisible char for test
                      onChanged: (Product? newValue) {
                        _selectedProduct = newValue;
                      },
                      asyncItems: (String filter) {
                        _productBloc.add(ProductFetch(
                            searchString: filter, isForDropDown: true));
                        return Future.value(state.products);
                      },
                      compareFn: (item, sItem) =>
                          item.productId == sItem.productId,
                      validator: (value) =>
                          value == null ? 'field required' : null,
                    );
                  default:
                    return const Center(child: LoadingIndicator());
                }
              }),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      key: const Key('statusDropDown'),
                      decoration: const InputDecoration(labelText: 'Status'),
                      value: _statusId,
                      validator: (value) =>
                          value == null ? 'field required' : null,
                      items: assetStatusValues
                          .map((label) => DropdownMenuItem<String>(
                                value: label,
                                child: Text(label),
                              ))
                          .toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _statusId = newValue!;
                        });
                      },
                      isExpanded: true,
                    ),
                  ),
                  Expanded(
                    child: DropdownSearch<Location>(
                        key: const Key('locationDropDown'),
                        selectedItem: _selectedLocation,
                        popupProps: PopupProps.menu(
                          isFilterOnline: true,
                          showSearchBox: true,
                          searchFieldProps: TextFieldProps(
                            autofocus: true,
                            decoration: const InputDecoration(
                                labelText: "location name"),
                            controller: _locationSearchBoxController,
                          ),
                          menuProps: MenuProps(
                              borderRadius: BorderRadius.circular(20.0)),
                          title: popUp(
                            context: context,
                            title: 'Select location',
                            height: 50,
                          ),
                        ),
                        dropdownDecoratorProps: const DropDownDecoratorProps(
                            dropdownSearchDecoration:
                                InputDecoration(labelText: 'Location')),
                        itemAsString: (Location? u) =>
                            " ${u?.locationName ?? ''}",
                        asyncItems: (String filter) {
                          _locationBloc.add(GetDataEvent(() => context
                              .read<RestClient>()
                              .getLocation(searchString: filter, limit: 3)));
                          return Future.delayed(
                              const Duration(milliseconds: 250), () {
                            return Future.value(
                                (_locationBloc.state.data as Locations)
                                    .locations);
                          });
                        },
                        compareFn: (item, sItem) =>
                            item.locationId == sItem.locationId,
                        onChanged: (Location? newValue) {
                          _selectedLocation = newValue!;
                        }),
                  )
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                  key: const Key('update'),
                  child:
                      Text(widget.asset.assetId.isEmpty ? 'Create' : 'Update'),
                  onPressed: () async {
                    if (_assetDialogformKey.currentState!.validate()) {
                      _assetBloc.add(AssetUpdate(
                        Asset(
                          assetId: widget.asset.assetId,
                          assetClassId: classificationId == 'AppHotel'
                              ? 'Hotel Room'
                              : null,
                          assetName: _nameController.text,
                          quantityOnHand: _quantityOnHandController.text != ""
                              ? Decimal.parse(_quantityOnHandController.text)
                              : Decimal.parse('1'),
                          product: _selectedProduct,
                          statusId: _statusId,
                        ),
                      ));
                    }
                  }),
            ])));
  }
}
