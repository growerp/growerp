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

import 'package:decimal/decimal.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:growerp_core/growerp_core.dart';

class AssetDialog extends StatelessWidget {
  final Asset asset;
  const AssetDialog(this.asset, {super.key});
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (BuildContext context) => ProductBloc(CatalogAPIRepository(
          context.read<AuthBloc>().state.authenticate!.apiKey!))
        ..add(const ProductFetch()),
      child: AssetDialogFull(asset),
    );
  }
}

class AssetDialogFull extends StatefulWidget {
  final Asset asset;
  const AssetDialogFull(this.asset, {super.key});
  @override
  AssetDialogState createState() => AssetDialogState();
}

class AssetDialogState extends State<AssetDialogFull> {
  final _assetDialogformKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityOnHandController =
      TextEditingController();
  final TextEditingController _productSearchBoxController =
      TextEditingController();
  late String classificationId;
  late AssetBloc _assetBloc;
  late ProductBloc _productBloc;
  Product? _selectedProduct;
  String? _statusId = 'Available';

  @override
  void initState() {
    super.initState();
    _assetBloc = context.read<AssetBloc>();
    _productBloc = context.read<ProductBloc>();
    _productBloc.add(const ProductFetch());
    _statusId = widget.asset.statusId;
    _nameController.text = widget.asset.assetName ?? '';
    _quantityOnHandController.text = widget.asset.quantityOnHand == null
        ? ''
        : widget.asset.quantityOnHand.toString();
    _selectedProduct = widget.asset.product;
    classificationId = GlobalConfiguration().get("classificationId");
  }

  @override
  Widget build(BuildContext context) {
    bool isPhone = ResponsiveBreakpoints.of(context).isMobile;
    return BlocConsumer<AssetBloc, AssetState>(
        listener: (context, state) async {
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
                      title: classificationId == 'AppHotel'
                          ? 'Room information'
                          : 'Asset Information',
                      height: 400,
                      width: 400,
                      child: _showForm(isPhone))));
        case AssetStatus.failure:
          return const FatalErrorForm(message: 'Asset load problem');
        default:
          return const Center(child: CircularProgressIndicator());
      }
    });
  }

  Widget _showForm(bool isPhone) {
    return Center(
        child: Form(
            key: _assetDialogformKey,
            child: ListView(key: const Key('listView'), children: <Widget>[
              Center(
                  child: Text(
                      (classificationId == 'AppHotel' ? "Room #" : "Asset #") +
                          (widget.asset.assetId.isEmpty
                              ? "New"
                              : widget.asset.assetId),
                      key: const Key('header'))),
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
                  child: TextFormField(
                    key: const Key('quantityOnHand'),
                    decoration:
                        const InputDecoration(labelText: 'Quantity on Hand'),
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(RegExp('[0-9.,]+'))
                    ],
                    controller: _quantityOnHandController,
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Please enter a quantityOnHand?';
                      }
                      return null;
                    },
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
                              ? 'Room Type'
                              : 'Product',
                          hintText: "country in menu mode",
                        ),
                      ),
                      itemAsString: (Product? u) => "${u!.productName}",
                      onChanged: (Product? newValue) {
                        _selectedProduct = newValue;
                      },
                      asyncItems: (String filter) {
                        _productBloc.add(ProductFetch(searchString: filter));
                        return Future.value(state.products);
                      },
                      validator: (value) =>
                          value == null ? 'field required' : null,
                    );
                  default:
                    return const Center(child: CircularProgressIndicator());
                }
              }),
              DropdownButtonFormField<String>(
                key: const Key('statusDropDown'),
                decoration: const InputDecoration(labelText: 'Status'),
                value: _statusId,
                validator: (value) => value == null ? 'field required' : null,
                items: assetStatusValues
                    .map((label) => DropdownMenuItem<String>(
                          value: label,
                          child: Text(label),
                        ))
                    .toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _statusId = newValue;
                  });
                },
                isExpanded: true,
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
