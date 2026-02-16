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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

import '../asset.dart';
import 'package:growerp_inventory/l10n/generated/inventory_localizations.dart';

class AssetDialog extends StatefulWidget {
  final Asset asset;
  const AssetDialog(this.asset, {super.key});
  @override
  AssetDialogState createState() => AssetDialogState();
}

class AssetDialogState extends State<AssetDialog> {
  final _assetDialogformKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _pseudoIdController = TextEditingController();
  final TextEditingController _quantityOnHandController =
      TextEditingController();
  final TextEditingController _atpController = TextEditingController();
  final TextEditingController _acquireCostController = TextEditingController();

  late String classificationId;
  late AssetBloc _assetBloc;
  late DataFetchBloc<Products> _productBloc;
  late DataFetchBloc<Locations> _locationBloc;
  Location? _selectedLocation;
  Product? _selectedProduct;
  late String _statusId;
  late String currencyId;
  late String currencySymbol;
  late InventoryLocalizations _localizations;

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
      locale: Platform.localeName,
      name: currencyId,
    ).currencySymbol;
    _assetBloc = context.read<AssetBloc>();
    _productBloc = context.read<DataFetchBloc<Products>>()
      ..add(
        GetDataEvent(
          () => context.read<RestClient>().getProduct(
            limit: 3,
            isForDropDown: true,
          ),
        ),
      );
    _statusId = widget.asset.statusId ?? 'Available';
    _nameController.text = widget.asset.assetName ?? '';
    _pseudoIdController.text = widget.asset.pseudoId;
    _quantityOnHandController.text = widget.asset.quantityOnHand == null
        ? ''
        : widget.asset.quantityOnHand.toString();
    _atpController.text = widget.asset.availableToPromise == null
        ? ''
        : widget.asset.availableToPromise.toString();
    _acquireCostController.text = widget.asset.acquireCost == null
        ? ''
        : widget.asset.acquireCost.currency(currencyId: ''); // no symbol
    _selectedProduct = widget.asset.product;
    _selectedLocation = widget.asset.location;
    classificationId = context.read<String>();
    _locationBloc = context.read<DataFetchBloc<Locations>>()
      ..add(
        GetDataEvent(() => context.read<RestClient>().getLocation(limit: 3)),
      );
  }

  @override
  Widget build(BuildContext context) {
    _localizations = InventoryLocalizations.of(context)!;
    bool isPhone = ResponsiveBreakpoints.of(context).isMobile;
    return BlocConsumer<AssetBloc, AssetState>(
      listener: (context, state) {
        switch (state.status) {
          case AssetStatus.success:
            Navigator.of(context).pop();
            break;
          case AssetStatus.failure:
            HelperFunctions.showMessage(
              context,
              _localizations.error(state.message ?? ''),
              Colors.red,
            );
            break;
          default:
            const Text("????");
        }
      },
      builder: (context, state) {
        switch (state.status) {
          case AssetStatus.success:
            return Dialog(
              key: const Key('AssetDialog'),
              insetPadding: const EdgeInsets.all(10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: popUp(
                context: context,
                title:
                    '${classificationId == 'AppHotel' ? _localizations.roomNumber : _localizations.assetNumber} #${widget.asset.pseudoId.isEmpty ? _localizations.newLabel : widget.asset.pseudoId}',
                height: 480,
                width: 350,
                child: _showForm(isPhone),
              ),
            );
          case AssetStatus.failure:
            return FatalErrorForm(message: _localizations.assetLoadProblem);
          default:
            return const Center(child: LoadingIndicator());
        }
      },
    );
  }

  Widget _showForm(bool isPhone) {
    return SingleChildScrollView(
      key: const Key('listView'),
      child: Form(
        key: _assetDialogformKey,
        child: Column(
          children: <Widget>[
            const SizedBox(height: 10),
            TextFormField(
              key: const Key('pseudoId'),
              decoration: InputDecoration(labelText: _localizations.idLabel),
              controller: _pseudoIdController,
            ),
            const SizedBox(height: 10),
            TextFormField(
              key: const Key('name'),
              decoration: InputDecoration(
                labelText: classificationId == 'AppHotel'
                    ? _localizations.roomNameLabel
                    : _localizations.assetNameLabel,
              ),
              controller: _nameController,
              validator: (value) {
                if (value!.isEmpty) return _localizations.enterAssetName;
                return null;
              },
            ),
            const SizedBox(height: 10),
            if (classificationId != 'AppHotel')
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: TextFormField(
                      key: const Key('quantityOnHand'),
                      decoration: InputDecoration(
                        labelText: _localizations.qtyOnHand,
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.allow(RegExp('[0-9.,]+')),
                      ],
                      controller: _quantityOnHandController,
                      validator: (value) {
                        if (value!.isEmpty) {
                          return _localizations.enterQtyOnHand;
                        }
                        return null;
                      },
                    ),
                  ),
                  Expanded(
                    child: TextFormField(
                      key: const Key('availableToPromise'),
                      decoration: InputDecoration(
                        labelText: _localizations.qtyPromise,
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.allow(RegExp('[0-9.,]+')),
                      ],
                      controller: _atpController,
                      validator: (value) {
                        if (value!.isEmpty) {
                          return _localizations.enterQtyPromise;
                        }
                        return null;
                      },
                    ),
                  ),
                  Expanded(
                    child: TextFormField(
                      key: const Key('acquireCost'),
                      decoration: InputDecoration(
                        labelText: _localizations.aqrdCosts(currencySymbol),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.allow(RegExp('[0-9.,]+')),
                      ],
                      controller: _acquireCostController,
                      validator: (value) {
                        if (value!.isEmpty) {
                          return _localizations.enterAquiredCost;
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 10),
            BlocBuilder<DataFetchBloc<Products>, DataFetchState<Products>>(
              buildWhen: (previous, current) =>
                  current.status != DataFetchStatus.loading,
              builder: (context, state) {
                switch (state.status) {
                  case DataFetchStatus.failure:
                    return FatalErrorForm(
                      message: _localizations.serverProblem,
                    );
                  case DataFetchStatus.success:
                    return AutocompleteLabel<Product>(
                      key: const Key('productDropDown'),
                      initialValue: _selectedProduct,
                      label: classificationId == 'AppHotel'
                          ? _localizations.roomTypeId
                          : _localizations.productId,
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        _productBloc.add(
                          GetDataEvent(
                            () => context.read<RestClient>().getProduct(
                              searchString: textEditingValue.text,
                              limit: 3,
                              isForDropDown: true,
                            ),
                          ),
                        );
                        return Future.delayed(
                          const Duration(milliseconds: 150),
                          () {
                            return (_productBloc.state.data as Products)
                                .products;
                          },
                        );
                      },
                      displayStringForOption: (Product u) =>
                          " ${u.productName} [${u.pseudoId}]",
                      onSelected: (Product? newValue) {
                        setState(() {
                          _selectedProduct = newValue;
                        });
                      },
                      validator: (value) =>
                          value == null ? _localizations.fieldRequired : null,
                    );
                  default:
                    return const Center(child: LoadingIndicator());
                }
              },
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    key: const Key('statusDropDown'),
                    decoration: InputDecoration(
                      labelText: _localizations.status,
                    ),
                    initialValue: _statusId,
                    validator: (value) =>
                        value == null ? _localizations.fieldRequired : null,
                    items: assetStatusValues
                        .map(
                          (label) => DropdownMenuItem<String>(
                            value: label,
                            child: Text(label),
                          ),
                        )
                        .toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _statusId = newValue!;
                      });
                    },
                    isExpanded: true,
                  ),
                ),
                if (classificationId != 'AppHotel')
                  Expanded(
                    child:
                        BlocBuilder<
                          DataFetchBloc<Locations>,
                          DataFetchState<Locations>
                        >(
                          buildWhen: (previous, current) =>
                              current.status != DataFetchStatus.loading,
                          builder: (context, state) {
                            switch (state.status) {
                              case DataFetchStatus.failure:
                                return FatalErrorForm(
                                  message: _localizations.serverProblem,
                                );
                              case DataFetchStatus.success:
                                return AutocompleteLabel<Location>(
                                  key: const Key('locationDropDown'),
                                  initialValue: _selectedLocation,
                                  label: _localizations.location,
                                  optionsBuilder:
                                      (TextEditingValue textEditingValue) {
                                        _locationBloc.add(
                                          GetDataEvent(
                                            () => context
                                                .read<RestClient>()
                                                .getLocation(
                                                  searchString:
                                                      textEditingValue.text,
                                                  limit: 3,
                                                ),
                                          ),
                                        );
                                        return Future.delayed(
                                          const Duration(milliseconds: 250),
                                          () {
                                            return (_locationBloc.state.data
                                                    as Locations)
                                                .locations;
                                          },
                                        );
                                      },
                                  displayStringForOption: (Location u) =>
                                      " ${u.locationName}",
                                  onSelected: (Location? newValue) {
                                    setState(() {
                                      _selectedLocation = newValue;
                                    });
                                  },
                                );
                              default:
                                return const Center(child: LoadingIndicator());
                            }
                          },
                        ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              key: const Key('update'),
              child: Text(
                widget.asset.assetId.isEmpty
                    ? _localizations.create
                    : _localizations.update,
              ),
              onPressed: () async {
                if (_assetDialogformKey.currentState!.validate()) {
                  _assetBloc.add(
                    AssetUpdate(
                      Asset(
                        assetId: widget.asset.assetId,
                        pseudoId: _pseudoIdController.text,
                        assetClassId: classificationId == 'AppHotel'
                            ? 'Hotel Room'
                            : null,
                        assetName: _nameController.text,
                        quantityOnHand: _quantityOnHandController.text != ""
                            ? Decimal.parse(_quantityOnHandController.text)
                            : Decimal.parse('0'),
                        availableToPromise: _atpController.text != ""
                            ? Decimal.parse(_atpController.text)
                            : Decimal.parse('0'),
                        acquireCost: _acquireCostController.text != ""
                            ? Decimal.parse(_acquireCostController.text)
                            : Decimal.parse('0'),
                        product: _selectedProduct,
                        location: _selectedLocation,
                        statusId: _statusId,
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
