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
import 'package:responsive_framework/responsive_wrapper.dart';
import 'package:growerp_core/growerp_core.dart';
import '../../../growerp_catalog.dart';

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
  final TextEditingController _productSearchBoxController =
      TextEditingController();
  late String classificationId;
  late AssetBloc _assetBloc;
  late CatalogAPIRepository repos;
  Product? _selectedProduct;
  String? _statusId = 'Available';

  @override
  void initState() {
    super.initState();
    repos = context.read<CatalogAPIRepository>();
    _assetBloc = context.read<AssetBloc>();
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
    bool isPhone = ResponsiveWrapper.of(context).isSmallerThan(TABLET);
    return GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Scaffold(
            backgroundColor: Colors.transparent,
            body: GestureDetector(
                onTap: () {},
                child: Dialog(
                    key: const Key('AssetDialog'),
                    insetPadding: const EdgeInsets.all(10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: BlocListener<AssetBloc, AssetState>(
                        listener: (context, state) async {
                          switch (state.status) {
                            case AssetStatus.success:
                              HelperFunctions.showMessage(
                                  context,
                                  '${widget.asset.assetId.isEmpty ? "Add" : "Update"} successfull',
                                  Colors.green);
                              await Future.delayed(
                                  const Duration(milliseconds: 500));
                              // ignore: use_build_context_synchronously
                              Navigator.of(context).pop();
                              break;
                            case AssetStatus.failure:
                              HelperFunctions.showMessage(context,
                                  'Error: ${state.message}', Colors.red);
                              break;
                            default:
                              const Text("????");
                          }
                        },
                        child: Stack(clipBehavior: Clip.none, children: [
                          Container(
                              padding: const EdgeInsets.all(20),
                              width: 400,
                              height: 500,
                              child: Center(
                                child: _showForm(repos, isPhone),
                              )),
                          Container(
                              height: 50,
                              width: 400,
                              decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColorDark,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(20),
                                    topRight: Radius.circular(20),
                                  )),
                              child: const Center(
                                  child: Text('Asset Information',
                                      style: TextStyle(
                                          fontSize: 20,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold)))),
                          Positioned(
                              top: 10, right: 10, child: DialogCloseButton())
                        ]))))));
  }

  Widget _showForm(CatalogAPIRepository repos, bool isPhone) {
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
                      style: const TextStyle(
                          fontSize: 10,
                          color: Colors.black,
                          fontWeight: FontWeight.bold),
                      key: const Key('header'))),
              const SizedBox(height: 30),
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
              const SizedBox(height: 20),
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
              const SizedBox(height: 20),
              DropdownSearch<Product>(
                key: const Key('productDropDown'),
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
                  menuProps:
                      MenuProps(borderRadius: BorderRadius.circular(20.0)),
                  title: Container(
                      height: 50,
                      decoration: BoxDecoration(
                          color: Theme.of(context).primaryColorDark,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          )),
                      child: const Center(
                          child: Text('Select product',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              )))),
                ),
                dropdownSearchDecoration: InputDecoration(
                  labelText:
                      classificationId == 'AppHotel' ? 'Room Type' : 'Product',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25.0)),
                ),
                showClearButton: false,
                itemAsString: (Product? u) => "${u!.productName}",
                asyncItems: (String? filter) async {
                  ApiResult<List<Product>> result = await repos.getProduct(
                      filter: _productSearchBoxController.text,
                      assetClassId:
                          classificationId == 'AppHotel' ? 'Hotel Room' : null);
                  return result.when(
                      success: (data) => data,
                      failure: (_) =>
                          [Product(productName: 'get data error!')]);
                },
                validator: (value) => value == null ? 'field required' : null,
                onChanged: (Product? newValue) {
                  _selectedProduct = newValue;
                },
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                key: const Key('statusDropDown'),
                decoration: const InputDecoration(labelText: 'Status'),
                hint: const Text('Status'),
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
