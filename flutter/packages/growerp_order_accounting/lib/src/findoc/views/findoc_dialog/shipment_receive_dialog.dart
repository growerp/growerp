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

import 'package:collection/collection.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_order_accounting/l10n/generated/order_accounting_localizations.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../findoc.dart';

class ShipmentReceiveDialog extends StatefulWidget {
  final FinDoc finDoc;
  const ShipmentReceiveDialog(this.finDoc, {super.key});
  @override
  ShipmentReceiveState createState() => ShipmentReceiveState();
}

class ShipmentReceiveState extends State<ShipmentReceiveDialog> {
  late RestClient restClient;
  late DataFetchBloc<Locations> _locationBloc;
  late bool isPhone;
  final List<TextEditingController> _locationSearchBoxControllers = [];
  final List<TextEditingController> _newLocationControllers = [];
  final List<Location> _selectedLocations = [];
  List<FinDocItem> newItems = [];
  late bool confirm;
  late OrderAccountingLocalizations _localizations;

  @override
  void initState() {
    super.initState();
    for (var _ in widget.finDoc.items) {
      _locationSearchBoxControllers.add(TextEditingController());
      _newLocationControllers.add(TextEditingController());
      _selectedLocations.add(Location(locationName: 'Select'));
    }
    newItems = List.of(widget.finDoc.items);
    confirm = false;
    _locationBloc = context.read<DataFetchBloc<Locations>>()
      ..add(
          GetDataEvent(() => context.read<RestClient>().getLocation(limit: 3)));
  }

