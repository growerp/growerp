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
import 'package:growerp_models/growerp_models.dart';

import '../location.dart';

class LocationListItem extends StatelessWidget {
  const LocationListItem(
      {super.key,
      required this.location,
      required this.index,
      required this.isPhone});

  final Location location;
  final int index;
  final bool isPhone;

  @override
  Widget build(BuildContext context) {
    final locationBloc = context.read<LocationBloc>();
    //d(String s) => Decimal.parse(s);
    Decimal qohTotal = Decimal.zero;
    for (Asset asset in location.assets) {
      qohTotal += asset.quantityOnHand ?? Decimal.zero;
    }
    return ExpansionTile(
        key: Key("$index"),
        leading: CircleAvatar(
          backgroundColor: Colors.green,
          child: Text(
              location.locationName != null ? location.locationName![0] : "?"),
        ),
        title: Row(children: <Widget>[
          Expanded(
              child: Text("${location.locationName}[${location.locationId}]",
                  key: Key('locName$index'))),
          SizedBox(
              width: 70,
              child: Text(
                qohTotal.toString(),
                key: Key('qoh$index'),
                textAlign: TextAlign.center,
              )),
        ]),
        trailing: SizedBox(
            width: isPhone ? 100 : 195,
            child: Row(children: [
              IconButton(
                  key: Key('delete$index'),
                  icon: const Icon(Icons.delete_forever),
                  onPressed: () {
                    locationBloc.add(LocationDelete(location));
                  }),
              IconButton(
                  key: Key('edit$index'),
                  icon: const Icon(Icons.edit),
                  onPressed: () async {
                    await showDialog(
                        barrierDismissible: true,
                        context: context,
                        builder: (BuildContext context) {
                          return BlocProvider.value(
                              value: locationBloc,
                              child: LocationDialog(location));
                        });
                  }),
            ])),
        children: location.assets.isEmpty
            ? [Text("No assets found")]
            : items(location, index));
  }

  List<Widget> items(Location location, int index) {
    int assetCount = 1;
    return List.from(location.assets.map(
        (e) => Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              const SizedBox(width: 50),
              Expanded(
                key: const Key('locationItem'),
                child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green,
                      maxRadius: 10,
                      child: Text((assetCount++).toString()),
                    ),
                    title: Row(children: [
                      Expanded(child: Text("${e.assetName}")),
                      Text("${e.statusId}")
                    ]),
                    subtitle: Text("QOH: ${e.quantityOnHand?.toString()} "
                        "ATP: ${e.availableToPromise?.toString()} "
                        "Receive Date:${e.receivedDate ?? ''}")),
              )
            ])));
  }
}
