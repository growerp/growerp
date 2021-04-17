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
import 'package:image_picker/image_picker.dart';
import 'package:models/@models.dart';
import 'package:core/blocs/@blocs.dart';
import 'package:core/helper_functions.dart';
import 'package:core/templates/@templates.dart';

class AssetDialog extends StatelessWidget {
  final FormArguments formArguments;
  const AssetDialog({Key? key, required this.formArguments}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AssetPage(formArguments.message, formArguments.object as Asset);
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
  TextEditingController _descriptionController = TextEditingController();
  TextEditingController _quantityOnHandController = TextEditingController();
  TextEditingController _productSearchBoxController = TextEditingController();

  bool loading = false;
  late Asset updatedAsset;
  Product? _selectedCategory;
  PickedFile? _imageFile;
  dynamic _pickImageError;
  String? _retrieveDataError;

  final ImagePicker _picker = ImagePicker();
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  _AssetState(this.message, this.asset) {
    HelperFunctions.showTopMessage(scaffoldMessengerKey, message);
  }

  void _onImageButtonPressed(ImageSource source,
      {BuildContext? context}) async {
    try {
      final pickedFile = await _picker.getImage(
        source: source,
      );
      setState(() {
        _imageFile = pickedFile;
      });
    } catch (e) {
      setState(() {
        _pickImageError = e;
      });
    }
  }

  Future<void> retrieveLostData() async {
    final LostData response = await _picker.getLostData();
    if (response.isEmpty) {
      return;
    }
    if (response.file != null) {
      setState(() {
        _imageFile = response.file;
      });
    } else {
      _retrieveDataError = response.exception!.code;
    }
  }

  @override
  Widget build(BuildContext context) {
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
          child: Scaffold(
              backgroundColor: Colors.transparent,
              body: Builder(
                  builder: (context) => GestureDetector(
                      onTap: () {},
                      child: Dialog(
                          insetPadding: EdgeInsets.all(10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Container(
                              padding: EdgeInsets.all(20),
                              width: 400,
                              height: 750,
                              child: ScaffoldMessenger(
                                  key: scaffoldMessengerKey,
                                  child: Scaffold(
                                      backgroundColor: Colors.transparent,
                                      floatingActionButton: imageButtons(
                                          context, _onImageButtonPressed),
                                      body: Center(
                                        child: !kIsWeb &&
                                                defaultTargetPlatform ==
                                                    TargetPlatform.android
                                            ? FutureBuilder<void>(
                                                future: retrieveLostData(),
                                                builder: (BuildContext context,
                                                    AsyncSnapshot<void>
                                                        snapshot) {
                                                  if (snapshot.hasError) {
                                                    return Text(
                                                      'Pick image error: ${snapshot.error}}',
                                                      textAlign:
                                                          TextAlign.center,
                                                    );
                                                  }
                                                  return _showForm(repos);
                                                })
                                            : _showForm(repos),
                                      )))))))));
    });
  }

  Text? _getRetrieveErrorWidget() {
    if (_retrieveDataError != null) {
      final Text result = Text(_retrieveDataError!);
      _retrieveDataError = null;
      return result;
    }
    return null;
  }

  Widget _showForm(repos) {
    if (asset != null) {
      _nameController.text = asset!.assetName ?? '';
      _quantityOnHandController.text =
          asset!.quantityOnHand == null ? '' : asset!.quantityOnHand.toString();
      if (_selectedCategory == null && asset?.productId != null)
        _selectedCategory = Product(
            productId: asset!.productId, productName: asset!.productName);
    }
    final Text? retrieveError = _getRetrieveErrorWidget();
    if (retrieveError != null) {
      return retrieveError;
    }
    if (_pickImageError != null) {
      return Text(
        'Pick image error: $_pickImageError',
        textAlign: TextAlign.center,
      );
    }
    return Center(
        child: Container(
            width: 400,
            child: Form(
                key: _formKey,
                child: ListView(children: <Widget>[
                  SizedBox(height: 30),
                  TextFormField(
                    key: Key('name'),
                    decoration: InputDecoration(labelText: 'Asset Name'),
                    controller: _nameController,
                    validator: (value) {
                      if (value!.isEmpty) return 'Please enter a asset name?';
                      return null;
                    },
                  ),
                  SizedBox(height: 20),
                  TextFormField(
                    key: Key('description'),
                    maxLines: 5,
                    decoration: InputDecoration(labelText: 'Description'),
                    controller: _descriptionController,
                  ),
                  SizedBox(height: 20),
                  TextFormField(
                    key: Key('quantityOnHand'),
                    decoration: InputDecoration(labelText: 'Asset Price'),
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(RegExp('[0-9.,]+'))
                    ],
                    controller: _quantityOnHandController,
                    validator: (value) {
                      if (value!.isEmpty)
                        return 'Please enter a quantityOnHand?';
                      return null;
                    },
                  ),
                  SizedBox(height: 10),
                  DropdownSearch<Product>(
                    label: 'Category',
                    dialogMaxWidth: 300,
                    autoFocusSearchBox: true,
                    selectedItem: _selectedCategory,
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
                    showClearButton: true,
                    key: Key('dropDownCategory'),
                    itemAsString: (Product? u) => "${u?.productName}",
                    onFind: (String filter) async {
                      var result = await repos.getCategory(
                          filter: _productSearchBoxController.text);
                      return result;
                    },
                    onChanged: (Product? newValue) {
                      _selectedCategory = newValue;
                    },
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                      key: Key('update'),
                      child: Text(asset?.assetId == null ? 'Create' : 'Update'),
                      onPressed: () async {
                        if (_formKey.currentState!.validate() && !loading) {
                          updatedAsset = Asset(
                            assetId: asset?.assetId,
                            assetName: _nameController.text,
                            quantityOnHand:
                                Decimal.parse(_quantityOnHandController.text),
                            productId: _selectedCategory!.productId,
                          );
                          BlocProvider.of<AssetBloc>(context).add(UpdateAsset(
                            updatedAsset,
                          ));
                        }
                      }),
                  SizedBox(height: 20),
                  ElevatedButton(
                      key: Key('cancel'),
                      child: Text('Cancel'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      })
                ]))));
  }
}
