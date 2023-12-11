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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:growerp_core/growerp_core.dart';

import '../../l10n/generated/inventory_localizations.dart';

class LocationListHeader extends StatefulWidget {
  const LocationListHeader({super.key, required this.locationBloc});
  final LocationBloc locationBloc;

  @override
  State<LocationListHeader> createState() => _LocationListHeaderState();
}

class _LocationListHeaderState extends State<LocationListHeader> {
  bool search = false;
  String searchString = '';
  late final LocationBloc locationBloc;

  @override
  void initState() {
    super.initState();
    locationBloc = context.read<LocationBloc>();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
        leading: GestureDetector(
            key: const Key('search'),
            onTap: (() {
              if (search) locationBloc.add(const LocationFetch(refresh: true));
              setState(() => search = !search);
            }),
            child: const Icon(Icons.search_sharp, size: 40)),
        title: search
            ? Row(children: <Widget>[
                SizedBox(
                    width: ResponsiveBreakpoints.of(context).isMobile
                        ? MediaQuery.of(context).size.width - 300
                        : MediaQuery.of(context).size.width - 350,
                    key: const Key('searchField'),
                    child: TextField(
                      autofocus: true,
                      decoration: const InputDecoration(
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.transparent),
                        ),
                        hintText: "search in name loc/asset/product Id",
                      ),
                      onChanged: ((value) =>
                          setState(() => searchString = value)),
                    )),
                ElevatedButton(
                    key: const Key('searchButton'),
                    child: const Text('Search'),
                    onPressed: () {
                      locationBloc
                          .add(LocationFetch(searchString: searchString));
                    })
              ])
            : const Row(children: <Widget>[
                Expanded(child: Text("Loc.Name[ID]")),
                SizedBox(width: 80, child: Text("QOH")),
              ]),
        subtitle: Text(InventoryLocalizations.of(context)!.productName),
        trailing: const SizedBox(width: 50));
  }
}