  @override
  Widget build(BuildContext context) {
    isPhone = ResponsiveBreakpoints.of(context).isMobile;
    _localizations = OrderAccountingLocalizations.of(context)!;
    return Dialog(
        key: Key(
            "ShipmentReceiveDialog${widget.finDoc.sales ? 'Sales' : 'Purchase'}"),
        insetPadding: const EdgeInsets.all(10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: popUp(
            context: context,
            title: '${_localizations.incomingShipment} ${widget.finDoc.pseudoId}',
            width: isPhone ? 400 : 800,
            height: isPhone
                ? 600
                : 600, // not increase height otherwise tests will fail
            child: shipmentItemList()));
  }

  Widget shipmentItemList() {
    FinDocBloc finDocBloc = context.read<FinDocBloc>();
    String nowDate = DateTime.now().toString().substring(0, 10);
    return Column(children: [
      RelatedFinDocs(finDoc: widget.finDoc, context: context),
      Expanded(
          child: ListView.builder(
              key: const Key('listView'),
              itemCount: newItems.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Column(children: [
                    ListTile(
                      leading: !isPhone
                          ? const CircleAvatar(
                              backgroundColor: Colors.transparent,
                            )
                          : null,
                      title: Column(children: [
                        Center(
                            child: Text(
                          _localizations.itemLocationInstructions,
                        )),
                        const SizedBox(height: 30),
                        Row(children: <Widget>[
                          Text('${_localizations.productId}  '),
                          Expanded(child: Text(_localizations.description)),
                          Text(_localizations.quantity),
                        ]),
                      ]),
                      subtitle: Row(children: <Widget>[
                        Expanded(
                            child: Text(_localizations.location,
                                textAlign: TextAlign.center)),
                        Expanded(
                            child: Text(_localizations.newLocation,
                                textAlign: TextAlign.center)),
                      ]),
                    ),
                    const Divider(),
                  ]);
                }
                if (index == 1 && newItems.isEmpty) {
                  return Center(
                      heightFactor: 20,
                      child: Text(_localizations.noItems,
                          key: const Key('empty'), textAlign: TextAlign.center));
                }
                index--;
                return ListTile(
                  leading: !isPhone
                      ? const CircleAvatar(
                          backgroundColor: Colors.transparent,
                        )
                      : null,
                  title: Column(children: [
                    Row(children: <Widget>[
                      Text(newItems[index].product?.productId ?? ''),
                      const SizedBox(width: 10),
                      Expanded(child: Text('${newItems[index].description}')),
                      Text('${newItems[index].quantity}'),
                    ]),
                    const SizedBox(height: 10),
                    confirm
                        ? Text(
                            '${_localizations.toLocation} ${newItems[index].asset?.location?.locationName}')
                        : Row(children: <Widget>[
                            Expanded(
                                child: SizedBox(
                                    height: 60,
                                    child: DropdownSearch<Location>(
                                        key: Key('locationDropDown$index'),
                                        selectedItem: _selectedLocations[index],
                                        popupProps: PopupProps.menu(
                                          isFilterOnline: true,
                                          showSearchBox: true,
                                          searchFieldProps: TextFieldProps(
                                            autofocus: true,
                                            decoration: InputDecoration(
                                                labelText: _localizations.locationName),
                                            controller:
                                                _locationSearchBoxControllers[
                                                    index],
                                          ),
                                          menuProps: MenuProps(
                                              borderRadius:
                                                  BorderRadius.circular(20.0)),
                                          title: popUp(
                                            context: context,
                                            title: _localizations.selectLocation,
                                            height: 50,
                                          ),
                                        ),
                                        dropdownDecoratorProps:
                                            DropDownDecoratorProps(
                                                dropdownSearchDecoration:
                                                    InputDecoration(
                                                        labelText:
                                                            _localizations.location)),
                                        itemAsString: (Location? u) =>
                                            " ${u?.locationName}",
                                        asyncItems: (String filter) {
                                          _locationBloc.add(GetDataEvent(() =>
                                              context
                                                  .read<RestClient>()
                                                  .getLocation(
                                                      searchString: filter,
                                                      limit: 3)));
                                          return Future.delayed(
                                              const Duration(milliseconds: 250),
                                              () {
                                            return Future.value((_locationBloc
                                                    .state.data as Locations)
                                                .locations);
                                          });
                                        },
                                        compareFn: (item, sItem) =>
                                            item.locationId == sItem.locationId,
                                        onChanged: (Location? newValue) {
                                          _selectedLocations[index] = newValue!;
                                          _newLocationControllers[index].text =
                                              '';
                                        }))),
                            const SizedBox(width: 10),
                            Expanded(
                                child: TextFormField(
                              key: Key('newLocation$index'),
                              decoration: InputDecoration(
                                  labelText: _localizations.newLocation),
                              controller: _newLocationControllers[index],
                              onChanged: (_) {
                                setState(() {
                                  _selectedLocations[index] =
                                      Location(locationName: '');
                                });
                              },
                            ))
                          ])
                  ]),
                );
              })),
      SizedBox(
          height: 50,
          child: Row(children: [
            Visibility(
                visible: confirm,
                child: OutlinedButton(
                    key: const Key('back'),
                    child: Text(_localizations.goBack),
                    onPressed: () async {
                      setState(() {
                        confirm = false;
                      });
                      newItems.forEachIndexed((index, value) {
                        final asset = value.asset!.copyWith(
                            location: _selectedLocations[index].locationId !=
                                    null
                                ? _selectedLocations[index]
                                : Location(
                                    locationName:
                                        _newLocationControllers[index].text));

                        newItems[index] = value.copyWith(asset: asset);
                      });
                      finDocBloc.add(FinDocShipmentReceive(
                          widget.finDoc.copyWith(items: newItems)));
                    })),
            const SizedBox(
              width: 10,
            ),
            Expanded(
                child: OutlinedButton(
                    key: const Key('update'),
                    child:
                        Text(confirm ? _localizations.confirm : _localizations.receiveShipment),
                    onPressed: () async {
                      setState(() {
                        if (confirm == false) {
                          newItems.forEachIndexed((index, value) {
                            final asset = Asset(
                                location: _selectedLocations[index]
                                            .locationId !=
                                        null
                                    ? _selectedLocations[index]
                                    : _newLocationControllers[index]
                                            .text
                                            .isNotEmpty
                                        ? Location(
                                            locationName:
                                                _newLocationControllers[index]
                                                    .text)
                                        : Location(
                                            locationName:
                                                '${newItems[index].description}'
                                                '($nowDate)'));

                            newItems[index] = value.copyWith(asset: asset);
                            confirm = true;
                          });
                        } else {
                          finDocBloc.add(FinDocShipmentReceive(
                              widget.finDoc.copyWith(items: newItems)));
                          Navigator.of(context).pop();
                        }
                      });
                    }))
          ])),
      const SizedBox(height: 20)
    ]);
  }
}
