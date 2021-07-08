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
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:models/@models.dart';
import 'package:core/blocs/@blocs.dart';
import 'package:core/helper_functions.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:responsive_framework/responsive_wrapper.dart';

class AssetDialog extends StatelessWidget {
  final FormArguments formArguments;
  const AssetDialog({Key? key, required this.formArguments}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AssetPage(formArguments.message, formArguments.object as Asset?);
  }
}

class AssetPage extends StatefulWidget {
  final String? message;
  final Asset? asset;
  AssetPage(this.message, this.asset);
  @override
  _AssetState createState() => _AssetState(message, asset);
}

class _AssetState extends State<AssetPage> {
  final String? message;
  final Asset? asset;
  final _formKey = GlobalKey<FormState>();
  TextEditingController _nameController = TextEditingController();
  TextEditingController _quantityOnHandController = TextEditingController();
  TextEditingController _productSearchBoxController = TextEditingController();
  String classificationId = GlobalConfiguration().get("classificationId");

  bool loading = false;
  Product? _selectedProduct;
  String? _statusId = 'Available';

  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  _AssetState(this.message, this.asset) {
    HelperFunctions.showTopMessage(scaffoldMessengerKey, message);
  }

  @override
  void initState() {
    super.initState();
    if (asset != null) {
      _statusId = asset!.statusId!;
      _nameController.text = asset!.assetName ?? '';
      _quantityOnHandController.text = asset!.quantityOnHand.toString();
      _selectedProduct =
          Product(productId: asset!.productId, productName: asset!.productName);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isPhone = ResponsiveWrapper.of(context).isSmallerThan(TABLET);
    var repos = context.read<Object>();
    return BlocConsumer<AssetBloc, AssetState>(listener: (context, state) {
      if (state is AssetLoading)
        HelperFunctions.showMessage(context, '${state.message}', Colors.green);
      if (state is AssetProblem) {
        loading = false;
        HelperFunctions.showMessage(
            context, '${state.errorMessage}', Colors.red);
      }
      if (state is AssetSuccess) {
        HelperFunctions.showMessage(context, '${state.message}', Colors.green);
        Navigator.of(context).pop();
      }
    }, builder: (BuildContext context, state) {
      if (state is AssetLoading) return Container();
      return GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: ScaffoldMessenger(
              key: scaffoldMessengerKey,
              child: Scaffold(
                  backgroundColor: Colors.transparent,
                  body: Builder(
                      builder: (context) => GestureDetector(
                          onTap: () {},
                          child: Dialog(
                              key: Key('AssetDialog'),
                              insetPadding: EdgeInsets.all(10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Container(
                                  padding: EdgeInsets.all(20),
                                  width: 400,
                                  height: 500,
                                  child: Center(
                                    child: _showForm(repos, isPhone),
                                  ))))))));
    });
  }

  Widget _showForm(repos, isPhone) {
    return Center(
        child: Container(
            child: Form(
                key: _formKey,
                child: ListView(key: Key('listView'), children: <Widget>[
                  Center(
                      child: Text(
                          (classificationId == 'AppHotel'
                                  ? "Room# "
                                  : "Asset# ") +
                              (asset == null ? "New" : "${asset!.assetId!}"),
                          style: TextStyle(
                              fontSize: isPhone ? 10 : 20,
                              color: Colors.black,
                              fontWeight: FontWeight.bold))),
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
                    showClearButton: false,
                    key: Key('productDropDown'),
                    itemAsString: (Product? u) => "${u?.productName}",
                    onFind: (String filter) async {
                      var result = await repos.getProduct(
                          filter: _productSearchBoxController.text,
                          assetClassId: classificationId == 'AppHotel'
                              ? 'Hotel Room'
                              : null);
                      return result;
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
                  Row(children: [
                    ElevatedButton(
                        key: Key('cancel'),
                        child: Text('Cancel'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        }),
                    SizedBox(width: 20),
                    Expanded(
                      child: ElevatedButton(
                          key: Key('update'),
                          child: Text(
                              asset?.assetId == null ? 'Create' : 'Update'),
                          onPressed: () async {
                            if (_formKey.currentState!.validate() && !loading) {
                              BlocProvider.of<AssetBloc>(context)
                                  .add(UpdateAsset(
                                Asset(
                                  assetId: asset?.assetId,
                                  assetName: _nameController.text,
                                  quantityOnHand:
                                      _quantityOnHandController.text != ""
                                          ? Decimal.parse(
                                              _quantityOnHandController.text)
                                          : null,
                                  productId: _selectedProduct!.productId,
                                  statusId: _statusId,
                                  assetClassId: 'Hotel Room',
                                ),
                              ));
                            }
                          }),
                    )
                  ])
                ]))));
  }
}
