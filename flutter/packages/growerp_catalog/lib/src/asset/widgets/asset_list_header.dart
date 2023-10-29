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
import 'package:global_configuration/global_configuration.dart';
import 'package:growerp_core/growerp_core.dart';

class AssetListHeader extends StatefulWidget {
  const AssetListHeader({Key? key}) : super(key: key);

  @override
  State<AssetListHeader> createState() => _AssetListHeaderState();
}

class _AssetListHeaderState extends State<AssetListHeader> {
  String classificationId = GlobalConfiguration().getValue("classificationId");
  String searchString = '';
  bool search = false;
  @override
  Widget build(BuildContext context) {
    final assetBloc = context.read<AssetBloc>();
    return ListTile(
        leading: GestureDetector(
            key: const Key('search'),
            onTap: (() =>
                setState(() => search ? search = false : search = true)),
            child: const Icon(Icons.search_sharp, size: 40)),
        title: search
            ? Row(children: <Widget>[
                Expanded(
                    child: TextField(
                  key: const Key('searchField'),
                  textInputAction: TextInputAction.go,
                  autofocus: true,
                  decoration: const InputDecoration(
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.transparent),
                    ),
                    hintText: "search in ID, name and description...",
                  ),
                  onChanged: ((value) => setState(() {
                        searchString = value;
                      })),
                )),
                ElevatedButton(
                    key: const Key('searchButton'),
                    child: const Text('Search'),
                    onPressed: () {
                      assetBloc.add(AssetFetch(searchString: searchString));
                    })
              ])
            : Column(children: [
                Row(children: <Widget>[
                  const Expanded(
                      child: Text("Name", textAlign: TextAlign.center)),
                  Expanded(
                      child: Text(
                          classificationId == 'AppHotel' ? 'Type' : 'Product',
                          textAlign: TextAlign.center)),
                  const Expanded(
                      child: Text("Act.", textAlign: TextAlign.center)),
                ]),
                const Divider(),
              ]),
        trailing: const Text(' '));
  }
}
