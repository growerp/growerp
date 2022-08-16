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

import 'package:core/domains/common/functions/helper_functions.dart';
import 'package:core/services/api_result.dart';
import 'package:decimal/decimal.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:responsive_framework/responsive_wrapper.dart';
import 'package:core/domains/domains.dart';

import '../../../api_repository.dart';

class AssetDialog extends StatefulWidget {
  final Asset asset;
  AssetDialog(this.asset);
  @override
  _AssetState createState() => _AssetState(asset);
}

class _AssetState extends State<AssetDialog> {
  final Asset asset;
  final _formKey = GlobalKey<FormState>();
  TextEditingController _nameController = TextEditingController();
  TextEditingController _quantityOnHandController = TextEditingController();
  TextEditingController _productSearchBoxController = TextEditingController();
  late String classificationId;

  Product? _selectedProduct;
  String? _statusId = 'Available';

  _AssetState(this.asset);

  @override
  void initState() {
    super.initState();
    _statusId = asset.statusId ?? null;
    _nameController.text = asset.assetName ?? '';
    _quantityOnHandController.text =
        asset.quantityOnHand == null ? '' : asset.quantityOnHand.toString();
    _selectedProduct = asset.product ?? null;
    classificationId = GlobalConfiguration().get("classificationId");
  }

  @override
  Widget build(BuildContext context) {
    bool isPhone = ResponsiveWrapper.of(context).isSmallerThan(TABLET);
    var repos = context.read<APIRepository>();
    return GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Scaffold(
            backgroundColor: Colors.transparent,
            body: GestureDetector(
                onTap: () {},
                child: Dialog(
                    key: Key('AssetDialog'),
                    insetPadding: EdgeInsets.all(10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: BlocListener<AssetBloc, AssetState>(
                        listener: (context, state) async {
                          switch (state.status) {
                            case AssetStatus.success:
                              HelperFunctions.showMessage(
                                  context,
                                  '${asset.assetId.isEmpty ? "Add" : "Update"} successfull',
                                  Colors.green);
                              await Future.delayed(Duration(milliseconds: 500));
                              Navigator.of(context).pop();
                              break;
                            case AssetStatus.failure:
                              HelperFunctions.showMessage(context,
                                  'Error: ${state.message}', Colors.red);
                              break;
                            default:
                              Text("????");
                          }
                        },
                        child: Stack(clipBehavior: Clip.none, children: [
                          Container(
                              padding: EdgeInsets.all(20),
                              width: 400,
                              height: 450,
                              child: Center(
                                child: _showForm(repos, isPhone),
                              )),
                          Container(
                              height: 50,
                              width: 400,
                              decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColorDark,
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(20),
                                    topRight: Radius.circular(20),
                                  )),
                              child: Center(
                                  child: Text('Asset Information',
                                      style: TextStyle(
                                          fontSize: 20,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold)))),
                          Positioned(
                              top: 10, right: 10, child: DialogCloseButton())
                        ]))))));
  }

  Widget _showForm(APIRepository repos, bool isPhone) {
    return Center(
        child: Container(
            child: Form(
                key: _formKey,
                child: ListView(key: Key('listView'), children: <Widget>[
                  Center(
                      child: Text(
                          (classificationId == 'AppHotel'
                                  ? "Room #"
                                  : "Asset #") +
                              (asset.assetId.isEmpty
                                  ? "New"
                                  : "${asset.assetId}"),
                          style: TextStyle(
                              fontSize: 10,
                              color: Colors.black,
                              fontWeight: FontWeight.bold),
                          key: Key('header'))),
                  SizedBox(height: 30),
                  TextFormField(
                    key: Key('name'),
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
                  SizedBox(height: 20),
                  Visibility(
                      visible: classificationId != 'AppHotel',
                      child: SizedBox(height: 20)),
                  Visibility(
                      visible: classificationId != 'AppHotel',
                      child: TextFormField(
                        key: Key('quantityOnHand'),
                        decoration:
                            InputDecoration(labelText: 'Quantity on Hand'),
                        keyboardType: TextInputType.number,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.allow(RegExp('[0-9.,]+'))
                        ],
                        controller: _quantityOnHandController,
                        validator: (value) {
                          if (value!.isEmpty)
                            return 'Please enter a quantityOnHand?';
                          return null;
                        },
                      )),
                  SizedBox(height: 20),
                  DropdownSearch<Product>(
                    key: Key('productDropDown'),
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
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(20),
                                topRight: Radius.circular(20),
                              )),
                          child: Center(
                              child: Text('Select product',
                                  style: TextStyle(
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
                    showClearButton: false,
                    itemAsString: (Product? u) => "${u!.productName}",
                    asyncItems: (String? filter) async {
                      ApiResult<List<Product>> result = await repos.getProduct(
                          filter: _productSearchBoxController.text,
                          assetClassId: classificationId == 'AppHotel'
                              ? 'Hotel Room'
                              : null);
                      return result.when(
                          success: (data) => data,
                          failure: (_) =>
                              [Product(productName: 'get data error!')]);
                    },
                    validator: (value) =>
                        value == null ? 'field required' : null,
                    onChanged: (Product? newValue) {
                      _selectedProduct = newValue;
                    },
                  ),
                  SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    key: Key('statusDropDown'),
                    decoration: InputDecoration(labelText: 'Status'),
                    hint: Text('Status'),
                    value: _statusId,
                    validator: (value) =>
                        value == null ? 'field required' : null,
                    items: assetStatusValues
                        .map((label) => DropdownMenuItem<String>(
                              child: Text(label),
                              value: label,
                            ))
                        .toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _statusId = newValue;
                      });
                    },
                    isExpanded: true,
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                      key: Key('update'),
                      child: Text(asset.assetId.isEmpty ? 'Create' : 'Update'),
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          context.read<AssetBloc>().add(AssetUpdate(
                                Asset(
                                  assetId: asset.assetId,
                                  assetName: _nameController.text,
                                  quantityOnHand:
                                      _quantityOnHandController.text != ""
                                          ? Decimal.parse(
                                              _quantityOnHandController.text)
                                          : Decimal.parse('1'),
                                  product: _selectedProduct,
                                  statusId: _statusId,
                                ),
                              ));
                        }
                      }),
                ]))));
  }
}
